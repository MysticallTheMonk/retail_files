if not BBF.isMidnight then return end
local L = BBF.L
local UnitIsFriend = UnitIsFriend
local UnitIsEnemy = UnitIsEnemy
local UnitIsPlayer = UnitIsPlayer
local UnitClass = UnitClass
local UnitIsUnit = UnitIsUnit

local healthbarsHooked = nil
local classColorsOn
local colorPetAfterOwner
local skipPlayer
local skipFriendly
local retexturedBars
local rpNames
local rpNamesHealthbarColor
local customHealthbarColors
local overrideClassColors
local customColorsUnitFrames
local customColorsRaidFrames
local useOneClassColor
local singleClassColor
local useOnePowerColor
local singlePowerColor
local customPowerColors
local powerColorCache = {}
local useCustomPowerColors = false

local OnSetVertexColorHookScript = function(r, g, b, a)
    return function(frame, red, green, blue, alpha, flag)
        if flag ~= "BBFHookSetVertexColor" then
            frame:SetVertexColor(r, g, b, a, "BBFHookSetVertexColor")
        end
    end
end

function BBF.SetVertexColor(frame, r, g, b, a)
    frame:SetVertexColor(r, g, b, a, "BBFHookSetVertexColor")

    if (not frame.BBFHookSetVertexColor) then
        hooksecurefunc(frame, "SetVertexColor", OnSetVertexColorHookScript(r, g, b, a))
        frame.BBFHookSetVertexColor = true
    end
end

local function getUnitReaction(unit)
    if UnitIsFriend(unit, "player") then
        return "FRIENDLY"
    elseif UnitIsEnemy(unit, "player") then
        return "HOSTILE"
    else
        return "NEUTRAL"
    end
end

local function GetRPNameColor(unit)
    if not TRP3_API or not TRP3_API.globals or not TRP3_API.globals.player_realm_id then return end
    local player = AddOn_TotalRP3 and AddOn_TotalRP3.Player and AddOn_TotalRP3.Player.CreateFromUnit(unit)
    if player then
        local color = player:GetCustomColorForDisplay()
        if color then
            local r, g, b = color:GetRGB()
            return r, g, b
        end
    end
end

local npcColorCache = {}
local function GetBBPNameplateColor(unit)
    if BBF.isMidnight then return end
    local guid = UnitGUID(unit)
    if not guid then return end

    local npcID = select(6, strsplit("-", guid))
    local npcName = UnitName(unit)
    local lowerCaseNpcName = npcName and strlower(npcName)

    -- First check cache by npcID
    if npcID and npcColorCache[npcID] ~= nil then
        return npcColorCache[npcID]
    end

    -- Fallback to cache by name
    if lowerCaseNpcName and npcColorCache[lowerCaseNpcName] ~= nil then
        return npcColorCache[lowerCaseNpcName]
    end

    local colorNpcList = BetterBlizzPlatesDB.colorNpcList
    local npcHealthbarColor = nil

    for _, npc in ipairs(colorNpcList) do
        if npc.id == tonumber(npcID) or (npc.name and strlower(npc.name) == lowerCaseNpcName) then
            if npc.entryColors then
                npcHealthbarColor = npc.entryColors.text
            else
                npc.entryColors = {}
            end
            break
        end
    end

    -- Cache both ID and name for future use
    if npcID then
        npcColorCache[npcID] = npcHealthbarColor
    end
    if lowerCaseNpcName then
        npcColorCache[lowerCaseNpcName] = npcHealthbarColor
    end

    return npcHealthbarColor
end

local function getUnitColor(unit, useCustomColors, txt)
    if not UnitExists(unit) then return end

    if UnitIsPlayer(unit) or (C_LFGInfo.IsInLFGFollowerDungeon() and UnitInParty(unit)) then
        if TRP3_API and rpNames then
            local r,g,b = GetRPNameColor(unit)
            if r then
                return {r = r, g = g, b = b}, false
            else
                local _, className = UnitClass(unit)
                local color

                if useCustomColors and customHealthbarColors and overrideClassColors then
                    if useOneClassColor then
                        local customColor = singleClassColor or {1, 1, 1, 1}
                        color = {r = customColor[1], g = customColor[2], b = customColor[3], a = customColor[4] or 1}
                    else
                        local customColor = BetterBlizzFramesDB["classColor"..className]
                        if customColor then
                            color = {r = customColor[1], g = customColor[2], b = customColor[3], a = customColor[4] or 1}
                        else
                            color = RAID_CLASS_COLORS[className]
                        end
                    end
                else
                    color = RAID_CLASS_COLORS[className]
                end

                if color then
                    return {r = color.r, g = color.g, b = color.b, a = color.a or 1}, false
                end
            end
        else
            local _, className = UnitClass(unit)
            local color

            if useCustomColors and customHealthbarColors and overrideClassColors then
                if useOneClassColor then
                    local customColor = singleClassColor or {1, 1, 1, 1}
                    color = {r = customColor[1], g = customColor[2], b = customColor[3], a = customColor[4] or 1}
                else
                    local customColor = BetterBlizzFramesDB["classColor"..className]
                    if customColor then
                        color = {r = customColor[1], g = customColor[2], b = customColor[3], a = customColor[4] or 1}
                    else
                        color = RAID_CLASS_COLORS[className]
                    end
                end
            else
                color = RAID_CLASS_COLORS[className]
            end

            if color then
                if skipFriendly then
                    local reaction = getUnitReaction(unit)
                    return {r = color.r, g = color.g, b = color.b, a = color.a or 1}, ((unit == "player" and skipPlayer) or (skipFriendly and reaction == "FRIENDLY" and unit ~= "player"))
                else
                    return {r = color.r, g = color.g, b = color.b, a = color.a or 1}, false
                end
            end
        end
    elseif colorPetAfterOwner and unit == "pet" then
        -- Check if the unit is the player's pet and the setting is enabled
        local _, playerClass = UnitClass("player")
        local color = RAID_CLASS_COLORS[playerClass]
        if color then
            return {r = color.r, g = color.g, b = color.b, a = 1}, false
        end
    else
        if BetterBlizzPlatesDB and BetterBlizzPlatesDB.colorNPC then
            local npcHealthbarColor = GetBBPNameplateColor(unit)
            if npcHealthbarColor then
                return {r = npcHealthbarColor.r, g = npcHealthbarColor.g, b = npcHealthbarColor.b, a = 1}, false
            else
                local reaction = getUnitReaction(unit)
                if reaction == "HOSTILE" then
                    if UnitIsTapDenied(unit) and not txt then
                        return {r = 0.9, g = 0.9, b = 0.9, a = 1}, false
                    elseif useCustomColors and customHealthbarColors then
                        local enemyColor = BetterBlizzFramesDB.enemyHealthColor
                        return {r = enemyColor[1], g = enemyColor[2], b = enemyColor[3], a = enemyColor[4] or 1}, false
                    else
                        return {r = 1, g = 0, b = 0, a = 1}, false
                    end
                elseif reaction == "NEUTRAL" then
                    if UnitIsTapDenied(unit) and not txt then
                        return {r = 0.9, g = 0.9, b = 0.9, a = 1}, false
                    elseif useCustomColors and customHealthbarColors then
                        local neutralColor = BetterBlizzFramesDB.neutralHealthColor
                        return {r = neutralColor[1], g = neutralColor[2], b = neutralColor[3], a = neutralColor[4] or 1}, false
                    else
                        return {r = 1, g = 1, b = 0, a = 1}, false
                    end
                elseif reaction == "FRIENDLY" then
                    if useCustomColors and customHealthbarColors then
                        local friendlyColor = BetterBlizzFramesDB.friendlyHealthColor
                        return {r = friendlyColor[1], g = friendlyColor[2], b = friendlyColor[3], a = friendlyColor[4] or 1}, false
                    else
                        return {r = 0, g = 1, b = 0, a = 1}, true
                    end
                end
            end
        else
            local reaction = getUnitReaction(unit)

            if reaction == "HOSTILE" then
                if UnitIsTapDenied(unit) and not txt then
                    return {r = 0.9, g = 0.9, b = 0.9, a = 1}, false
                elseif useCustomColors and customHealthbarColors then
                    local enemyColor = BetterBlizzFramesDB.enemyHealthColor
                    return {r = enemyColor[1], g = enemyColor[2], b = enemyColor[3], a = enemyColor[4] or 1}, false
                else
                    return {r = 1, g = 0, b = 0, a = 1}, false
                end
            elseif reaction == "NEUTRAL" then
                if UnitIsTapDenied(unit) and not txt then
                    return {r = 0.9, g = 0.9, b = 0.9, a = 1}, false
                elseif useCustomColors and customHealthbarColors then
                    local neutralColor = BetterBlizzFramesDB.neutralHealthColor
                    return {r = neutralColor[1], g = neutralColor[2], b = neutralColor[3], a = neutralColor[4] or 1}, false
                else
                    return {r = 1, g = 1, b = 0, a = 1}, false
                end
            elseif reaction == "FRIENDLY" then
                if useCustomColors and customHealthbarColors then
                    local friendlyColor = BetterBlizzFramesDB.friendlyHealthColor
                    return {r = friendlyColor[1], g = friendlyColor[2], b = friendlyColor[3], a = friendlyColor[4] or 1}, false
                else
                    return {r = 0, g = 1, b = 0, a = 1}, true
                end
            end
        end
    end
