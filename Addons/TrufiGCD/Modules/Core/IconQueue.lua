---@type string, Namespace
local _, ns = ...

local globalCooldown = 1.6
local fastSpeedModifier = 3

local iconHidingDuration = 2
local iconHidingDelay = 3

local innerIconsNumber = 10

---Represents a queue of moving ability icons. 
---@class IconQueue
local IconQueue = {}
IconQueue.__index = IconQueue
ns.IconQueue = IconQueue

---@class IconQueueParams
---@field unitType UnitType
---@field layoutType LayoutType

---@param params IconQueueParams
function IconQueue:New(params)
    local unitSettings = ns.settings.activeProfile.unitSettings[params.unitType]

    ---@class IconQueue
    local obj = setmetatable({}, IconQueue)

    obj.unitType = params.unitType
    obj.layoutType = params.layoutType

    ---@type number[]
    obj.nextIconIndices = {}

    ---Buffer between the last shown icon and the start of the frame.
    ---Used to place a next icon if it's big enough.
    obj.buffer = 0

    obj.iconIndex = 1
    obj.isMoving = true

    obj.frame = CreateFrame("Frame", nil, UIParent)

    obj.texture = obj.frame:CreateTexture(nil, "BACKGROUND")
    obj.texture:SetAllPoints(obj.frame)
    obj.texture:SetColorTexture(0, 0, 0)
    obj.texture:SetAlpha(0.6)
    obj.texture:Hide()

    obj.text = obj.frame:CreateFontString(nil, "BACKGROUND")
    obj.text:SetFont(STANDARD_TEXT_FONT, 9)
    obj.text:SetText(unitSettings.text)
    obj.text:SetAllPoints(obj.frame)
    obj.text:SetAlpha(0.6)
    obj.text:Hide()

    obj.frame:RegisterForDrag("LeftButton")
    obj.frame:SetScript("OnDragStart", obj.frame.StartMoving)
    obj.frame:SetScript("OnDragStop", obj.frame.StopMovingOrSizing)
    obj.frame:SetPoint(unitSettings.point, unitSettings.x, unitSettings.y)

    ---@type {[number]: Icon}
    obj.icons = {}
    for i = 1, innerIconsNumber do
        obj.icons[i] = ns.Icon:New({
            parentFrame = obj.frame,
            unitType = obj.unitType,
            layoutType = obj.layoutType,
            onMouseEnter = function()
                if ns.settings.activeProfile.tooltipEnabled and ns.settings.activeProfile.tooltipStopScroll then
                    obj.isMoving = false
                end
            end,
            onMouseLeave = function()
                obj.isMoving = true
            end
        })
    end

    obj:Resize()

    return obj
end

---@param id number
---@param texture string | number
function IconQueue:AddSpell(id, texture)
    if self.iconIndex == innerIconsNumber then
        self.iconIndex = 1
    end

    self.icons[self.iconIndex]:SetSpell(id, texture)
    table.insert(self.nextIconIndices, self.iconIndex)
    self.iconIndex = self.iconIndex + 1
end

---@param from IconQueue
function IconQueue:Copy(from)
    for i = 1, innerIconsNumber do
        self.icons[i]:Copy(from.icons[i])
    end

    self.buffer = from.buffer
    self.iconIndex = from.iconIndex

    self.nextIconIndices = {}
    for i, x in ipairs(from.nextIconIndices) do
        self.nextIconIndices[i] = x
    end
end

---Updates the icons every frame
---@param time number
---@param interval number
---@param isCasting boolean
function IconQueue:Update(time, interval, isCasting)
    if not self.isMoving then
        return
    end

    local layout = ns.settings.activeProfile.layoutSettings[self.layoutType]

    if #self.nextIconIndices > 0 and self.buffer >= layout.iconSize then
        self:ShowNextIcon()
        self.buffer = 0
    end

    local normalSpeed = layout.iconSize / globalCooldown
    local fastSpeed = normalSpeed * fastSpeedModifier * (#self.nextIconIndices + 1)
    local fastSpeedDuration = 0.0

    if #self.nextIconIndices > 0 then
        fastSpeedDuration = math.min((layout.iconSize - self.buffer) / fastSpeed, interval)
    end

    local width = layout.iconsNumber * layout.iconSize
    local offsetDelta = fastSpeedDuration * fastSpeed
    if not isCasting then
        offsetDelta = offsetDelta + (interval - fastSpeedDuration) * normalSpeed
    end

    for _, icon in ipairs(self.icons) do
        if icon.displayed then
            if ns.settings.activeProfile.iconsScroll or fastSpeedDuration > 0 then
                icon.offset = icon.offset - offsetDelta
            end

            icon:UpdatePosition()

            if not ns.settings.activeProfile.iconsScroll then
                local elapsedTime = time - icon.startTime

                if elapsedTime > iconHidingDuration + iconHidingDelay then
                    icon:Hide()
                elseif elapsedTime > iconHidingDelay then
                    local alpha = 1 - (elapsedTime - iconHidingDelay) / iconHidingDuration
                    icon.frame:SetAlpha(alpha)
                end
            end

            local absoluteOffset = math.abs(icon.offset)
            if absoluteOffset > width then
                local alpha = 1 - (absoluteOffset - width) / 10

                if alpha < 0 then
                    icon:Hide()
                elseif ns.settings.activeProfile.iconsScroll then
                    icon.frame:SetAlpha(alpha)
                end
            end
        end
    end

    if ns.settings.activeProfile.iconsScroll or fastSpeedDuration > 0 then
        self.buffer = self.buffer + offsetDelta
    end
end

function IconQueue:ShowCancel()
    local previousIconIndex = self.iconIndex - 1
    if previousIconIndex == 0 then
        previousIconIndex = innerIconsNumber
    end

    self.icons[previousIconIndex]:ShowCancelTexture()

    return previousIconIndex
end

---@param index number
function IconQueue:HideCancel(index)
    -- TODO: if change target between fake cancel and hide cancel, new hide cancel not done
    if self.icons[index] then
        self.icons[index]:HideCancelTexture()
    end
end

---@private
function IconQueue:ShowNextIcon()
    local nextIconIndex = table.remove(self.nextIconIndices, 1)
    self.icons[nextIconIndex]:Show()
end

function IconQueue:Clear()
    for _, icon in ipairs(self.icons) do
        icon:Clear()
    end

    self.iconIndex = 1
    self.nextIconIndices = {}
end

function IconQueue:Resize()
    local layout = ns.settings.activeProfile.layoutSettings[self.layoutType]
    if layout.direction == "Left" or layout.direction == "Right" then
        self.frame:SetWidth(layout.iconsNumber * layout.iconSize)
        self.frame:SetHeight(layout.iconSize)
    elseif layout.direction == "Up" or layout.direction == "Down" then
        self.frame:SetWidth(layout.iconSize)
        self.frame:SetHeight(layout.iconsNumber * layout.iconSize)
    end

    for _, icon in ipairs(self.icons) do
        icon:Resize()
    end

    ns.masqueHelper.reskinIcons()
end

function IconQueue:UpdateOffset()
    local unitSettings = ns.settings.activeProfile.unitSettings[self.unitType]
    self.frame:ClearAllPoints()
    self.frame:SetPoint(unitSettings.point, unitSettings.x, unitSettings.y)
end

function IconQueue:ShowAnchor()
    self.frame:SetMovable(true)
    self.frame:EnableMouse(true)

    self.texture:Show()
    self.text:Show()
end

function IconQueue:HideAnchor()
    self.frame:SetMovable(false)
    self.frame:EnableMouse(false)

    self.texture:Hide()
    self.text:Hide()
end
