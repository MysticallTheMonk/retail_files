local _, NS = ...
local Icons = {}
local frames = {}
NS.Icons = Icons
NS.iconFrames = frames

local pool = CreateFramePool("CheckButton", nil, _G.BackdropTemplateMixin and "BackdropTemplate") -- CheckButton to support Masque

local _G = _G
local pairs = _G.pairs
local UnitGUID = _G.UnitGUID
local GetTime = _G.GetTime
local gsub = _G.string.gsub
local format = _G.string.format
local strmatch = _G.string.match
local GetNamePlateForUnit = _G.C_NamePlate.GetNamePlateForUnit

local STANDARD_TEXT_FONT = _G.STANDARD_TEXT_FONT

local anchorCache = {}

function Icons:GetAnchor(unitID, defaultAnchor, noUIParent)
    if unitID == "player" and NS.db.unitFrames.player.usePersonalNameplate then
        return GetNamePlateForUnit("player")
    end

    local unit, count = gsub(unitID, "%d", "") -- party1 -> party

    -- HACK: anchorCache[] wont work 100% for party/raid frames due to event race conditions,
    -- cba rewriting everything at this point so this'll have to do for now
    if (unit == "party" or unit == "player-party") and not defaultAnchor then
        if unit == "player-party" then
            unitID = "player"
        end

        if not NS.db.unitFrames.party.anchorUIParent then
            if NS.useCompactPartyFrames or IsInRaid(LE_PARTY_CATEGORY_HOME) then
                return Icons:FindCompactRaidFrameByUnit(unitID) or Icons:FindPartyFrameByUnit(unitID)
            else
                return Icons:FindPartyFrameByUnit(unitID)
            end
        else
            return UIParent
        end
    end

    if anchorCache[unitID] and not defaultAnchor then
        return anchorCache[unitID]
    end

    if unit == "nameplate" then
        if unitID == "nameplate" then -- is testmode
            unitID = "target"
        end

        local f = GetNamePlateForUnit(unitID)
        if f then
            local threatPlates = f.TPFrame
            if threatPlates and threatPlates.Active then
                return threatPlates
            end
        end
        return f
    end

    local anchors = NS.anchors[unit]
    if not anchors then return end

    for i = 1, #anchors do
        local name = anchors[i]

        if count > 0 then
            name = format(name, strmatch(unitID, "%d+")) -- add unit index to frame name
        end

        local frame
        if not noUIParent and NS.db.unitFrames[unit].anchorUIParent then
            frame = UIParent
        else
            frame = _G[name]
        end

        if frame then
            if unit ~= "party" and unit ~= "player-party" and not defaultAnchor then
                anchorCache[unitID] = frame
            end

            return frame
        end
    end
end

function Icons:FindCompactRaidFrameByUnit(unitID)
    local guid = UnitGUID(unitID)
    if not guid then return end

    for i = 1, 40 do
        -- TODO: local frame = Icons:GetAnchor("raid"..i, true)
        local frame = _G["CompactRaidFrame"..i] -- check this frame first

        -- CompactRaidFrameManager_GetSetting("KeepGroupsTogether")
        if not frame or (frame and not frame:IsVisible()) then
            frame = _G["CompactPartyFrameMember"..i] -- check this instead if first frame has no unit attached
        end

        if not frame or (frame and not frame:IsVisible()) then
            frame = _G["CompactRaidGroup1Member"..i]
        end

        if frame and frame.unit and UnitGUID(frame.unit) == guid then
            return frame
        end
    end
end

-- For blizzard frames, party1 is always equal to PartyFrame1 and so on
-- but for unitframe addons party1 might be frame3 or some other random frame index
-- so always just scan through them all, just like with the raid frames
-- Edit: For Dragonflight this is no longer true.
function Icons:FindPartyFrameByUnit(unitID)
    local guid = UnitGUID(unitID)
    if not guid then return end

    for i = 1, 5 do
        local frame = Icons:GetAnchor("party"..i, true)
        --if not frame then return end

        if frame and frame.unit and frame:IsVisible() and UnitGUID(frame.unit) == guid then
            return frame
        end
    end

    if PartyFrame and PartyFrame.PartyMemberFramePool then
        for f in PartyFrame.PartyMemberFramePool:EnumerateActive() do
            if f.layoutIndex and f:IsVisible() and UnitGUID("party" .. f.layoutIndex) == guid then
                return f
            end
        end
    end
