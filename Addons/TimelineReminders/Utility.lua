local _, LRP = ...

local LCG = LibStub("LibCustomGlow-1.0")
local LS = LibStub("LibSpecialization")

local playerName = UnitName("player")
local liquidNickname = playerName
local auraUpdaterNickname = playerName
local playerClass, playerGroup, playerRole, playerPosition, playerSpecIndex

local bytetoB64 = {
    [0]="a","b","c","d","e","f","g","h",
    "i","j","k","l","m","n","o","p",
    "q","r","s","t","u","v","w","x",
    "y","z","A","B","C","D","E","F",
    "G","H","I","J","K","L","M","N",
    "O","P","Q","R","S","T","U","V",
    "W","X","Y","Z","0","1","2","3",
    "4","5","6","7","8","9","(",")"
}

-- For use in config dropdowns and reminder tooltips
LRP.coloredClasses = {}
LRP.classIcons = {}
LRP.classFileToClassID = {}

for classID = 1, GetNumClasses() do
    local className, classFile = GetClassInfo(classID)
    local colorStr = RAID_CLASS_COLORS[classFile].colorStr

    LRP.coloredClasses[classFile] = string.format("|c%s%s|r", colorStr, className)
    LRP.classFileToClassID[classFile] = classID

    -- For some reason the regular class icon file is missing for cata
    if LRP.isCata and classFile == "DEATHKNIGHT" then
        LRP.classIcons[classFile] = "interface\\icons\\spell_deathknight_classicon.blp"
    else
        LRP.classIcons[classFile] = string.format("interface\\icons\\classicon_%s.blp", classFile:lower())
    end
end

-- Generates a unique random 11 digit number in base64
-- Taken from WeakAuras
function LRP:GenerateUniqueID()
    local s = {}

    for _ = 1, 11 do
        tinsert(s, bytetoB64[math.random(0, 63)])
    end

    return table.concat(s)
end

-- Rounds a value, optionally to a certain number of decimals
function LRP:Round(value, decimals)
    if not decimals then decimals = 0 end
    
    local p = math.pow(10, decimals)
    
    value = value * p
    value = Round(value)
    value = value / p
    
    return value
end

-- Same as the game's SecondsToClock, except adds a single decimal to the seconds
function LRP:SecondsToClock(seconds, displayZeroHours)
	local units = ConvertSecondsToUnits(seconds)

	if units.hours > 0 or displayZeroHours then
		return format("%.2d:%.2d:%04.1f", units.hours, units.minutes, units.seconds + units.milliseconds)
	else
		return format("%.2d:%04.1f", units.minutes, units.seconds + units.milliseconds)
	end
end

-- Takes a creature GUID and returns its npc ID
function LRP:NpcID(GUID)
    if not GUID then return end
    
    local npcID = select(6, strsplit("-", GUID))

    return tonumber(npcID)
end

-- Iterates group units
-- Usage: <for unit in LRP:IterateGroupMembers() do>
-- Taken from WeakAuras
function LRP:IterateGroupMembers(reversed, forceParty)
    local unit = (not forceParty and IsInRaid()) and "raid" or "party"
    local numGroupMembers = unit == "party" and GetNumSubgroupMembers() or GetNumGroupMembers()
    local i = reversed and numGroupMembers or (unit == "party" and 0 or 1)

    return function()
        local ret

        if i == 0 and unit == "party" then
            ret = "player"
        elseif i <= numGroupMembers and i > 0 then
            ret = unit .. i
        end

        i = i + (reversed and -1 or 1)

        return ret
    end
end

-- Adds a tooltip to a frame
-- Can be called repeatedly to change the tooltip
function LRP:AddTooltip(frame, tooltipText, secondaryTooltipText) 
    if not tooltipText then tooltipText = "" end

    frame.secondaryTooltipText = secondaryTooltipText -- Used for stuff like warnings/additional info that shouldn't change the main tooltip text

    -- If this frame already has a tooltip applied to it, simply change the tooltip text
    if frame.tooltipText then
        frame.tooltipText = tooltipText
    else
        frame.tooltipText = tooltipText

        -- The tooltip should be handled in a hook, in case the OnEnter/OnLeave script changes later on
        -- If there is no OnEnter/OnLeave script present, add an empty one
        if not frame:HasScript("OnEnter") then
            frame:SetScript("OnEnter", function() end)
        end

        if not frame:HasScript("OnLeave") then
            frame:SetScript("OnLeave", function() end)
        end

        frame:HookScript(
            "OnEnter",
            function()
                if not frame.tooltipText or frame.tooltipText == "" then return end
                
                LRP.Tooltip:Hide()
                LRP.Tooltip:SetOwner(frame, "ANCHOR_RIGHT")

                if frame.secondaryTooltipText and frame.secondaryTooltipText ~= "" then
                    LRP.Tooltip:SetText(string.format("%s|n|n%s", frame.tooltipText, frame.secondaryTooltipText), 0.9, 0.9, 0.9, 1, true)
                else
                    LRP.Tooltip:SetText(frame.tooltipText, 0.9, 0.9, 0.9, 1, true)
                end

                LRP.Tooltip:Show()
            end
        )

        frame:HookScript(
            "OnLeave",
            function()
                LRP.Tooltip:Hide()
            end
        )
    end
