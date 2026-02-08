if sArenaMixin.isMidnight then return end

local isRetail = sArenaMixin.isRetail
local isTBC = sArenaMixin.isTBC
local noEarlyFrames = sArenaMixin.isTBC or sArenaMixin.isWrath
local GetSpellTexture = GetSpellTexture or C_Spell.GetSpellTexture
local auraList = sArenaMixin.auraList
local interruptList = sArenaMixin.interruptList
local tooltipInfoAuras = sArenaMixin.tooltipInfoAuras
local spellLockReducer = sArenaMixin.spellLockReducer
local stanceAuras = sArenaMixin.stanceAuras
local activeStanceAuras = sArenaMixin.activeStanceAuras

function sArenaFrameMixin:FindInterrupt(event, spellID, sourceName, sourceGUID)
    local interruptDuration = interruptList[spellID]
    local unit = self.unit
    local castBar = self.CastBar

    if event == "SPELL_CAST_SUCCESS" then
        local notInterruptable = select(7, UnitChannelInfo(unit))
        if notInterruptable ~= false then
            return
        end
    end

    if sourceName then
        local name, server = strsplit("-", sourceName)
        local colorStr = "ffFFFFFF"

        if C_PlayerInfo.GUIDIsPlayer(sourceGUID) then
            local _, englishClass = GetPlayerInfoByGUID(sourceGUID)
            if englishClass then
                colorStr = RAID_CLASS_COLORS[englishClass].colorStr
            end
        end

        local interruptedByName = string.format("|c%s[%s]|r", colorStr, name)
        castBar.interruptedBy = interruptedByName
        castBar.Text:SetText(interruptedByName)
        castBar:Show()
        C_Timer.After(1, function()
            castBar.interruptedBy = nil
        end)
    end

    for n = 1, 30 do
        local aura = C_UnitAuras.GetAuraDataByIndex(unit, n, "HELPFUL")
        if not aura then break end
        local mult = spellLockReducer[aura.spellId]
        if mult then
            interruptDuration = interruptDuration * mult
        end
    end
    self.currentInterruptSpellID = spellID
    self.currentInterruptDuration = interruptDuration
    self.currentInterruptExpirationTime = GetTime() + interruptDuration
    self.currentInterruptTexture = GetSpellTexture(spellID)
    self:FindAura()
    C_Timer.After(interruptDuration, function()
        self.currentInterruptSpellID = nil
        self.currentInterruptDuration = 0
        self.currentInterruptExpirationTime = 0
        self.currentInterruptTexture = nil
        self:FindAura()
    end)
end

local tooltipScanner = CreateFrame("GameTooltip", "sArenaTooltipScanner", nil, "GameTooltipTemplate")
tooltipScanner:SetOwner(WorldFrame, "ANCHOR_NONE")

local function AuraTooltipContains(unit, index, filter, search)
    tooltipScanner:ClearLines()
    tooltipScanner:SetUnitAura(unit, index, filter)

    local line
    for i = 1, tooltipScanner:NumLines() do
        line = _G["sArenaTooltipScannerTextLeft" .. i]
        if line then
            local text = line:GetText()
            if text and text:find(search, 1, true) then
                return true
            end
        end
    end

    return false
end

local function AuraTooltipExtractPercent(unit, index, filter)
    tooltipScanner:ClearLines()
    tooltipScanner:SetUnitAura(unit, index, filter)

    local line
    for i = 1, tooltipScanner:NumLines() do
        line = _G["sArenaTooltipScannerTextLeft" .. i]
        if line then
            local text = line:GetText()
            if text then
                local percent = text:match("(%d+%%)")
                if percent then
                    return percent
                end
            end
        end
    end

    return nil
end