end

function Icons:AnchorPartyFrames(members)
    local cfg = NS.db.unitFrames.party
    if not cfg.enabled then return end

    for i = 0, (members or 4) do
        local unit = i == 0 and "player" or "party"..i
        local parent

        if not cfg.anchorUIParent then
            if NS.useCompactPartyFrames or IsInRaid(LE_PARTY_CATEGORY_HOME) then
                parent = Icons:FindCompactRaidFrameByUnit(unit) or Icons:FindPartyFrameByUnit(unit)
            else
                parent = Icons:FindPartyFrameByUnit(unit)
            end
        else
            parent = UIParent
        end

        if unit == "player" then
            -- we need to difference "player" for PlayerFrame and
            -- "player" for CompactRaidFrame
            unit = "player-party"
        end

        --anchorCache[unit] = parent or nil

        if parent then
            if frames[unit] then
                -- Anchor existing DR icons to new parent
                -- if parent:IsForbidden() then return end
                for category, frame in pairs(frames[unit]) do
                    frame:ClearAllPoints()
                    frame:SetParent(parent)
                end
            end
        end
    end
end

do
    local CreateFrame = _G.CreateFrame

    local function MasqueAddFrame(frame)
        frame:SetNormalTexture(NS.db.border.edgeFile)

        NS.MasqueGroup:AddButton(frame, {
            Icon = frame.icon,
            Cooldown = frame.cooldown,
            Normal = frame:GetNormalTexture(),
            Border = frame.border,
        })
    end

    local function GetOffsets(cfg)
        local ofsX, ofsY = 0, 0
        local direction = cfg.growDirection
        if direction == "LEFT" then
            ofsX = -cfg.iconSize - cfg.iconPadding
        elseif direction == "RIGHT" then
            ofsX = cfg.iconSize + cfg.iconPadding
        elseif direction == "TOP" then
            ofsY = cfg.iconSize + cfg.iconPadding
        elseif direction == "BOTTOM" then
            ofsY = -cfg.iconSize - cfg.iconPadding
        end

        return ofsX, ofsY
    end

    function Icons:UpdatePositions(cooldownFrame)
        local anchor = cooldownFrame.parent
        if not frames[anchor.unit] then return end

        local cfg = anchor.unitSettingsRef
        local ofsX, ofsY = GetOffsets(cfg)

        local first = true
        local firstOfsX = cfg.offsetX
        local firstOfsY = cfg.offsetY

        if cfg.anchorUIParent then
            anchor.uid = anchor.uid or tonumber(strmatch(anchor.unit, "%d+")) or 1 -- 1 if not arena/party
            firstOfsY = cfg.offsetsY[anchor.uid] -- array index 2 = arena2/party2 pos etc
            firstOfsX = cfg.offsetsX[anchor.uid]
        end

        for _, frame in pairs(frames[anchor.unit]) do
            if anchor.unit ~= frame.unit then
                -- TODO: check if still needed
                frames[frame.unit] = nil
            else
                if frame.shown then
                    if first then
                        frame:SetPoint("CENTER", anchor:GetParent(), firstOfsX, firstOfsY)
                        first = false
                    else
                        frame:SetPoint("CENTER", anchor, ofsX, ofsY)
                    end

                    anchor = frame
                end
            end
        end
    end

    local function CooldownOnShow(self)
        local frame = self.parent
        local timer = frame.timerRef

        if timer and GetTime() >= (timer.expiration or 0) then
            return NS.Timers:Remove(timer.unitGUID, timer.category)
        end

        -- Seems to be an extremely rare occassion that the frame itself is not shown
        -- but the cooldown frame is. No idea why, so always force show here
        if not frame:IsVisible() then
            frame.shown = true
            frame:Show()
        end

        Icons:UpdatePositions(self)
    end

    local function CooldownOnHide(self)
        local frame = self.parent
        local timer = frame.timerRef

        if timer and self:GetCooldownDuration() <= 0.2 then
            if frame.unitFormatted and C_VoiceChat and C_VoiceChat.SpeakText then
                if DIMINISH_NS.db.announceDRs and not timer.isNotPetOrPlayer then -- FYI: experimental/test at the moment
                    local text = format("%s %s expired.", UnitName(frame.unitFormatted) or "", timer.category)
                    C_VoiceChat.SpeakText(0, text, Enum.VoiceTtsDestination.QueuedLocalPlayback, 3, 100)
                end
            end

            NS.Timers:Remove(timer.unitGUID, timer.category)
        end

        if frame:IsVisible() then
            frame.shown = false
            frame:Hide()
        end

        Icons:UpdatePositions(self)
    end

    function Icons:CreateUIParentOffsets(db, unit)
        if not db.offsetsY or not db.offsetsX then
            -- When anchoring to UIParent we need to setup new offsets for every frame belonging to this unitID
            if unit == "arena" or unit == "party" then
                db.offsetsY = { db.offsetY, db.offsetY, db.offsetY, db.offsetY, db.offsetY }
                db.offsetsX = { 0, 0, 0, 0, 0 }
            else
                db.offsetsY = { db.offsetY }
                db.offsetsX = { 0 }
            end
        end
    end

    local iconCount = 0
    local function CreateIcon(unitID, category)
        local anchor = Icons:GetAnchor(unitID)
        if not anchor then return end

        local origUnitID
        if unitID == "player-party" then
            unitID = "party" -- use for party db settings below
            origUnitID = "player-party"
        end

        local db = NS.db

        local frame, isNew = pool:Acquire()
        frame:ClearAllPoints()
        frame.unit = origUnitID or unitID
        frame.unitFormatted = gsub(unitID, "%d", "")
        frame.unitSettingsRef = db.unitFrames[frame.unitFormatted]
        frame.uid = nil

        local unitDB = frame.unitSettingsRef

        -- Need to always update these for pooled frames
        if unitDB.anchorUIParent then
            Icons:CreateUIParentOffsets(unitDB, frame.unitFormatted)
            anchorCache[frame.unitFormatted] = UIParent
            frame:SetParent(UIParent)
        else
            if anchorCache[frame.unitFormatted] == UIParent then
                anchorCache[frame.unitFormatted] = nil
            end
            frame:SetParent(anchor)
        end

        local size = unitDB.iconSize
        frame:SetSize(size, size)

        if frame.countdown then
            local name, height, flags = frame.countdown:GetFont()
            if flags ~= db.timerTextOutline or height ~= unitDB.timerTextSize then
                frame.countdown:SetFont(name, unitDB.timerTextSize, db.timerTextOutline)
            end
        end

        if isNew then
            --[==[@debug@
            NS.Debug("Created new frame for %s:%s", unitID, category)
            --@end-debug@]==]

            iconCount = iconCount + 1
            frame:SetFrameStrata("HIGH")
            frame:SetFrameLevel(11)
            frame:EnableMouse(false)
            frame:Hide()

            frame.icon = frame:CreateTexture(nil, "ARTWORK")
            frame.icon:SetAllPoints(frame)
            frame.icon:SetDrawLayer("ARTWORK", 7)

            -- We don't really need a frame name here, but add it to support some addons
            local cooldown = CreateFrame("Cooldown", "DiminishIcon" .. iconCount, frame, "CooldownFrameTemplate")
            cooldown:SetAllPoints(frame)
            cooldown:SetHideCountdownNumbers(not db.timerText)
            cooldown:SetDrawSwipe(db.timerSwipe)
            cooldown:SetDrawEdge(db.timerEdge)
            cooldown:SetDrawBling(false)
            cooldown:SetSwipeColor(0, 0, 0, 0.65)
            cooldown:SetScript("OnShow", CooldownOnShow)
            cooldown:SetScript("OnHide", CooldownOnHide)
            cooldown.parent = frame -- avoids calling :GetParent() later on
            frame.cooldown = cooldown

            local indicatorBorder = cooldown:CreateTexture(nil, "OVERLAY")
            indicatorBorder:SetTexture("Interface\\TalentFrame\\TalentFrame-RankBorder")
            indicatorBorder:SetSize(26, 26)
            indicatorBorder:SetPoint("CENTER", frame, "BOTTOMRIGHT", 0, 0)
            frame.indicatorBg = indicatorBorder

            frame.indicatorText = cooldown:CreateFontString(nil, "OVERLAY")
            frame.indicatorText:SetFont(STANDARD_TEXT_FONT, 9)
            frame.indicatorText:SetPoint("CENTER", indicatorBorder, 0, 0)

            frame.countdown = cooldown:GetRegions()
            frame.countdown:SetFont(frame.countdown:GetFont(), unitDB.timerTextSize, db.timerTextOutline)

            local borderWidth = db.border.edgeSize
            local border = frame:CreateTexture(nil, db.border.layer or "BORDER")
            border:SetPoint("TOPLEFT", -borderWidth, borderWidth)
            border:SetPoint("BOTTOMRIGHT", borderWidth, -borderWidth)
            border:SetTexture(db.border.edgeFile)
            frame.border = border

            -- label above an icon that displays category text
            local ctext = frame:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
            ctext:SetFont(db.categoryFont.font or ctext:GetFont(), db.categoryFont.size, db.categoryFont.flags)
            --ctext:SetPoint("BOTTOMLEFT", db.categoryFont.x, size + 2)
            ctext:SetShown(db.showCategoryText)
            ctext:SetJustifyH("CENTER")
            ctext:SetNonSpaceWrap(true)
            ctext:SetWidth(unitDB.iconSize + 11)
            frame.categoryText = ctext
            frame.categoryTextSize = db.categoryFont.size

            frame.icon:SetTexCoord(0.08, 0.92, 0.08, 0.92)

            if NS.MasqueGroup then
                MasqueAddFrame(frame)
            end
        end

        if NS.MasqueGroup and not isNew then
            frame:SetNormalTexture(NS.db.border.edgeFile)
            NS.MasqueGroup:ReSkin(frame)
        end

        if not db.colorBlind then
            frame.indicatorBg:Hide()
            frame.indicatorText:Hide()
        end

        if frame.categoryText then
            frame.categoryText:SetMaxLines(db.categoryTextMaxLines or 2)
            frame.categoryText:SetText(category)
            frame.categoryText:SetPoint("BOTTOM", db.categoryFont.x, size + 2)
        end

        return frame
    end

    function Icons:GetFrame(unitID, category)
        if not unitID or not category then return end

        if frames[unitID] and frames[unitID][category] then
            return frames[unitID][category]
        end

        if not frames[unitID] then
            frames[unitID] = {}
        end

        local frame = CreateIcon(unitID, category)
        frames[unitID][category] = frame

        return frame
    end

    local function RefreshIcon(frame, db)
        frame.cooldown:SetHideCountdownNumbers(not db.timerText)
        frame.cooldown:SetDrawSwipe(db.timerSwipe)
        frame.cooldown:SetDrawEdge(db.timerEdge)
        frame.categoryText:SetShown(db.showCategoryText)

        if not NS.MasqueGroup then
            frame.border:SetDrawLayer(db.border.layer or "BORDER")
            frame.border:SetTexture(db.border.edgeFile)
            frame.border:SetPoint("TOPLEFT", -db.border.edgeSize, db.border.edgeSize)
            frame.border:SetPoint("BOTTOMRIGHT", db.border.edgeSize, -db.border.edgeSize)
        else
            frame:SetNormalTexture(NS.db.border.edgeFile)
            NS.MasqueGroup:ReSkin(frame)
        end

        frame.cooldown.noCooldownCount = db.timerColors or not db.timerText -- toggle OmniCC
        if db.timerText and not db.timerColors then
            frame.countdown:SetTextColor(1, 1, 1, 1)
        end

        frame.indicatorBg:SetShown(db.colorBlind)
        frame.indicatorText:SetShown(db.colorBlind)
    end

    -- Refresh everything for icons. Called by Diminish_Options.
    -- Function is deleted if Diminish_Options is not enabled.
    function Icons:OnFrameConfigChanged()
        local db = NS.db

        -- Enumerate inactive frames
        for _, frame in pool:EnumerateInactive() do
            RefreshIcon(frame, db)
        end

        -- Enumerate active frames or frames that aren't pooled
        for _, tbl in pairs(frames) do
            for _, frame in pairs(tbl) do
                RefreshIcon(frame, db)

                if frame.categoryTextSize and frame.categoryTextSize ~= db.categoryFont.size then
                    frame.categoryText:SetFont(db.categoryFont.font or frame.categoryText:GetFont(), db.categoryFont.size, db.categoryFont.flags)
                    frame.categoryText:SetShown(db.showCategoryText)
                    frame.categoryTextSize = db.categoryFont.size
                end

                -- Refresh settings that require unit ID
                frame.unitSettingsRef = db.unitFrames[frame.unitFormatted] -- need to update pointer if changed profile
                local size = frame.unitSettingsRef.iconSize
                frame:SetSize(size, size)

                if frame.categoryText then
                    frame.categoryText:SetPoint("BOTTOM", db.categoryFont.x, size + 2)
                    frame.categoryText:SetWidth(size + 11)
                    frame.categoryText:SetMaxLines(db.categoryTextMaxLines)
                    --frame.categoryText:SetHeight(db.categoryFont.size * 2)
                end

                local name, height, flags = frame.countdown:GetFont()
                if flags ~= db.timerTextOutline or height ~= frame.unitSettingsRef.timerTextSize then
                    frame.countdown:SetFont(name, frame.unitSettingsRef.timerTextSize, db.timerTextOutline)
                end

                if frame.unitSettingsRef.anchorUIParent then
                    Icons:CreateUIParentOffsets(frame.unitSettingsRef, frame.unitFormatted)
                    anchorCache[frame.unitFormatted] = UIParent
                    frame:ClearAllPoints()
                    frame:SetParent(UIParent)
                else
                    anchorCache[frame.unitFormatted] = nil -- HACK: grab new cache on next anchor call
                    frame:ClearAllPoints()
                    local anchor = Icons:GetAnchor(frame.unit, true, true)
                    if anchor then
                        frame:SetParent(anchor)
                    end
                end

                Icons:UpdatePositions(frame.cooldown)
            end
        end

        if NS.MasqueGroup then
            NS.MasqueGroup:ReSkin()
        end
    end
