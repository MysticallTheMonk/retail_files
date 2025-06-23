local _, NS = ...
local L = NS.L

local isTesting = false
local isAnchoring = false

local backdrop = {
    bgFile = "Interface\\Tooltips\\UI-Tooltip-Background",
    tile = false,
}

local SetCVar = _G.SetCVar or _G.C_CVar.SetCVar

local TestMode = CreateFrame("Frame")
TestMode.pool = CreateFramePool("Frame", nil, _G.BackdropTemplateMixin and "BackdropTemplate") -- just for testing purposes
NS.TestMode = TestMode

-- Thanks sArena
local function CalcPoint(frame)
    local parentX, parentY = frame:GetParent():GetCenter()
    local frameX, frameY = frame:GetCenter()
    if not frameX then return end

    parentX, parentY, frameX, frameY = parentX + 0.5, parentY + 0.5, frameX + 0.5, frameY + 0.5

    local scale = frame:GetScale()

    parentX, parentY = floor(parentX), floor(parentY)
    frameX, frameY = floor(frameX * scale), floor(frameY * scale)
    frameX, frameY = floor((parentX - frameX) * -1), floor((parentY - frameY) * -1)

    return frameX/scale, frameY/scale
end

local function GetUnitIndex(str)
    return tonumber(strmatch(str, "%d+")) or 1 -- 1 if target/focus
end

local function OnDragStop(self)
    if self.unit == "nameplate" then return end
    if self.unit == "player" and DIMINISH_NS.db.unitFrames.player.usePersonalNameplate then return end
    self:StopMovingOrSizing()

    -- frames loses relativity to parent and is instead relative to UIParent after dragging
    -- so we cant just use self:GetPoint() here
    local xOfs, yOfs = CalcPoint(self)
    local db = DIMINISH_NS.db.unitFrames[self.realUnit]

    if db.anchorUIParent then
        -- when anchoring to UIParent for partyX/arenaX each frame has their own position values
        local id = GetUnitIndex(self.unitID or self.unit)
        db.offsetsY[id] = yOfs
        db.offsetsX[id] = xOfs
        return
    end

    db.offsetY = yOfs
    db.offsetX = xOfs

    -- Fix nameplate anchor after dragging
    if self.realUnit == "nameplate" then
        self:ClearAllPoints()
        self:SetPoint("CENTER", self:GetParent(), xOfs, yOfs)
    end

    local isArena = strfind(self.unit, "arena")
    local isParty = strfind(self.unit, "party")

    -- Update position for all party/arena anchor frames (not icons) after dragging 1 of them
    if isArena or isParty then
        for frame in TestMode.pool:EnumerateActive() do
            if isArena and strfind(frame.unit, "arena") or isParty and strfind(frame.unit, "party") then
                frame:ClearAllPoints()
                frame:SetPoint("CENTER", frame:GetParent(), db.offsetX, db.offsetY)
            end
        end
    end
end

local function OnEnter(self)
    SetCursor("Interface\\CURSOR\\UI-Cursor-Move")
end

--[[local function PartyOnHide(self)
    if not TestMode:IsTestingOrAnchoring() then return end

    -- If you hit Escape or Cancel in InterfaceOptions instead of "Okay" button then for some reason
    -- blizzard auto hides the spawned PartyMember frames so hook them and prevent hiding when testing
    if not InCombatLockdown() and not self:IsForbidden() then
        if not GetCVarBool("useCompactPartyFrames") then -- user toggling cvar while testing would prevent hiding permanently
            self:Show()
        end
    end
end]]

function TestMode:IsTestingOrAnchoring()
    return isTesting or isAnchoring
end

function TestMode:IsTesting()
    return isTesting
end

function TestMode:IsAnchoring()
    return isAnchoring
end