end
BBF.getUnitColor = getUnitColor

local function updateFrameColorToggleVer(frame, unit)
    if not frame then return end
    if not frame.SetStatusBarDesaturated then return end
    if unit == "player" and skipPlayer then
        if retexturedBars then
            frame:SetStatusBarColor(0, 1, 0, 1)
        end
        return
    end

    if classColorsOn or (customHealthbarColors and customColorsUnitFrames) then
        local useCustomColors = customHealthbarColors and customColorsUnitFrames
        local shouldColorByClass = classColorsOn or (customHealthbarColors and overrideClassColors)

        if shouldColorByClass then
            local color, isFriendly = getUnitColor(unit, useCustomColors)
            if color then
                if isFriendly and (not frame.bbfChangedTexture or skipFriendly) then
                    frame:SetStatusBarDesaturated(false)
                    frame:SetStatusBarColor(1, 1, 1, 1)
                else
                    frame:SetStatusBarDesaturated(true)
                    frame:SetStatusBarColor(color.r, color.g, color.b, color.a or 1)
                end
            end
        else
            local color, isFriendly = getUnitColor(unit, useCustomColors)
            if color then
                if isFriendly and (not frame.bbfChangedTexture or skipFriendly) then
                    frame:SetStatusBarDesaturated(false)
                    frame:SetStatusBarColor(1, 1, 1, 1)
                else
                    frame:SetStatusBarDesaturated(true)
                    frame:SetStatusBarColor(color.r, color.g, color.b, color.a or 1)
                end
            end
        end
    end
end

BBF.updateFrameColorToggleVer = updateFrameColorToggleVer

local function resetFrameColor(frame, unit)
    if frame.bbfChangedTexture then
        frame:SetStatusBarDesaturated(false)
        frame:SetStatusBarColor(1, 1, 1, 1)
    else
        frame:SetStatusBarDesaturated(true)
        frame:SetStatusBarColor(0, 1, 0, 1)
    end
end

local validUnits = {
    player = true,
    target = true,
    targettarget = true,
    focus = true,
    focustarget = true,
    pet = true,
    party1 = true,
    party2 = true,
    party3 = true,
    party4 = true,
}

local function UpdateHealthColor(frame, unit)
    if not validUnits[unit] then return end
    if unit == "player" and skipPlayer then
        if retexturedBars then
            frame:SetStatusBarColor(0, 1, 0, 1)
        end
        return
    end

    local useCustomColors = customHealthbarColors and customColorsUnitFrames
    local color, isFriendly = getUnitColor(unit, useCustomColors)
    if color then
        if isFriendly and (not frame.bbfChangedTexture or skipFriendly) then
            frame:SetStatusBarDesaturated(false)
            frame:SetStatusBarColor(1, 1, 1, 1)
        else
            frame:SetStatusBarDesaturated(true)
            frame:SetStatusBarColor(color.r, color.g, color.b, color.a or 1)
        end
    end
end

local function UpdateHealthColorCF(frame, unit)
    if unit == "player" and BetterBlizzFramesDB.classColorFramesSkipPlayer then return end

    local useCustomColors = customHealthbarColors and customColorsUnitFrames
    local color, isFriendly = getUnitColor(unit, useCustomColors)
    if color then
        --frame:SetStatusBarDesaturated(true)
        frame:SetStatusBarColor(color.r, color.g, color.b, color.a or 1)
    end
end

function BBF.UpdateToTColor()
    updateFrameColorToggleVer(TargetFrameToT.HealthBar, "targettarget")
end

local function UpdatePowerColorCache()
    powerColorCache = {}
    useCustomPowerColors = customPowerColors and customHealthbarColors and customColorsUnitFrames

    if not useCustomPowerColors then
        return
    end

    if useOnePowerColor and singlePowerColor then
        powerColorCache.unified = {
            r = singlePowerColor[1],
            g = singlePowerColor[2],
            b = singlePowerColor[3],
            a = singlePowerColor[4] or 1
        }
        return
    end

    local powerTypes = {
        "MANA", "RAGE", "FOCUS", "ENERGY", "RUNIC_POWER",
        "LUNAR_POWER", "MAELSTROM", "INSANITY", "CHI", "FURY",
        "EBON_MIGHT", "STAGGER", "SOUL_FRAGMENTS"
    }

    for _, powerToken in ipairs(powerTypes) do
        local colorKey = "powerColor"..powerToken
        local customColor = BetterBlizzFramesDB[colorKey]
        if customColor then
            powerColorCache[powerToken] = {
                r = customColor[1],
                g = customColor[2],
                b = customColor[3],
                a = customColor[4] or 1
            }
        end
    end
end
BBF.UpdatePowerColorCache = UpdatePowerColorCache

local function GetCustomPowerColor(powerToken)
    if not powerToken or not useCustomPowerColors then return nil end

    if powerColorCache.unified then
        local c = powerColorCache.unified
        return c.r, c.g, c.b, c.a or 1
    end

    local color = powerColorCache[powerToken]
    if color then
        return color.r, color.g, color.b, color.a or 1
    end
    return nil
end
BBF.GetCustomPowerColor = GetCustomPowerColor