end

function Icons:ReleaseNameplate(unitID)
    NS.Timers:RemoveActiveGUID(unitID)
    if frames[unitID] then
        for category, frame in pairs(frames[unitID]) do
            Icons:ReleaseFrame(frame, unitID, nil, category)
        end
        --[==[@debug@
        NS.Debug("Released nameplate %s", unitID)
        --@end-debug@]==]
    end
end

function Icons:HideAll()
    for unitID, tbl in pairs(frames) do
        for category, frame in pairs(tbl) do
            if not Icons:ReleaseFrame(frame, unitID, nil, category) then
                frame.shown = false
                frame:Hide()
            end
        end
    end
end

function Icons:ReleaseFrame(frame, unitID, timer, category)
    if frame.unitFormatted == "nameplate" or frame.unitFormatted == "party" or (frame.unitFormatted == "arena" and NS.Diminish.currInstanceType ~= "arena") then
        frame.shown = false
        frame.timerRef = nil
        Icons:UpdatePositions(frame.cooldown)

        if frames[unitID] then
            if timer and timer.category or category then
                -- remove cache ref to frame
                frames[unitID][category or timer.category] = nil
            else
                -- if we ever got here then timer was cleared before frames for some reason
                -- so just delete everything..
                wipe(frames[unitID])
            end

            if not next(frames[unitID]) then
                frames[unitID] = nil
            end
        end

        pool:Release(frame) -- will also trigger Hide + ClearAllPoints

        return true
    end