function sArenaFrameMixin:FindAura()
    if (self.parent.db and self.parent.db.profile.disableAurasOnClassIcon) or sArenaMixin.isMidnight then
        self:UpdateClassIcon()
        return
    end
    local unit = self.unit
    local currentSpellID, currentDuration, currentExpirationTime, currentTexture, currentApplications
    local currentPriority, currentRemaining = 0, 0

    if self.currentInterruptSpellID then
        currentSpellID = self.currentInterruptSpellID
        currentDuration = self.currentInterruptDuration
        currentExpirationTime = self.currentInterruptExpirationTime
        currentTexture = self.currentInterruptTexture
        currentPriority = 5.9 -- Below Silence, need to clean list
        currentRemaining = currentExpirationTime - GetTime()
        currentApplications = nil
    end

    for i = 1, 2 do
        local filter = (i == 1 and "HELPFUL" or "HARMFUL")

        for n = 1, 30 do
            local aura = C_UnitAuras.GetAuraDataByIndex(unit, n, filter)
            if not aura then break end

            local spellID = aura.spellId
            local priority = auraList[spellID]

            -- TBC Spec Detection: Check if this buff indicates a spec
            if noEarlyFrames and i == 1 then -- Only check buffs (HELPFUL)
                self:CheckForSpecSpell(spellID)
            end

            if priority then

                local duration = aura.duration or 0
                local expirationTime = aura.expirationTime or 0
                local texture = aura.icon
                local applications = aura.applications or 0

                -- Mists of Pandaria unique checks
                if not isRetail then
                    -- Icebound Fortitude, Check if it's glyphed to be immune to CC
                    if spellID == 51271 then
                        if AuraTooltipContains(unit, n, filter, "70%%") then
                            priority = 7
                        end
                    end
                    -- Handle percentage-based auras
                    if tooltipInfoAuras[spellID] then
                        local percent = AuraTooltipExtractPercent(unit, n, filter)
                        if percent then
                            applications = percent
                        end
                    end
                end

                -- Check for manual override of duration
                if sArenaMixin.activeNonDurationAuras[spellID] then
                    local tracked = sArenaMixin.nonDurationAuras[spellID]
                    if tracked then
                        duration = tracked.duration
                        expirationTime = sArenaMixin.activeNonDurationAuras[spellID] + duration
                        texture = tracked.texture or texture
                    end
                end

                local remaining = expirationTime - GetTime()

                if (priority > currentPriority)
                    or (priority == currentPriority and remaining > currentRemaining)
                then
                    currentSpellID = spellID
                    currentDuration = duration
                    currentExpirationTime = expirationTime
                    currentTexture = texture
                    currentPriority = priority
                    currentRemaining = remaining
                    currentApplications = applications
                end
            end
        end
    end

    -- TBC: Stances don't have auras so track them by mimicking a permanent aura. Stances still activate in CLEU as auras as normal.
    if isTBC then
        local stanceSpellID = activeStanceAuras[unit]
        if stanceSpellID then
            local stancePriority = stanceAuras[stanceSpellID]
            if stancePriority and stancePriority >= currentPriority then
                currentSpellID = stanceSpellID
                currentDuration = 0
                currentExpirationTime = 0
                currentTexture = GetSpellTexture(stanceSpellID)
                currentPriority = stancePriority
                currentRemaining = 0
                currentApplications = nil
            end
        end
    end

    if currentSpellID then
        self.currentAuraSpellID = currentSpellID
        self.currentAuraStartTime = currentExpirationTime - currentDuration
        self.currentAuraDuration = currentDuration
        self.currentAuraTexture = currentTexture
        self.currentAuraApplications = currentApplications
    else
        self.currentAuraSpellID = nil
        self.currentAuraStartTime = 0
        self.currentAuraDuration = 0
        self.currentAuraTexture = nil
        self.currentAuraApplications = nil
    end

    self:UpdateAuraStacks()
    self:UpdateClassIcon()
end

function sArenaFrameMixin:UpdateAuraStacks()
    if not self.currentAuraApplications then
        self.AuraStacks:SetText("")
        return
    end

    -- Show percentage for percentage-based auras, stacks >= 2 for others
    if tooltipInfoAuras[self.currentAuraSpellID] then
        self.AuraStacks:SetText(self.currentAuraApplications)
        self.AuraStacks:SetScale(0.9)
    elseif self.currentAuraApplications >= 2 then
        self.AuraStacks:SetText(self.currentAuraApplications)
        self.AuraStacks:SetScale(1)
    else
        self.AuraStacks:SetText("")
    end
end