local function GetDefaultPowerColor(powerToken, bar)
    if not powerToken then return 0, 0, 1 end

    local powerBarColor = PowerBarColor[powerToken]
    if not powerBarColor then return 0, 0, 1 end

    if powerToken == "STAGGER" then
        if bar and bar.statusBarColorIndex then
            if bar.statusBarColorIndex == 1 then
                return powerBarColor.green.r, powerBarColor.green.g, powerBarColor.green.b
            elseif bar.statusBarColorIndex == 2 then
                return powerBarColor.yellow.r, powerBarColor.yellow.g, powerBarColor.yellow.b
            elseif bar.statusBarColorIndex == 3 then
                return powerBarColor.red.r, powerBarColor.red.g, powerBarColor.red.b
            end
        end
        return powerBarColor.green.r, powerBarColor.green.g, powerBarColor.green.b
    elseif powerToken == "SOUL_FRAGMENTS" then
        if bar and bar.inVoidMetamorphosis then
            return powerBarColor.collapsingStarProgess.r, powerBarColor.collapsingStarProgess.g, powerBarColor.collapsingStarProgess.b
        else
            return powerBarColor.voidMetamorphosisProgess.r, powerBarColor.voidMetamorphosisProgess.g, powerBarColor.voidMetamorphosisProgess.b
        end
    end

    return powerBarColor.r, powerBarColor.g, powerBarColor.b
end
BBF.GetDefaultPowerColor = GetDefaultPowerColor

local function SetupAlternateBarHook(bar, defaultColor)
    if not bar or bar.bbfTextureColorHook then return end

    local applyTexture = BetterBlizzFramesDB.changeUnitFrameManabarTexture
    local keepFancy = BetterBlizzFramesDB.changeUnitFrameManaBarTextureKeepFancy
    local fancyManas = BBF.fancyManas
    local manaTexture = BBF.manaTexture

    local hookFunc

    if useCustomPowerColors then
        if applyTexture then
            if keepFancy then
                hookFunc = function(self)
                    local powerToken = self.powerToken or self.powerName
                    if powerToken then
                        local r, g, b, a = GetCustomPowerColor(powerToken)
                        if not r then
                            r, g, b, a = defaultColor.r, defaultColor.g, defaultColor.b, 1
                        end

                        if not fancyManas[powerToken] then
                            self:SetStatusBarTexture(manaTexture)
                        end

                        self:SetStatusBarDesaturated(true)
                        self:SetStatusBarColor(r, g, b, a or 1)
                    end
                end
            else
                hookFunc = function(self)
                    local powerToken = self.powerToken or self.powerName
                    if powerToken then
                        local r, g, b, a = GetCustomPowerColor(powerToken)
                        if not r then
                            r, g, b, a = defaultColor.r, defaultColor.g, defaultColor.b, 1
                        end

                        self:SetStatusBarTexture(manaTexture)
                        self:SetStatusBarDesaturated(true)
                        self:SetStatusBarColor(r, g, b, a or 1)
                    end
                end
            end
        else
            hookFunc = function(self)
                local powerToken = self.powerToken or self.powerName
                if powerToken then
                    local r, g, b, a = GetCustomPowerColor(powerToken)
                    if not r then
                        r, g, b, a = defaultColor.r, defaultColor.g, defaultColor.b, 1
                    end

                    self:SetStatusBarDesaturated(true)
                    self:SetStatusBarColor(r, g, b, a or 1)
                end
            end
        end
    else
        if applyTexture then
            if keepFancy then
                hookFunc = function(self)
                    local powerToken = self.powerToken or self.powerName
                    if not powerToken or not fancyManas[powerToken] then
                        self:SetStatusBarTexture(manaTexture)
                    end
                    local r, g, b = GetDefaultPowerColor(powerToken, self)
                    self:SetStatusBarDesaturated(true)
                    self:SetStatusBarColor(r, g, b, 1)
                end
            else
                hookFunc = function(self)
                    self:SetStatusBarTexture(manaTexture)
                    local r, g, b = GetDefaultPowerColor(self.powerToken or self.powerName, self)
                    self:SetStatusBarDesaturated(true)
                    self:SetStatusBarColor(r, g, b, 1)
                end
            end
        else
            hookFunc = function(self)
                local r, g, b = GetDefaultPowerColor(self.powerToken or self.powerName, self)
                self:SetStatusBarDesaturated(true)
                self:SetStatusBarColor(r, g, b, 1)
            end
        end
    end

    hooksecurefunc(bar, "EvaluateUnit", hookFunc)
    bar.bbfTextureColorHook = true
end

local function HookPowerBarColors()
    if not customPowerColors or not customHealthbarColors then return end

    if customColorsUnitFrames and not BBF.powerColorsUnitFramesHooked then
        hooksecurefunc("UnitFrameManaBar_UpdateType", function(manabar)
            if not manabar or not manabar.unit then return end

            local _, powerToken = UnitPowerType(manabar.unit)
            if powerToken then
                local r, g, b, a = GetCustomPowerColor(powerToken)
                if r then
                    manabar:SetStatusBarDesaturated(true)
                    manabar:SetStatusBarColor(r, g, b, a or 1)
                end
            end
        end)
        BBF.powerColorsUnitFramesHooked = true
    end

    if customColorsRaidFrames and not BBF.powerColorsRaidFramesHooked then
        hooksecurefunc("CompactUnitFrame_UpdatePowerColor", function(frame)
            if not frame or not frame.unit or frame.unit:find("nameplate") or frame:IsForbidden() then return end

            local _, powerToken = UnitPowerType(frame.unit)
            if powerToken then
                local r, g, b, a = GetCustomPowerColor(powerToken)
                if r then
                    frame.powerBar:SetStatusBarColor(r, g, b, a or 1)
                end
            end
        end)
        BBF.powerColorsRaidFramesHooked = true
    end

    if customColorsUnitFrames and not BBF.altBarsTextureColorHooked and not BetterBlizzFramesDB.changeUnitFrameManabarTexture then
        local class = select(2, UnitClass("player"))

        local defaultColors = {
            AlternatePowerBar = {r = 0, g = 0, b = 1},
            MonkStaggerBar = {r = 0.52, g = 1.0, b = 0.52},
            EvokerEbonMightBar = {r = 0.9, g = 0.55, b = 0.3},
            DemonHunterSoulFragmentsBar = {r = 0.11, g = 0.34, b = 0.71}
        }

        if AlternatePowerBar then
            SetupAlternateBarHook(AlternatePowerBar, defaultColors.AlternatePowerBar)
        end

        if class == "MONK" and MonkStaggerBar then
            SetupAlternateBarHook(MonkStaggerBar, defaultColors.MonkStaggerBar)
        end

        if class == "EVOKER" and EvokerEbonMightBar then
            SetupAlternateBarHook(EvokerEbonMightBar, defaultColors.EvokerEbonMightBar)
        end

        if class == "DEMONHUNTER" and DemonHunterSoulFragmentsBar then
            SetupAlternateBarHook(DemonHunterSoulFragmentsBar, defaultColors.DemonHunterSoulFragmentsBar)
        end

        BBF.altBarsTextureColorHooked = true
    end
end