function TestMode:ToggleArenaAndPartyFrames(state, forceHide)
    if isTesting or isAnchoring then return end
    if InCombatLockdown() then return end

    local settings = DIMINISH_NS.db.unitFrames

    if not DIMINISH_NS.IS_CLASSIC then
        if not C_AddOns.IsAddOnLoaded("Blizzard_ArenaUI") then
            C_AddOns.LoadAddOn("Blizzard_ArenaUI")
        end
    end

    local showFlag
    if state ~= nil then
        showFlag = state
    else
        if not DIMINISH_NS.IS_CLASSIC then
            if ArenaEnemyFrames then
                showFlag = not ArenaEnemyFrames:IsShown()
            end
        end
    end

    if not DIMINISH_NS.IS_CLASSIC then
        local isInArena = select(2, IsInInstance()) == "arena"
        if forceHide or settings.arena.enabled and not isInArena then
            if ArenaEnemyFrames then
                ArenaEnemyFrames:SetShown(showFlag)
            end

            if LibStub and LibStub("AceAddon-3.0", true) then
                local _, sArena = pcall(function() return LibStub("AceAddon-3.0"):GetAddon("sArena") end)
                if sArena and sArena.ArenaEnemyFrames then
                    -- (As of sArena 3.0.0 this is no longer needed, but we'll keep this for now
                    -- incase anyone is using the old version)
                    -- sArena anchors frames to sArena.ArenaEnemyFrames instead of _G.ArenaEnemyFrames
                    sArena.ArenaEnemyFrames:SetShown(showFlag)
                end
            end
        end
    end

    local useCompact = GetCVarBool("useCompactPartyFrames")
    if EditModeManagerFrame and EditModeManagerFrame.UseRaidStylePartyFrames then
        useCompact = EditModeManagerFrame:UseRaidStylePartyFrames()
    end
    if useCompact and settings.party.enabled and showFlag then
        if not IsInGroup() then
            print("Diminish: " .. L.COMPACTFRAMES_ERROR) -- luacheck: ignore
        end
    end

    if ElvUI then
        -- :Show doesn't seem to work for ElvUI so use ElvUI built in functions to toggle arena/party frames
        local E = unpack(ElvUI)
        local UF = E and E:GetModule("UnitFrames")
        if UF then
            if not DIMINISH_NS.IS_CLASSIC then
                if settings.arena.enabled then
                    UF:ToggleForceShowGroupFrames('arena', 5)
                end
            end
            if settings.party.enabled then
                UF:HeaderConfig(ElvUF_Party, ElvUF_Party.forceShow ~= true or nil)
            end
            return
        end
    elseif Tukui then
        local T = Tukui:unpack()
        local Test = T and T["TestUI"]
        if Test then
            return Test:EnableOrDisable()
        end
    end

    for i = 1, 5 do
        if not DIMINISH_NS.IS_CLASSIC then
            if select(2, IsInInstance()) ~= "arena" then
                local frame = DIMINISH_NS.Icons:GetAnchor("arena"..i, true, true)
                if frame and frame ~= UIParent then
                    if frame:IsVisible() or settings.arena.enabled then
                        frame:SetShown(showFlag)
                    end
                end
            end
        end

        -- EditModeManagerFrame:EnterEditMode()
        if forceHide or not useCompact and settings.party.enabled then
            --[[if EditModeManagerFrame and EditModeManagerFrame.AccountSettings then
                EditModeManagerFrame.AccountSettings:SetPartyFramesShown(showFlag)
                EditModeManagerFrame.AccountSettings:RefreshPartyFrames()
            end]]
           -- TODO: idk how to get party frame testing to work in Dragonflight without tainting the whole UI, and dont got time to research it
                -- so gotta use existing player party members for now.
            if i == 1 then
                print("Diminish: You'll need to test party frames while in a group.") -- luacheck: ignore
            end
        end
    end
end

function TestMode:HideAnchors()
    isAnchoring = false
    self.pool:ReleaseAll()
    if not TestMode:IsTestingOrAnchoring() then
        self:UnregisterEvent("PLAYER_TARGET_CHANGED")
    end
    self:ToggleArenaAndPartyFrames(false)
    if EditModeManagerFrame and EditModeManagerFrame.AccountSettings then -- Dragonflight...
        HideUIPanel(EditModeManagerFrame)
    end
end

local function OnMouseDown(self)
    if self.unit == "nameplate" or (self.unit == "player" and DIMINISH_NS.db.unitFrames.player.usePersonalNameplate) then
        return print("Please use the position sliders in Diminish_Options to set nameplate position. WoW patch 8.3.0 broke the drag to move functionaliy for nameplates.") -- luacheck: ignore
    end

    self:StartMoving()
end

function TestMode:CreateDummyAnchor(parent, unit, unitID)
    if not parent then return end

    local db = DIMINISH_NS.db.unitFrames[unit]
    if not db or not db.enabled then return end

    local isCompact = strfind(parent:GetName() or "", "Compact")
    if isCompact and not parent:IsShown() then return end

    local frame, isNew = self.pool:Acquire()
    frame:SetParent(parent)
    frame:ClearAllPoints()
    frame.realUnit = unit

    if unit == "player" and isCompact then
        unit = "player-party"
    end

    frame.unit = unit
    frame.unitID = unitID

    if isNew then
        frame.tooltip = frame:CreateFontString(nil, "ARTWORK", "GameFontNormal")
        frame.tooltip:SetPoint("TOP", frame, 0, 10)

        frame:SetClampedToScreen(true)
        frame:SetScript("OnMouseDown", OnMouseDown)
        frame:SetScript("OnMouseUp", OnDragStop)
        frame:EnableMouse(true)
        frame:SetMovable(true)
        frame:SetFrameLevel(9999)
        frame:SetBackdrop(backdrop)
        frame:SetBackdropColor(1, 0, 0, 1)
        frame:SetFrameStrata("HIGH")

        frame:SetScript("OnEnter", OnEnter)
        frame:SetScript("OnLeave", ResetCursor)
    end

    frame.tooltip:SetFormattedText(L.ANCHORDRAG, strupper(unitID or unit), db.growDirection)
    frame:SetSize(db.iconSize, db.iconSize)
    if not db.anchorUIParent then
        frame:SetPoint("CENTER", parent, db.offsetX, db.offsetY)
    else
        local id = GetUnitIndex(unitID or unit)
        frame:SetPoint("CENTER", parent, db.offsetsX[id], db.offsetsY[id])
    end
    frame:Show()

    isAnchoring = true