end

do
    local GetSpellTexture = function(...)
        if _G.GetSpellTexture then
            return _G.GetSpellTexture(...)
        elseif C_Spell and C_Spell.GetSpellTexture then
            return C_Spell.GetSpellTexture(...)
        end
    end
    local CATEGORY_TAUNT = NS.CATEGORIES.taunt
    local indicatorColors = NS.DR_STATES_COLORS
    local DR_TIME = NS.DR_TIME

    local function GetIndicatorColor(applied, category)
        if category ~= CATEGORY_TAUNT then
            return indicatorColors[applied]
        else
            -- Taunts aren't immune until fifth applied
            return applied <= 4 and indicatorColors[1] or indicatorColors[3]
        end
    end

    local function SetIndicators(frame, applied, category)
        local color = GetIndicatorColor(applied, category)
        if not color then return end

        if NS.db.timerText and NS.db.timerColors then
            frame.countdown:SetTextColor(color[1], color[2], color[3], 1)
        end

        if Icons.MSQGroup then
            frame.__MSQ_NormalTexture:SetVertexColor(color[1], color[2], color[3], 1)
            frame.border:SetVertexColor(frame.border.__MSQ_Color)
        else
            frame.border:SetVertexColor(color[1], color[2], color[3], 1)
        end

        if NS.db.colorBlind then
            frame.indicatorText:SetTextColor(color[1], color[2], color[3], 1)
            frame.indicatorText:SetText(applied)
        end
    end

    local function SetSpellTexture(frame, timer)
        if NS.db.categoryTextures[timer.category] then
            -- Icon has been sat manually in Diminish_Options
            return frame.icon:SetTexture(NS.db.categoryTextures[timer.category])
        end

        frame.icon:SetTexture(GetSpellTexture(timer.spellID))
    end

    function Icons:StartCooldown(timer, unitID, onAuraEnd)
        local frame = self:GetFrame(unitID, timer.category)
        if not frame then return end

        if unitID == "player-party" then
            if not DIMINISH_NS.useCompactPartyFrames then return end
        end

        if unitID == "player" then
            if NS.db.unitFrames.player.usePersonalNameplate then
                local personalResourceDisplay = GetNamePlateForUnit("player")
                if not personalResourceDisplay then return end -- skip starting cd until nameplate is shown
                if frame:GetParent() ~= personalResourceDisplay then
                    frame:ClearAllPoints()
                    frame:SetParent(personalResourceDisplay)
                end
            end
        end

        if unitID == "nameplate" then
            -- HACK: reanchor test nameplate frames to new target's nameplate
            local parent = GetNamePlateForUnit("target")
            if parent then
                local threatPlates = parent.TPFrame
                if threatPlates and threatPlates.Active then
                    frame:ClearAllPoints()
                    frame:SetParent(threatPlates)
                else
                    frame:ClearAllPoints()
                    frame:SetParent(parent)
                end
            end
        end

        local now = GetTime()
        local expiration = timer.expiration - now
        frame.timerRef = timer

        SetSpellTexture(frame, timer)
        SetIndicators(frame, timer.applied, timer.category)

        if frame.shown then
            if timer.testMode then return end

            if not onAuraEnd or NS.db.timerStartAuraEnd then
                -- frame.cooldown:SetCooldownDuration(expiration)
                frame.cooldown:SetCooldown(now, expiration)
            else
                -- Refresh cooldown without resetting timer swipe (only on aura broke/end for mode timerStartAuraEnd=false)
                -- Thanks to sArena for this
                local startTime, startDuration = frame.cooldown:GetCooldownTimes()
                startTime, startDuration = startTime/1000, startDuration/1000

                local drTime = --[[timer.isNotPetOrPlayer and 20 or]] DR_TIME
                local newDuration = drTime / (1 - ((now - startTime) / startDuration))
                local newStartTime = drTime + now - newDuration
                frame.cooldown:SetCooldown(newStartTime, newDuration)
            end
        else
            frame.shown = true
            frame.cooldown:SetCooldown(now, expiration)
            frame:Show()
        end
    end

    function Icons:StopCooldown(timer, unitID, isFinished)
        local frame = frames[unitID] and frames[unitID][timer.category]
        if not frame then return end

        if isFinished and frame.timerRef then
            frame.timerRef = nil
        end

        if not Icons:ReleaseFrame(frame, unitID, timer) then
            frame.shown = false
            frame:Hide()
        end
    end
end