function BBF.UpdateFrames()
    classColorsOn = BetterBlizzFramesDB.classColorFrames
    retexturedBars = BetterBlizzFramesDB.changeUnitFrameHealthbarTexture
    colorPetAfterOwner = BetterBlizzFramesDB.colorPetAfterOwner
    skipPlayer = BetterBlizzFramesDB.classColorFramesSkipPlayer
    skipFriendly = BetterBlizzFramesDB.classColorFramesSkipFriendly
    rpNames = BetterBlizzFramesDB.rpNamesHealthbarColor
    rpNamesHealthbarColor = BetterBlizzFramesDB.rpNamesHealthbarColor
    customHealthbarColors = BetterBlizzFramesDB.customHealthbarColors
    overrideClassColors = BetterBlizzFramesDB.overrideClassColors
    customColorsUnitFrames = BetterBlizzFramesDB.customColorsUnitFrames
    customColorsRaidFrames = BetterBlizzFramesDB.customColorsRaidFrames
    useOneClassColor = BetterBlizzFramesDB.useOneClassColor
    singleClassColor = BetterBlizzFramesDB.singleClassColor
    useOnePowerColor = BetterBlizzFramesDB.useOnePowerColor
    singlePowerColor = BetterBlizzFramesDB.singlePowerColor
    customPowerColors = BetterBlizzFramesDB.customPowerColors
    if customPowerColors then
        UpdatePowerColorCache()
        HookPowerBarColors()

        if customHealthbarColors and customColorsUnitFrames then
            if PlayerFrame.PlayerFrameContent.PlayerFrameContentMain.ManaBarArea.ManaBar then
                local _, powerToken = UnitPowerType("player")
                if powerToken then
                    local r, g, b, a = GetCustomPowerColor(powerToken)
                    if r then
                        PlayerFrame.PlayerFrameContent.PlayerFrameContentMain.ManaBarArea.ManaBar:SetStatusBarDesaturated(true)
                        PlayerFrame.PlayerFrameContent.PlayerFrameContentMain.ManaBarArea.ManaBar:SetStatusBarColor(r, g, b, a or 1)
                    end
                end
            end

            if UnitExists("target") and TargetFrame.TargetFrameContent.TargetFrameContentMain.ManaBar then
                local _, powerToken = UnitPowerType("target")
                if powerToken then
                    local r, g, b, a = GetCustomPowerColor(powerToken)
                    if r then
                        TargetFrame.TargetFrameContent.TargetFrameContentMain.ManaBar:SetStatusBarDesaturated(true)
                        TargetFrame.TargetFrameContent.TargetFrameContentMain.ManaBar:SetStatusBarColor(r, g, b, a or 1)
                    end
                end
            end

            if UnitExists("focus") and FocusFrame.TargetFrameContent.TargetFrameContentMain.ManaBar then
                local _, powerToken = UnitPowerType("focus")
                if powerToken then
                    local r, g, b, a = GetCustomPowerColor(powerToken)
                    if r then
                        FocusFrame.TargetFrameContent.TargetFrameContentMain.ManaBar:SetStatusBarDesaturated(true)
                        FocusFrame.TargetFrameContent.TargetFrameContentMain.ManaBar:SetStatusBarColor(r, g, b, a or 1)
                    end
                end
            end

            if UnitExists("pet") and PetFrame.manabar then
                local _, powerToken = UnitPowerType("pet")
                if powerToken then
                    local r, g, b, a = GetCustomPowerColor(powerToken)
                    if r then
                        PetFrame.manabar:SetStatusBarDesaturated(true)
                        PetFrame.manabar:SetStatusBarColor(r, g, b, a or 1)
                    end
                end
            end

            if UnitExists("targettarget") and TargetFrame.totFrame.ManaBar then
                local _, powerToken = UnitPowerType("targettarget")
                if powerToken then
                    local r, g, b, a = GetCustomPowerColor(powerToken)
                    if r then
                        TargetFrame.totFrame.ManaBar:SetStatusBarDesaturated(true)
                        TargetFrame.totFrame.ManaBar:SetStatusBarColor(r, g, b, a or 1)
                    end
                end
            end

            if UnitExists("focustarget") and FocusFrame.totFrame.ManaBar then
                local _, powerToken = UnitPowerType("focustarget")
                if powerToken then
                    local r, g, b, a = GetCustomPowerColor(powerToken)
                    if r then
                        FocusFrame.totFrame.ManaBar:SetStatusBarDesaturated(true)
                        FocusFrame.totFrame.ManaBar:SetStatusBarColor(r, g, b, a or 1)
                    end
                end
            end

            if not EditModeManagerFrame:UseRaidStylePartyFrames() then
                for i = 1, 4 do
                    local unit = "party"..i
                    if UnitExists(unit) then
                        local frame = PartyFrame["MemberFrame"..i]
                        if frame and frame.ManaBar then
                            local _, powerToken = UnitPowerType(unit)
                            if powerToken then
                                local r, g, b, a = GetCustomPowerColor(powerToken)
                                if r then
                                    frame.ManaBar:SetStatusBarDesaturated(true)
                                    frame.ManaBar:SetStatusBarColor(r, g, b, a or 1)
                                end
                            end
                        end
                    end
                end
            end
        end
    end

    local shouldColorUnitFrames = classColorsOn or (customHealthbarColors and customColorsUnitFrames)
    if shouldColorUnitFrames then
        BBF.HookHealthbarColors()
        if UnitExists("player") then updateFrameColorToggleVer(PlayerFrame.healthbar, "player") end
        if UnitExists("pet") then updateFrameColorToggleVer(PetFrame.healthbar, "pet") end
        if UnitExists("target") then updateFrameColorToggleVer(TargetFrame.healthbar, "target") end
        if UnitExists("focus") then updateFrameColorToggleVer(FocusFrame.healthbar, "focus") end
        if UnitExists("targettarget") then updateFrameColorToggleVer(TargetFrameToT.HealthBar, "targettarget") end
        if UnitExists("focustarget") then updateFrameColorToggleVer(FocusFrameToT.HealthBar, "focustarget") end
        if UnitExists("party1") then updateFrameColorToggleVer(PartyFrame.MemberFrame1.HealthBarContainer.HealthBar, "party1") end
        if UnitExists("party2") then updateFrameColorToggleVer(PartyFrame.MemberFrame2.HealthBarContainer.HealthBar, "party2") end
        if UnitExists("party3") then updateFrameColorToggleVer(PartyFrame.MemberFrame3.HealthBarContainer.HealthBar, "party3") end
        if UnitExists("party4") then updateFrameColorToggleVer(PartyFrame.MemberFrame4.HealthBarContainer.HealthBar, "party4") end
        BBF.HealthColorOn = true
    else
        if BBF.HealthColorOn then
            if UnitExists("player") then resetFrameColor(PlayerFrame.healthbar, "player") end
            if UnitExists("pet") then resetFrameColor(PetFrame.healthbar, "pet") end
            if UnitExists("target") then resetFrameColor(TargetFrame.healthbar, "target") end
            if UnitExists("focus") then resetFrameColor(FocusFrame.healthbar, "focus") end
            if UnitExists("targettarget") then resetFrameColor(TargetFrameToT.HealthBar, "targettarget") end
            if UnitExists("focustarget") then resetFrameColor(FocusFrameToT.HealthBar, "focustarget") end
            if UnitExists("party1") then resetFrameColor(PartyFrame.MemberFrame1.HealthBarContainer.HealthBar, "party1") end
            if UnitExists("party2") then resetFrameColor(PartyFrame.MemberFrame2.HealthBarContainer.HealthBar, "party2") end
            if UnitExists("party3") then resetFrameColor(PartyFrame.MemberFrame3.HealthBarContainer.HealthBar, "party3") end
            if UnitExists("party4") then resetFrameColor(PartyFrame.MemberFrame4.HealthBarContainer.HealthBar, "party4") end
            BBF.HealthColorOn = nil
        end
    end
    if colorPetAfterOwner then
        if UnitExists("pet") then updateFrameColorToggleVer(PetFrame.healthbar, "pet") end
    end

    if customHealthbarColors and customColorsRaidFrames then
        for i = 1, 5 do
            local frame = _G["CompactPartyFrameMember" .. i]
            if frame and frame:IsShown() and frame.unit and frame.healthBar then
                local color, isFriendly = getUnitColor(frame.unit, true)
                if color then
                    frame.healthBar:SetStatusBarColor(color.r, color.g, color.b, color.a or 1)
                end

                if customPowerColors and frame.powerBar then
                    local _, powerToken = UnitPowerType(frame.unit)
                    if powerToken then
                        local r, g, b, a = GetCustomPowerColor(powerToken)
                        if not r then
                            r, g, b = GetDefaultPowerColor(powerToken, frame.powerBar)
                            a = 1
                        end
                        if r then
                            frame.powerBar:SetStatusBarColor(r, g, b, a or 1)
                        end
                    end
                end
            end
        end

        if IsInRaid() then
            for i = 1, 40 do
                local frame = _G["CompactRaidFrame" .. i]
                if frame and frame:IsShown() and frame.unit and frame.healthBar then
                    local color, isFriendly = getUnitColor(frame.unit, true)
                    if color then
                        frame.healthBar:SetStatusBarColor(color.r, color.g, color.b, color.a or 1)
                    end

                    if customPowerColors and frame.powerBar then
                        local _, powerToken = UnitPowerType(frame.unit)
                        if powerToken then
                            local r, g, b, a = GetCustomPowerColor(powerToken)
                            if not r then
                                r, g, b = GetDefaultPowerColor(powerToken, frame.powerBar)
                                a = 1
                            end
                            if r then
                                frame.powerBar:SetStatusBarColor(r, g, b, a or 1)
                            end
                        end
                    end
                end
            end
        end
    end

    if customPowerColors and customHealthbarColors and customColorsUnitFrames then
        if AlternatePowerBar and AlternatePowerBar:IsShown() then
            local powerToken = AlternatePowerBar.powerToken or AlternatePowerBar.powerName
            if powerToken then
                local r, g, b, a = GetCustomPowerColor(powerToken)
                if r then
                    AlternatePowerBar:SetStatusBarColor(r, g, b, a or 1)
                end
            end
        end

        local class = select(2, UnitClass("player"))
        if class == "MONK" and MonkStaggerBar and MonkStaggerBar:IsShown() then
            local powerToken = MonkStaggerBar.powerToken or MonkStaggerBar.powerName
            if powerToken then
                local r, g, b, a = GetCustomPowerColor(powerToken)
                if r then
                    MonkStaggerBar:SetStatusBarColor(r, g, b, a or 1)
                end
            end
        end

        if class == "EVOKER" and EvokerEbonMightBar and EvokerEbonMightBar:IsShown() then
            local powerToken = EvokerEbonMightBar.powerToken or EvokerEbonMightBar.powerName
            if powerToken then
                local r, g, b, a = GetCustomPowerColor(powerToken)
                if r then
                    EvokerEbonMightBar:SetStatusBarColor(r, g, b, a or 1)
                end
            end
        end

        if class == "DEMONHUNTER" and DemonHunterSoulFragmentsBar and DemonHunterSoulFragmentsBar:IsShown() then
            local powerToken = DemonHunterSoulFragmentsBar.powerToken or DemonHunterSoulFragmentsBar.powerName
            if powerToken then
                local r, g, b, a = GetCustomPowerColor(powerToken)
                if r then
                    DemonHunterSoulFragmentsBar:SetStatusBarColor(r, g, b, a or 1)
                    DemonHunterSoulFragmentsBar:SetStatusBarDesaturated(true)

                    if DemonHunterSoulFragmentsBar.Spark then
                        DemonHunterSoulFragmentsBar.Spark:SetDesaturated(true)
                        DemonHunterSoulFragmentsBar.Spark:SetVertexColor(r, g, b)
                    end

                    if DemonHunterSoulFragmentsBar.CollapsingStarBackground then
                        DemonHunterSoulFragmentsBar.CollapsingStarBackground:SetDesaturated(true)
                        DemonHunterSoulFragmentsBar.CollapsingStarBackground:SetVertexColor(r, g, b)
                    end

                    if DemonHunterSoulFragmentsBar.Glow then
                        DemonHunterSoulFragmentsBar.Glow:SetDesaturated(true)
                        DemonHunterSoulFragmentsBar.Glow:SetVertexColor(r, g, b)
                    end

                    if DemonHunterSoulFragmentsBar.Ready then
                        DemonHunterSoulFragmentsBar.Ready:SetDesaturated(true)
                        DemonHunterSoulFragmentsBar.Ready:SetVertexColor(r, g, b)
                    end

                    if DemonHunterSoulFragmentsBar.Deplete then
                        DemonHunterSoulFragmentsBar.Deplete:SetDesaturated(true)
                        DemonHunterSoulFragmentsBar.Deplete:SetVertexColor(r, g, b)
                    end

                    if DemonHunterSoulFragmentsBar.CollapsingStarDepleteFin then
                        DemonHunterSoulFragmentsBar.CollapsingStarDepleteFin:SetDesaturated(true)
                        DemonHunterSoulFragmentsBar.CollapsingStarDepleteFin:SetVertexColor(r, g, b)
                    end
                end
            end
        end
    end