end

-- Refreshes the tooltip that is currently showing
-- Useful mainly for when editbox vlaues in reminder config are changed, and tooltip warnings are added/hidden as a result
function LRP:RefreshTooltip()
    if LRP.Tooltip:IsVisible() then
        local frame = LRP.Tooltip:GetOwner()

        if frame and frame.tooltipText then
            if frame.secondaryTooltipText and frame.secondaryTooltipText ~= "" then
                LRP.Tooltip:SetText(string.format("%s|n|n%s", frame.tooltipText, frame.secondaryTooltipText), 0.9, 0.9, 0.9, 1, true)
            else
                LRP.Tooltip:SetText(frame.tooltipText, 0.9, 0.9, 0.9, 1, true)
            end
        end
    end
end

-- Takes an icon ID and returns an in-line icon string
function LRP:IconString(icon)
    if icon then
        if C_Texture.GetAtlasInfo(icon) then
            return CreateAtlasMarkup(icon)
        else
            return CreateTextureMarkup(icon, 64, 64, 0, 0, 5/64, 59/64, 5/64, 59/64)
        end
    end
end

-- Caches player info like class, spec, raid group, etc.
-- This is used to compare against the [load] part of reminders, to determine if they are relevant for us
local function UpdatePlayerInfo()
    playerClass = UnitClassBase("player")
    playerSpecIndex = LRP.isRetail and GetSpecialization() or GetPrimaryTalentTree and GetPrimaryTalentTree()
    liquidNickname = LiquidAPI and LiquidAPI:GetName("player") or playerName
    auraUpdaterNickname = AuraUpdater and AuraUpdater.GetNickname and AuraUpdater:GetNickname("player")

    local _, role, position = LS:MySpecialization()

    if role and position then
        playerRole = role
        playerPosition = position
    end

    playerGroup = (UnitInRaid("player") and GetRaidRosterInfo(UnitInRaid("player")) or 1)
end

-- Evaluates if a reminder should show for the current player character (based on name, class, spec, role)
function LRP:IsRelevantReminder(reminderData)
    if not playerClass then UpdatePlayerInfo() end
    
    local reminderType = reminderData.load.type

    if reminderType == "ALL" then
        return true
    end

    if reminderType == "NAME" then
        return reminderData.load.name == playerName or reminderData.load.name == liquidNickname or reminderData.load.name == auraUpdaterNickname
    end

    if reminderType == "ROLE" then
        return reminderData.load.role == playerRole
    end

    if reminderType == "POSITION" then
        return reminderData.load.position == playerPosition
    end

    if reminderType == "CLASS_SPEC" then
        if playerClass == reminderData.load.class then
            local specIndex = reminderData.load.spec

            -- Class reminder (specIndex is set to class base name)
            if specIndex == reminderData.load.class  then
                return true
            end

            -- Spec reminder
            if specIndex == playerSpecIndex then
                return true
            end
        end
    end

    if reminderType == "GROUP" then
        return reminderData.load.group == playerGroup
    end

    return false
end

function LRP:GetCurrentTimelineInfo()
    local instanceType = LiquidRemindersSaved.settings.timeline.selectedInstanceType
    local instance = LiquidRemindersSaved.settings.timeline.selectedInstance
    local encounter = LiquidRemindersSaved.settings.timeline.selectedEncounter
    local difficulty = LiquidRemindersSaved.settings.timeline.selectedDifficulty
    local timelineData = LRP.timelineData[instanceType][instance].encounters[encounter][difficulty]
    local encounterInfo = LRP.timelineData[instanceType][instance].encounters[encounter]
    local encounterID = encounterInfo.id
    local profile = LiquidRemindersSaved.settings.timeline.selectedProfiles[encounterID][difficulty]
    local reminders = LiquidRemindersSaved.reminders[encounterID][difficulty][profile]

    return {
        timelineData = timelineData,
        reminders = reminders,
        instanceType = instanceType,
        encounterInfo = encounterInfo,
        encounterID = encounterID,
        profile = profile,
        difficulty = difficulty
    }
end

