---@type string, Namespace
local _, ns = ...

local crossTexture = "Interface\\TargetingFrame\\UI-RaidTargetingIcon_7"

---Represents an ability icon moving in the queue.
---It displays an icon texture and a cross texture if the cast ability was canceled.
---@class Icon
local Icon = {}
Icon.__index = Icon
ns.Icon = Icon

---@class IconParams
---@field parentFrame any
---@field unitType UnitType
---@field layoutType LayoutType
---@field onMouseEnter fun()
---@field onMouseLeave fun()

---@param params IconParams
function Icon:New(params)
    ---@class Icon
    local obj = setmetatable({}, Icon)
    obj.unitType = params.unitType
    obj.layoutType = params.layoutType
    obj.displayed = false
    obj.offset = 0
    obj.startTime = 0
    obj.spellId = 0
    obj.cancelTextureDisplayed = false

    obj.frame = CreateFrame("Button", nil, params.parentFrame)
    obj.frame:Hide()
    obj.frame:SetScript("OnEnter", function()
        obj:ShowTooltip()
        params.onMouseEnter()
    end)
    obj.frame:SetScript("OnLeave", function()
        params:onMouseLeave()
        GameTooltip_Hide()
    end)
    obj.frame:SetScript("OnClick", function() obj:AddToBlocklist() end)

    obj.texture = obj.frame:CreateTexture(nil, "BACKGROUND")
    obj.texture:SetAllPoints(obj.frame)

    obj.cancelTexture = obj.frame:CreateTexture(nil, "BORDER")
    obj.cancelTexture:SetAllPoints(obj.frame)
    obj.cancelTexture:SetTexture(crossTexture)
    obj.cancelTexture:SetAlpha(1)
    obj.cancelTexture:Hide()

    obj:Resize()

    ns.masqueHelper.addIcon(obj.frame, obj.texture)

    return obj
end

function Icon:Show()
    self.startTime = GetTime()
    self.displayed = true
    self.frame:Show()
    self.frame:SetAlpha(1)
end

function Icon:Hide()
    self.offset = 0
    self.displayed = false

    self.frame:Hide()
    self.frame:SetAlpha(0)

    self.cancelTextureDisplayed = false
    self.cancelTexture:Hide()
end

function Icon:Resize()
    local settings = ns.settings.activeProfile.layoutSettings[self.layoutType]
    self.frame:SetWidth(settings.iconSize)
    self.frame:SetHeight(settings.iconSize)
end

function Icon:Clear()
    self.offset = 0
    self.displayed = false
    self.cancelTextureDisplayed = false

    self.frame:SetAlpha(0)
    self.frame:ClearAllPoints()
    self.frame:Hide()

    self.cancelTexture:Hide()
end

function Icon:UpdatePosition()
    local direction = ns.settings.activeProfile.layoutSettings[self.layoutType].direction
    if direction == "Left" then
        self.frame:SetPoint("RIGHT", self.offset, 0)
    elseif direction == "Right" then
        self.frame:SetPoint("LEFT", -self.offset, 0)
    elseif direction == "Up" then
        self.frame:SetPoint("BOTTOM", 0, -self.offset)
    elseif direction == "Down" then
        self.frame:SetPoint("TOP", 0, self.offset)
    end
end

---@param from Icon
function Icon:Copy(from)
    self.offset = from.offset
    self.startTime = from.startTime

    self:UpdatePosition()
    self.texture:SetTexture(from.texture:GetTexture())

    self.displayed = from.displayed
    if self.displayed then
        self.frame:Show()
        self.frame:SetAlpha(1)
    else
        self.frame:Hide()
    end

    self.cancelTextureDisplayed = from.cancelTextureDisplayed
    if self.cancelTextureDisplayed then
        self.cancelTexture:Show()
    else
        self.cancelTexture:Hide()
    end
end

---@param id number
---@param texture string | number
function Icon:SetSpell(id, texture)
    self.offset = 0
    self.displayed = false
    self.spellId = id
    self.texture:SetTexture(texture)
    self.frame:SetAlpha(0)
    self.frame:Hide()
end

function Icon:ShowCancelTexture()
    self.cancelTexture:Show()
    self.cancelTextureDisplayed = true
end

function Icon:HideCancelTexture()
    self.cancelTexture:Hide()
    self.cancelTextureDisplayed = false
end

---@private
function Icon:ShowTooltip()
    if not ns.settings.activeProfile.tooltipEnabled then
        return
    end

    GameTooltip_SetDefaultAnchor(GameTooltip, self.frame)
    GameTooltip:SetSpellByID(self.spellId, false, false, true)
    GameTooltip:Show()
    if ns.settings.activeProfile.tooltipPrintSpellId then
        if self.spellId then
            local spellLink = ns.utils.getSpellLink(self.spellId)
            if spellLink then
                print(spellLink .. " ID: " .. self.spellId)
            else
                print("ID: " .. self.spellId)
            end
        end
    end
end

---@private
function Icon:AddToBlocklist()
    if ns.settings.activeProfile.iconClickAddsSpellToBlocklist and IsControlKeyDown() and IsAltKeyDown() then
        table.insert(ns.settings.activeProfile.blocklist, self.spellId)
        ns.settings:Save()
        ns.blocklistFrame.syncWithSettings()

        local spellLink = ns.utils.getSpellLink(self.spellId)
        if spellLink then
            print("[TrufiGCD]: " .. spellLink .. " spell with ID \"" .. self.spellId .. "\" added to the blocklist")
        else
            print("[TrufiGCD]: A spell with ID \"" .. self.spellId .. "\" added to the blocklist")
        end
    end
end