end

function BBF.UpdateFrameColor(frame, unit)
    local useCustomColors = customHealthbarColors and customColorsUnitFrames
    local color, isFriendly = getUnitColor(unit, useCustomColors)
    if color then
        if isFriendly and not frame.bbfChangedTexture then
            frame:SetStatusBarDesaturated(false)
            frame:SetStatusBarColor(1, 1, 1, 1)
        else
            frame:SetStatusBarDesaturated(true)
            frame:SetStatusBarColor(color.r, color.g, color.b, color.a or 1)
        end
    end
end

function BBF.ClassColorReputation(frame, unit)
    local useCustomColors = customHealthbarColors and customColorsUnitFrames
    local color = getUnitColor(unit, useCustomColors)
    if color then
        frame:SetDesaturated(true)
        frame:SetVertexColor(color.r, color.g, color.b)
    end

    if not frame.bbfColorHook then
        hooksecurefunc(frame, "SetVertexColor", function(self)
            if self.changing then return end
            self.changing = true
            local useCustomColors = customHealthbarColors and customColorsUnitFrames
            local color = getUnitColor(unit, useCustomColors)
            if color then
                frame:SetDesaturated(true)
                frame:SetVertexColor(color.r, color.g, color.b)
            end
            self.changing = false
        end)
        frame.bbfColorHook = true
    end
end

function BBF.ClassColorReputationCaller()
    if BetterBlizzFramesDB.classColorTargetReputationTexture then
        BBF.ClassColorReputation(TargetFrame.TargetFrameContent.TargetFrameContentMain.ReputationColor, "target")
    end

    if BetterBlizzFramesDB.classColorFocusReputationTexture then
        BBF.ClassColorReputation(FocusFrame.TargetFrameContent.TargetFrameContentMain.ReputationColor, "focus")
    end
end

function BBF.ResetClassColorReputation(frame, unit)
    local useCustomColors = customHealthbarColors and customColorsUnitFrames
    local color = getUnitColor(unit, useCustomColors)
    if color then
        frame:SetDesaturated(false)
        frame:SetVertexColor(UnitSelectionColor(unit))
    end
end