-- Save the size/position of a frame in SavedVariables, keyed by some name
function LRP:SaveSize(frame, name)
    if not LiquidRemindersSaved.settings.frames[name] then
        LiquidRemindersSaved.settings.frames[name] = {}
    end

    local width, height = frame:GetSize()

    LiquidRemindersSaved.settings.frames[name].width = width
    LiquidRemindersSaved.settings.frames[name].height = height
end

function LRP:SavePosition(frame, name)
    if not LiquidRemindersSaved.settings.frames[name] then
        LiquidRemindersSaved.settings.frames[name] = {}
    end

    LiquidRemindersSaved.settings.frames[name].points = {}

    local numPoints = frame:GetNumPoints()

    for i = 1, numPoints do
        local point, relativeTo, relativePoint, offsetX, offsetY = frame:GetPoint(i)

        if relativeTo == nil or relativeTo == UIParent then -- Only consider points relative to UIParent
            table.insert(
                LiquidRemindersSaved.settings.frames[name].points,
                {
                    point = point,
                    relativePoint = relativePoint,
                    offsetX = offsetX,
                    offsetY = offsetY
                }
            )
        end
    end
end

-- Restore and apply saved size/position to a frame, keyed by some name
function LRP:RestoreSize(frame, name)
    local settings = LiquidRemindersSaved.settings.frames[name]

    if not settings then return end
    if not settings.width then return end
    if not settings.height then return end

    frame:SetSize(settings.width, settings.height)
end

function LRP:RestorePosition(frame, name)
    local points = name and LiquidRemindersSaved.settings.frames[name] and LiquidRemindersSaved.settings.frames[name].points

    if not points then return end

    for _, pointInfo in ipairs(points) do
        frame:SetPoint(pointInfo.point, UIParent, pointInfo.relativePoint, pointInfo.offsetX, pointInfo.offsetY)
    end
end

-- Adds a 1 pixel border to a frame
function LRP:AddBorder(parent, thickness, horizontalOffset, verticalOffset)
    if not thickness then thickness = 1 end
    if not horizontalOffset then horizontalOffset = 0 end
    if not verticalOffset then verticalOffset = 0 end
    
    parent.border = {
        top = parent:CreateTexture(nil, "OVERLAY"),
        bottom = parent:CreateTexture(nil, "OVERLAY"),
        left = parent:CreateTexture(nil, "OVERLAY"),
        right = parent:CreateTexture(nil, "OVERLAY"),
    }

    parent.border.top:SetHeight(thickness)
    parent.border.top:SetPoint("TOPLEFT", parent, "TOPLEFT", -horizontalOffset, verticalOffset)
    parent.border.top:SetPoint("TOPRIGHT", parent, "TOPRIGHT", horizontalOffset, verticalOffset)
    parent.border.top:SetSnapToPixelGrid(false)
    parent.border.top:SetTexelSnappingBias(0)

    parent.border.bottom:SetHeight(thickness)
    parent.border.bottom:SetPoint("BOTTOMLEFT", parent, "BOTTOMLEFT", -horizontalOffset, -verticalOffset)
    parent.border.bottom:SetPoint("BOTTOMRIGHT", parent, "BOTTOMRIGHT", horizontalOffset, -verticalOffset)
    parent.border.bottom:SetSnapToPixelGrid(false)
    parent.border.bottom:SetTexelSnappingBias(0)

    parent.border.left:SetWidth(thickness)
    parent.border.left:SetPoint("TOPLEFT", parent, "TOPLEFT", -horizontalOffset, verticalOffset)
    parent.border.left:SetPoint("BOTTOMLEFT", parent, "BOTTOMLEFT", -horizontalOffset, -verticalOffset)
    parent.border.left:SetSnapToPixelGrid(false)
    parent.border.left:SetTexelSnappingBias(0)

    parent.border.right:SetWidth(thickness)
    parent.border.right:SetPoint("TOPRIGHT", parent, "TOPRIGHT", horizontalOffset, verticalOffset)
    parent.border.right:SetPoint("BOTTOMRIGHT", parent, "BOTTOMRIGHT", horizontalOffset, -verticalOffset)
    parent.border.right:SetSnapToPixelGrid(false)
    parent.border.right:SetTexelSnappingBias(0)

    function parent:SetBorderColor(r, g, b)
        for _, tex in pairs(parent.border) do
            tex:SetColorTexture(r, g, b)
        end
    end

    function parent:ShowBorder()
        for _, tex in pairs(parent.border) do
            tex:Show()
        end
    end

    function parent:HideBorder()
        for _, tex in pairs(parent.border) do
            tex:Hide()
        end
    end

    function parent:SetBorderShown(shown)
        if shown then
            parent:ShowBorder()
        else
            parent:HideBorder()
        end
    end

    parent:SetBorderColor(0, 0, 0)
end