end

--[[local function ReanchorForNameplate()
    local anchor = C_NamePlate.GetNamePlateForUnit("target")
    if not anchor then return end

    for frame in TestMode.pool:EnumerateActive() do
        if frame.unit == "nameplate" then
            local db = DIMINISH_NS.db.unitFrames["nameplate"]
            frame:ClearAllPoints()
            frame:SetParent(anchor)
            frame:SetPoint("CENTER", anchor, db.offsetX, db.offsetY)
            frame:Show()
            return
        end
    end

        -- if we got here then dummy anchor hasn't been created yet
    TestMode:CreateDummyAnchor(anchor, "nameplate")
end]]

local function OnTargetChanged(self, event)
    -- Delay function call because GetNamePlateForUnit() is not
    -- ready immediately after PLAYER_TARGET_CHANGED is triggered
    --[[if TestMode:IsAnchoring() then
        C_Timer.After(0.2, ReanchorForNameplate)
    end]]

    if event == "PLAYER_LOGOUT" then
        if TestMode.personalNameplateCfg ~= nil then
            SetCVar("NameplatePersonalShowAlways", TestMode.personalNameplateCfg)
        end
    else
        if TestMode:IsTesting() and UnitExists("target") then
            DIMINISH_NS.Timers:Refresh("nameplate")
        end
    end
end
TestMode:RegisterEvent("PLAYER_LOGOUT")
TestMode:SetScript("OnEvent", OnTargetChanged)

function TestMode:ShowAnchors()
    TestMode:ToggleArenaAndPartyFrames(true)

    for _, unitID in pairs(NS.unitFrames) do
        if unitID == "arena" then
            if not DIMINISH_NS.IS_CLASSIC then
                for i = 1, 5 do
                    local anchor = DIMINISH_NS.Icons:GetAnchor(unitID..i, true)
                    TestMode:CreateDummyAnchor(anchor, unitID, unitID..i)
                end
            end
        elseif unitID == "party" then
            for i = 0, 4 do
                local unit = i == 0 and "player-party" or "party"..i
                local anchor = DIMINISH_NS.Icons:GetAnchor(unit, DIMINISH_NS.db.unitFrames.party.anchorUIParent)
                TestMode:CreateDummyAnchor(anchor, unitID, unit)
            end
        --[[elseif unitID == "nameplate" then
            local anchor = C_NamePlate.GetNamePlateForUnit("target")
            isAnchoring = true
            TestMode:CreateDummyAnchor(anchor, unitID)
            self:RegisterEvent("PLAYER_TARGET_CHANGED")]]
        else
            local anchor = DIMINISH_NS.Icons:GetAnchor(unitID)
            TestMode:CreateDummyAnchor(anchor, unitID)
        end
    end

    if EditModeManagerFrame and EditModeManagerFrame.AccountSettings then
        ShowUIPanel(EditModeManagerFrame)
    end
end

function TestMode:Test(hide)
    if InCombatLockdown() then
        return print(L.COMBATLOCKDOWN_ERROR) -- luacheck: ignore
    end

    if isTesting or hide then
        isTesting = false
        TestMode:ToggleArenaAndPartyFrames(false, hide)
        DIMINISH_NS.Timers:ResetAll()
        if not TestMode:IsTestingOrAnchoring() then
            self:UnregisterEvent("PLAYER_TARGET_CHANGED")
        end

        if self.personalNameplateCfg ~= nil then
            SetCVar("NameplatePersonalShowAlways", self.personalNameplateCfg)
            self.personalNameplateCfg = nil
        end
        if EditModeManagerFrame and EditModeManagerFrame.AccountSettings then -- Dragonflight...
            HideUIPanel(EditModeManagerFrame)
        end
        return
    end

    TestMode:ToggleArenaAndPartyFrames(true)
    isTesting = true
    self:RegisterEvent("PLAYER_TARGET_CHANGED")

    if DIMINISH_NS.db.unitFrames.player.enabled and DIMINISH_NS.db.unitFrames.player.usePersonalNameplate then
        self.personalNameplateCfg = self.personalNameplateCfg or GetCVar("NameplatePersonalShowAlways")
        SetCVar("NameplatePersonalShowAlways", 1)
        C_Timer.After(0.15, function()
            DIMINISH_NS.Timers:Refresh("player")
        end)
    end

    if EditModeManagerFrame and EditModeManagerFrame.AccountSettings then -- Dragonflight...
        ShowUIPanel(EditModeManagerFrame)
    end

    local DNS = DIMINISH_NS
    DNS.Timers:ResetAll()
    DNS.Timers:Insert(UnitGUID("player"), nil, DNS.CATEGORIES.stun, 853, false, false, true, true)
    DNS.Timers:Insert(UnitGUID("player"), nil, DNS.CATEGORIES.root, 122, false, false, true, true)
    DNS.Timers:Insert(UnitGUID("player"), nil, DNS.CATEGORIES.incapacitate, 118, false, false, true, true)
end