function BBF.HookHealthbarColors()
    local shouldHook = classColorsOn or (customHealthbarColors and customColorsUnitFrames)
    if not healthbarsHooked and shouldHook then

        local function HookCfSetStatusBarColor(frame, unit)
            if not frame.SetStatusBarColorHooked then
                hooksecurefunc(frame, "SetStatusBarColor", function(self, r, g, b, a)
                    if not frame.recoloring then
                        frame.recoloring = true
                        -- Only use custom colors if customHealthbarColors is enabled
                        local useCustomColors = customHealthbarColors and customColorsUnitFrames
                        local color = getUnitColor(unit, useCustomColors)
                        if color then
                            frame:SetStatusBarColor(color.r, color.g, color.b, color.a or 1)
                        end
                        frame.recoloring = false
                    end
                end)
                -- Only use custom colors if customHealthbarColors is enabled
                local useCustomColors = customHealthbarColors and customColorsUnitFrames
                local color = getUnitColor(unit, useCustomColors)
                if color then
                    frame:SetStatusBarColor(color.r, color.g, color.b, color.a or 1)
                end
                frame.SetStatusBarColorHooked = true
            end
        end

        if C_AddOns.IsAddOnLoaded("ClassicFrames") then
            hooksecurefunc("UnitFrameHealthBar_Update", function(self, unit)
                if unit then
                    UpdateHealthColorCF(TargetFrameToT.HealthBar, "targettarget")
                    UpdateHealthColorCF(FocusFrameToT.HealthBar, "focustarget")
                end
            end)
            if CfPlayerFrameHealthBar then
                if not BetterBlizzFramesDB.classColorFramesSkipPlayer then
                    HookCfSetStatusBarColor(CfPlayerFrameHealthBar, "player")
                end
                HookCfSetStatusBarColor(CfTargetFrameHealthBar, "target")
                HookCfSetStatusBarColor(CfFocusFrameHealthBar, "focus")
            else
                BBF.Print(L["Print_ClassicFrames_Not_Detected"])
            end
        else
            hooksecurefunc("UnitFrameHealthBar_Update", function(self, unit)
                if unit then
                    UpdateHealthColor(self, unit)
                    UpdateHealthColor(TargetFrameToT.HealthBar, "targettarget")
                    UpdateHealthColor(FocusFrameToT.HealthBar, "focustarget")
                end
            end)
        end

        if (rpNamesHealthbarColor and TRP3_API) or customHealthbarColors then
            local function UpdateHealthColorUnified(frame)
                if not frame or not frame.unit or frame.unit:find("nameplate") or frame:IsForbidden() then return end

                if TRP3_API and rpNamesHealthbarColor then
                    local r, g, b = GetRPNameColor(frame.unit)
                    if r then
                        frame.healthBar:SetStatusBarColor(r, g, b, 1)
                        frame.recolored = true
                        return
                    end
                end

                if customHealthbarColors and customColorsRaidFrames then
                    local color, isFriendly = getUnitColor(frame.unit, true)
                    if color then
                        frame.healthBar:SetStatusBarColor(color.r, color.g, color.b, color.a or 1)
                        frame.recolored = true
                        return
                    end
                end

                if frame.recolored then
                    if UnitIsPlayer(frame.unit) then
                        local classColor = RAID_CLASS_COLORS[select(2, UnitClass(frame.unit))]
                        if classColor then
                            frame.healthBar:SetStatusBarColor(classColor.r, classColor.g, classColor.b, 1)
                        end
                    end
                    frame.recolored = nil
                end
            end

            hooksecurefunc("CompactUnitFrame_UpdateHealthColor", UpdateHealthColorUnified)

            local function ApplyColorsToPartyFrames()
                for i = 1, 4 do
                    local frame = _G["CompactPartyFrameMember" .. i]
                    if frame and frame:IsShown() then
                        UpdateHealthColorUnified(frame)
                    end
                end
            end

            ApplyColorsToPartyFrames()
        end

        healthbarsHooked = true
    elseif not healthbarsHooked and ((rpNamesHealthbarColor and TRP3_API) or customHealthbarColors) then
        retexturedBars = BetterBlizzFramesDB.changeUnitFrameHealthbarTexture

        local function UpdateHealthColorUnified(frame)
            if not frame or not frame.unit or frame.unit:find("nameplate") or frame:IsForbidden() then return end

            if rpNamesHealthbarColor and TRP3_API then
                local r, g, b = GetRPNameColor(frame.unit)
                if r then
                    frame.healthBar:SetStatusBarColor(r, g, b, 1)
                    frame.recolored = true
                    return
                end
            end

            if customHealthbarColors and customColorsRaidFrames then
                local color, isFriendly = getUnitColor(frame.unit, true)
                if color then
                    frame.healthBar:SetStatusBarColor(color.r, color.g, color.b, color.a or 1)
                    frame.recolored = true
                    return
                end
            end

            if frame.recolored then
                if UnitIsPlayer(frame.unit) then
                    local classColor = RAID_CLASS_COLORS[select(2, UnitClass(frame.unit))]
                    if classColor then
                        frame.healthBar:SetStatusBarColor(classColor.r, classColor.g, classColor.b, 1)
                    end
                end
                frame.recolored = nil
            end
        end

        hooksecurefunc("CompactUnitFrame_UpdateHealthColor", UpdateHealthColorUnified)

        local function ApplyColorsToPartyFrames()
            for i = 1, 4 do
                local frame = _G["CompactPartyFrameMember" .. i]
                if frame and frame:IsShown() then
                    UpdateHealthColorUnified(frame)
                end
            end
        end

        ApplyColorsToPartyFrames()

        local function getRPUnitColor(unit)
            local r,g,b = GetRPNameColor(unit)
            if r then
                return {r = r, g = g, b = b}
            end
        end

        local function UpdateRPHealthColor(frame, unit)
            if not validUnits[unit] then return end
            if UnitIsPlayer(unit) or (C_LFGInfo.IsInLFGFollowerDungeon() and UnitInParty(unit)) then
                local color = getRPUnitColor(unit)
                if color then
                    frame:SetStatusBarDesaturated(true)
                    frame:SetStatusBarColor(color.r, color.g, color.b, 1)
                else
                    if retexturedBars then
                        frame:SetStatusBarDesaturated(true)
                        frame:SetStatusBarColor(0, 1, 0, 1)
                    else
                        frame:SetStatusBarDesaturated(false)
                        frame:SetStatusBarColor(1, 1, 1, 1)
                    end
                end
            else
                if retexturedBars then
                    frame:SetStatusBarDesaturated(true)
                    frame:SetStatusBarColor(0, 1, 0, 1)
                else
                    frame:SetStatusBarDesaturated(false)
                    frame:SetStatusBarColor(1, 1, 1, 1)
                end
            end
        end

        hooksecurefunc("UnitFrameHealthBar_Update", function(self, unit)
            if unit then
                UpdateRPHealthColor(self, unit)
                UpdateRPHealthColor(TargetFrameToT.HealthBar, "targettarget")
                UpdateRPHealthColor(FocusFrameToT.HealthBar, "focustarget")
            end
        end)

        UpdateRPHealthColor(PlayerFrame.healthbar, "player")
        if UnitExists("target") then
            UpdateRPHealthColor(TargetFrame.healthbar, "target")
        end
        if UnitExists("focus") then
            UpdateRPHealthColor(FocusFrame.healthbar, "focus")
        end
        C_Timer.After(1, function()
            UpdateRPHealthColor(PlayerFrame.healthbar, "player")
        end)

        healthbarsHooked = true
    end
end