-- Adds a highlight to a frame, displayed when the cursor hovers over it
-- If an alt frame is provided, the highlight will show on the alt frame when the cursor is hovered over the main frame
function LRP:AddHoverHighlight(frame, altFrame, width, r, g, b, a)
    if not altFrame then altFrame = frame end

    if not frame.highlight then
        frame.highlight = {
            top = frame:CreateTexture(nil, "HIGHLIGHT"),
            left = frame:CreateTexture(nil, "HIGHLIGHT"),
            bottom = frame:CreateTexture(nil, "HIGHLIGHT"),
            right = frame:CreateTexture(nil, "HIGHLIGHT")
        }
        
        frame.highlight.top:SetPoint("TOPLEFT", altFrame, "TOPLEFT", 1, -1)
        frame.highlight.top:SetPoint("TOPRIGHT", altFrame, "TOPRIGHT", -1, -1)
        frame.highlight.top:SetHeight(width or 1)

        frame.highlight.bottom:SetPoint("BOTTOMLEFT", altFrame, "BOTTOMLEFT", 1, 1)
        frame.highlight.bottom:SetPoint("BOTTOMRIGHT", altFrame, "BOTTOMRIGHT", -1, 1)
        frame.highlight.bottom:SetHeight(width or 1)

        frame.highlight.left:SetPoint("TOPLEFT", frame.highlight.top, "BOTTOMLEFT")
        frame.highlight.left:SetPoint("BOTTOMLEFT", frame.highlight.bottom, "TOPLEFT")
        frame.highlight.left:SetWidth(width or 1)

        frame.highlight.right:SetPoint("TOPRIGHT", frame.highlight.top, "BOTTOMRIGHT")
        frame.highlight.right:SetPoint("BOTTOMRIGHT", frame.highlight.bottom, "TOPRIGHT")
        frame.highlight.right:SetWidth(width or 1)
    end

    for _, tex in pairs(frame.highlight) do
        tex:SetColorTexture(r or (56/255), g or (119/255), b or (245/255), a or 0.6)
    end
end

-- Glows a frame
function LRP:StartGlow(frame, id, glowType, glowColor)
    glowColor = {glowColor.r, glowColor.g, glowColor.b, 1}

    if glowType == "PIXEL" then
        LCG.PixelGlow_Start(frame, glowColor, nil, nil, nil, 4, nil, nil, nil, id)
    elseif glowType == "AUTOCAST" then
        LCG.AutoCastGlow_Start(frame, glowColor, 8, nil, 1, nil, nil, id)
    elseif glowType == "BUTTON" then
        LCG.ButtonGlow_Start(frame, glowColor)
    elseif glowType == "PROC" then
        LCG.ProcGlow_Start(frame, {color = glowColor, key = id})
    end
end

-- Removes glow from a frame
function LRP:StopGlow(frame, id, glowType)
    if glowType == "PIXEL" then
        LCG.PixelGlow_Stop(frame, id)
    elseif glowType == "AUTOCAST" then
        LCG.AutoCastGlow_Stop(frame, id)
    elseif glowType == "BUTTON" then
        LCG.ButtonGlow_Stop(frame, id)
    elseif glowType == "PROC" then
        LCG.ProcGlow_Stop(frame, id)
    end
end

function LRP:PlayCountdown(number, voice)
    local soundFile = string.format("Interface\\AddOns\\TimelineReminders\\Media\\TTS\\%s\\%s.mp3", voice, number)

    PlaySoundFile(soundFile, LiquidRemindersSaved.settings.soundChannel)
end

-- Verifies that reminder data is structured correctly
-- Used before importing a reminder
function LRP:VerifyReminderIntegrity(reminderData)
    return reminderData and type(reminderData) == "table" and reminderData.trigger
end

-- Returns the time that the reminder will show on the timeline
-- This is not necessarily the same as the actual time it will show in-fight, as it may be relative to an event that happens at a variable time
function LRP:GetReminderTimelineTime(timelineData, reminderData)
    local relativeTo = reminderData.trigger.relativeTo

    if not relativeTo then
        return reminderData.trigger.time
    end

    local event = relativeTo.event
    local value = relativeTo.value
    local count = relativeTo.count

    for _, eventInfo in ipairs(timelineData.events) do
        if event == eventInfo.event and value == eventInfo.value then
            return eventInfo.entries[count] and eventInfo.entries[count][1] + reminderData.trigger.time
        end
    end
end

local eventFrame = CreateFrame("Frame")

eventFrame:RegisterEvent("LOADING_SCREEN_DISABLED")
eventFrame:RegisterEvent("PLAYER_SPECIALIZATION_CHANGED")
eventFrame:RegisterEvent("GROUP_ROSTER_UPDATE")
eventFrame:SetScript("OnEvent", UpdatePlayerInfo)