function BBF.PlayerReputationColor()
    local frame = PlayerFrame.PlayerFrameContent.PlayerFrameContentMain
    if BetterBlizzFramesDB.playerReputationColor and not BetterBlizzFramesDB.noPortraitModes then
        if not frame.ReputationColor then
            frame.ReputationColor = frame:CreateTexture(nil, "OVERLAY")
            if BetterBlizzFramesDB.classicFrames then
                if BetterBlizzFramesDB.changeUnitFrameNameBgTexture then
                    local nameBgTexture = BBF.LSM:Fetch(BBF.LSM.MediaType.STATUSBAR, BetterBlizzFramesDB.unitFrameNameBgTexture)
                    frame.ReputationColor:SetTexture(nameBgTexture)
                    frame.ReputationColor:SetTexCoord(0, 1, 0, 1)
                else
                    if not BetterBlizzFramesDB.changeUnitFrameHealthbarTexture then
                        frame.ReputationColor:SetTexture(137017)
                        frame.ReputationColor:SetTexCoord(1, 0, 0, 1)
                    else
                        local texture = BBF.LSM:Fetch(BBF.LSM.MediaType.STATUSBAR, BetterBlizzFramesDB.unitFrameHealthbarTexture)
                        frame.ReputationColor:SetTexture(texture)
                        frame.ReputationColor:SetTexCoord(0, 1, 0, 1)
                    end
                end
                frame.ReputationColor:SetSize(117, 18)
                frame.ReputationColor:SetPoint("TOPRIGHT", frame, "TOPRIGHT", -26, -30)
            elseif C_AddOns.IsAddOnLoaded("ClassicFrames") then
                frame.ReputationColor:SetTexture(137017)
                frame.ReputationColor:SetSize(117, 19)
                frame.ReputationColor:SetTexCoord(1, 0, 0, 1)
                frame.ReputationColor:SetPoint("TOPRIGHT", frame, "TOPRIGHT", -26, -26)
            else
                frame.ReputationColor:SetAtlas("UI-HUD-UnitFrame-Target-PortraitOn-Type")
                frame.ReputationColor:SetSize(136, 20)
                frame.ReputationColor:SetTexCoord(1, 0, 0, 1)
                frame.ReputationColor:SetPoint("TOPRIGHT", frame, "TOPRIGHT", -21, -25)
            end
        else
            frame.ReputationColor:Show()
        end
        if BetterBlizzFramesDB.playerReputationClassColor then
            local useCustomColors = customHealthbarColors and customColorsUnitFrames
            local color = getUnitColor("player", useCustomColors)
            if color then
                frame.ReputationColor:SetDesaturated(true)
                frame.ReputationColor:SetVertexColor(color.r, color.g, color.b)
            end
        else
            frame.ReputationColor:SetDesaturated(false)
            frame.ReputationColor:SetVertexColor(UnitSelectionColor("player"))
        end
    else
        if frame.ReputationColor then
            frame.ReputationColor:Hide()
        end
    end
end




function BBF.HookFrameTextureColor()
    if BBF.FrameTextureColor then return end
    local classColorFrameTexture = BetterBlizzFramesDB.classColorFrameTexture
    local rpColor = BetterBlizzFramesDB.rpNamesFrameTextureColor
    if not classColorFrameTexture and not rpColor then return end

    local darkmode = BetterBlizzFramesDB.darkModeUi
    local darkmodeColor = BetterBlizzFramesDB.darkModeColor


    local function DesaturateAndColorTexture(texture, unit)
        if not UnitExists(unit) then return end

        local color = darkmode and darkmodeColor or 1
        local r, g, b = color, color, color
        local desaturate = darkmode and true or false
        local colored = false

        if UnitIsPlayer(unit) or (C_LFGInfo.IsInLFGFollowerDungeon() and UnitInParty(unit)) then
            if TRP3_API and rpColor then
                local rpR, rpG, rpB = GetRPNameColor(unit)
                if rpR then
                    r, g, b = rpR, rpG, rpB
                    desaturate = true
                    colored = true
                end
            end

            if not colored and classColorFrameTexture then
                local _, class = UnitClass(unit)
                local color = RAID_CLASS_COLORS[class]
                if color then
                    r, g, b = color.r, color.g, color.b
                    desaturate = true
                    colored = true
                end
            end
        end

        texture:SetDesaturated(desaturate)
        texture.changing = true
        texture:SetVertexColor(r, g, b)
        texture.changing = false
    end


    local function SetupFrame(frame, unit, colorUnit)
        if not frame then return end
        colorUnit = colorUnit or unit

        local texture = (frame.TargetFrameContainer and frame.TargetFrameContainer.FrameTexture)
            or (frame.PlayerFrameContainer and frame.PlayerFrameContainer.FrameTexture)
            or frame.FrameTexture or (unit == "pet" and PetFrameTexture)
        local altTexture = (frame.TargetFrameContainer and frame.TargetFrameContainer.AlternatePowerFrameTexture)
            or (frame.PlayerFrameContainer and frame.PlayerFrameContainer.AlternatePowerFrameTexture)
            or frame.AlternatePowerFrameTexture
        if not texture then return end

        if not texture.bbfColorHook then
            hooksecurefunc(texture, "SetVertexColor", function(self)
                if self.changing then return end
                DesaturateAndColorTexture(self, colorUnit)
            end)
            texture.bbfColorHook = true
        end
        if altTexture and not altTexture.bbfColorHook then
            hooksecurefunc(altTexture, "SetVertexColor", function(self)
                if self.changing then return end
                DesaturateAndColorTexture(self, colorUnit)
            end)
            altTexture.bbfColorHook = true
        end

        DesaturateAndColorTexture(texture, colorUnit)
        if altTexture then
            DesaturateAndColorTexture(altTexture, colorUnit)
        end
    end

    -- Setup all frames
    SetupFrame(PlayerFrame, "player")
    SetupFrame(TargetFrame, "target")
    SetupFrame(FocusFrame, "focus")
    SetupFrame(TargetFrameToT, "targettarget")
    SetupFrame(FocusFrameToT, "focustarget")
    SetupFrame(PetFrame, "pet", "player")

    for frame in PartyFrame.PartyMemberFramePool:EnumerateActive() do
        local unit = frame.unit or ("party" .. frame:GetID())
        SetupFrame(frame, unit)
    end

    C_Timer.After(1, function()
        SetupFrame(PlayerFrame, "player")
        SetupFrame(PetFrame, "pet", "player")
    end)

    local f = CreateFrame("Frame")
    f:RegisterEvent("PLAYER_TARGET_CHANGED")
    f:RegisterEvent("PLAYER_FOCUS_CHANGED")
    f:RegisterUnitEvent("UNIT_TARGET", "target", "focus")
    f:RegisterEvent("GROUP_ROSTER_UPDATE")
    f:RegisterEvent("PLAYER_ENTERING_WORLD")
    f:SetScript("OnEvent", function(self, event)
        if event == "PLAYER_ENTERING_WORLD" or event == "GROUP_ROSTER_UPDATE" then
            for frame in PartyFrame.PartyMemberFramePool:EnumerateActive() do
                local unit = frame.unit or ("party" .. frame:GetID())
                DesaturateAndColorTexture(frame.Texture, unit)
            end
            return
        end
        if event == "PLAYER_TARGET_CHANGED" then
            DesaturateAndColorTexture(TargetFrame.TargetFrameContainer.FrameTexture, "target")
        elseif event == "PLAYER_FOCUS_CHANGED" then
            DesaturateAndColorTexture(FocusFrame.TargetFrameContainer.FrameTexture, "focus")
        end
        DesaturateAndColorTexture(TargetFrameToT.FrameTexture, "targettarget")
        DesaturateAndColorTexture(FocusFrameToT.FrameTexture, "focustarget")
    end)

    BBF.FrameTextureColor = true
end

function BBF.SetCompactUnitFramesBackground()
    if not BetterBlizzFramesDB.changePartyRaidFrameBackgroundColor then return end

    local healthColor = BetterBlizzFramesDB.partyRaidFrameBackgroundHealthColor or {0, 0, 0, 1}
    local healthR, healthG, healthB, healthA = healthColor[1], healthColor[2], healthColor[3], healthColor[4]

    local manaColor = BetterBlizzFramesDB.partyRaidFrameBackgroundManaColor or {0, 0, 0, 1}
    local manaR, manaG, manaB, manaA = manaColor[1], manaColor[2], manaColor[3], manaColor[4]

    local bgTexture = BBF.LSM:Fetch(BBF.LSM.MediaType.STATUSBAR, BetterBlizzFramesDB.raidFrameBgTexture)

    for i = 1, 5 do
        local frame = _G["CompactPartyFrameMember"..i]
        if frame and frame.background and frame.healthBar then
            frame.background:SetDrawLayer("BACKGROUND", -1)

            if not frame.bbfHealthBackground then
                local tex = frame:CreateTexture(nil, "BACKGROUND", nil, 0)
                frame.bbfHealthBackground = tex
                tex:SetPoint("TOPLEFT", frame.healthBar, "TOPLEFT", 0, 0)
                tex:SetPoint("BOTTOMRIGHT", frame.healthBar, "BOTTOMRIGHT", 0, 0)
            end
            frame.bbfHealthBackground:SetTexture(bgTexture)
            frame.bbfHealthBackground:SetVertexColor(healthR, healthG, healthB, healthA)

            if frame.powerBar then
                if not frame.bbfManaBackground then
                    local tex = frame:CreateTexture(nil, "BACKGROUND", nil, 0)
                    frame.bbfManaBackground = tex
                    tex:SetPoint("TOPLEFT", frame.powerBar, "TOPLEFT", 0, 0)
                    tex:SetPoint("BOTTOMRIGHT", frame.powerBar, "BOTTOMRIGHT", 0, 0)
                end
                frame.bbfManaBackground:SetTexture(bgTexture)
                frame.bbfManaBackground:SetVertexColor(manaR, manaG, manaB, manaA)
            end
        end
    end

    for i = 1, 40 do
        local frame = _G["CompactRaidFrame"..i]
        if frame and frame.background and frame.healthBar then
            frame.background:SetDrawLayer("BACKGROUND", -1)

            if not frame.bbfHealthBackground then
                local tex = frame:CreateTexture(nil, "BACKGROUND", nil, 0)
                frame.bbfHealthBackground = tex
                tex:SetPoint("TOPLEFT", frame.healthBar, "TOPLEFT", 0, 0)
                tex:SetPoint("BOTTOMRIGHT", frame.healthBar, "BOTTOMRIGHT", 0, 0)
            end
            frame.bbfHealthBackground:SetTexture(bgTexture)
            frame.bbfHealthBackground:SetVertexColor(healthR, healthG, healthB, healthA)

            if frame.powerBar then
                if not frame.bbfManaBackground then
                    local tex = frame:CreateTexture(nil, "BACKGROUND", nil, 0)
                    frame.bbfManaBackground = tex
                    tex:SetPoint("TOPLEFT", frame.powerBar, "TOPLEFT", 0, 0)
                    tex:SetPoint("BOTTOMRIGHT", frame.powerBar, "BOTTOMRIGHT", 0, 0)
                end
                frame.bbfManaBackground:SetTexture(bgTexture)
                frame.bbfManaBackground:SetVertexColor(manaR, manaG, manaB, manaA)
            end
        end
    end

    for i = 1, 8 do
        for j = 1, 5 do
            local frame = _G["CompactRaidGroup"..i.."Member"..j]
            if frame and frame.background then
                frame.background:SetDrawLayer("BACKGROUND", -1)

                if not frame.bbfHealthBackground then
                    local tex = frame:CreateTexture(nil, "BACKGROUND", nil, 0)
                    frame.bbfHealthBackground = tex
                    tex:SetPoint("TOPLEFT", frame.healthBar, "TOPLEFT", 0, 0)
                    tex:SetPoint("BOTTOMRIGHT", frame.healthBar, "BOTTOMRIGHT", 0, 0)
                end
                frame.bbfHealthBackground:SetTexture(bgTexture)
                frame.bbfHealthBackground:SetVertexColor(healthR, healthG, healthB, healthA)

                if frame.powerBar then
                    if not frame.bbfManaBackground then
                        local tex = frame:CreateTexture(nil, "BACKGROUND", nil, 0)
                        frame.bbfManaBackground = tex
                        tex:SetPoint("TOPLEFT", frame.powerBar, "TOPLEFT", 0, 0)
                        tex:SetPoint("BOTTOMRIGHT", frame.powerBar, "BOTTOMRIGHT", 0, 0)
                    end
                    frame.bbfManaBackground:SetTexture(bgTexture)
                    frame.bbfManaBackground:SetVertexColor(manaR, manaG, manaB, manaA)
                end
            end
        end
    end

    if not BBF.PetFrameBgHook then
        hooksecurefunc("DefaultCompactMiniFrameSetup", function(frame)
            if not frame or frame.bbfHealthBackground then return end
            local healthColor = BetterBlizzFramesDB.partyRaidFrameBackgroundHealthColor or {0, 0, 0, 1}
            local healthR, healthG, healthB, healthA = healthColor[1], healthColor[2], healthColor[3], healthColor[4]
            local bgTexture = BBF.LSM:Fetch(BBF.LSM.MediaType.STATUSBAR, BetterBlizzFramesDB.raidFrameBgTexture)
            local tex = frame:CreateTexture(nil, "BACKGROUND", nil, 0)
            frame.bbfHealthBackground = tex
            tex:SetPoint("TOPLEFT", frame.healthBar, "TOPLEFT", 0, 0)
            tex:SetPoint("BOTTOMRIGHT", frame.healthBar, "BOTTOMRIGHT", 0, 0)
            frame.bbfHealthBackground:SetTexture(bgTexture)
            frame.bbfHealthBackground:SetVertexColor(healthR, healthG, healthB, healthA)
        end)
        BBF.PetFrameBgHook = true
    end

    if not BBF.RaidFrameBgHook then
        hooksecurefunc("DefaultCompactUnitFrameSetup", function(frame)
            if not frame or not frame.healthBar or frame.bbfHealthBackground then return end

            local healthColor = BetterBlizzFramesDB.partyRaidFrameBackgroundHealthColor or {0, 0, 0, 1}
            local healthR, healthG, healthB, healthA = healthColor[1], healthColor[2], healthColor[3], healthColor[4]
            local manaColor = BetterBlizzFramesDB.partyRaidFrameBackgroundManaColor or {0, 0, 0, 1}
            local manaR, manaG, manaB, manaA = manaColor[1], manaColor[2], manaColor[3], manaColor[4]
            local bgTexture = BBF.LSM:Fetch(BBF.LSM.MediaType.STATUSBAR, BetterBlizzFramesDB.raidFrameBgTexture)

            if frame.background then
                frame.background:SetDrawLayer("BACKGROUND", -1)
            end

            local tex = frame:CreateTexture(nil, "BACKGROUND", nil, 0)
            frame.bbfHealthBackground = tex
            tex:SetPoint("TOPLEFT", frame.healthBar, "TOPLEFT", 0, 0)
            tex:SetPoint("BOTTOMRIGHT", frame.healthBar, "BOTTOMRIGHT", 0, 0)
            tex:SetTexture(bgTexture)
            tex:SetVertexColor(healthR, healthG, healthB, healthA)

            if frame.powerBar then
                local manaTex = frame:CreateTexture(nil, "BACKGROUND", nil, 0)
                frame.bbfManaBackground = manaTex
                manaTex:SetPoint("TOPLEFT", frame.powerBar, "TOPLEFT", 0, 0)
                manaTex:SetPoint("BOTTOMRIGHT", frame.powerBar, "BOTTOMRIGHT", 0, 0)
                manaTex:SetTexture(bgTexture)
                manaTex:SetVertexColor(manaR, manaG, manaB, manaA)
            end
        end)
        BBF.RaidFrameBgHook = true
    end
end