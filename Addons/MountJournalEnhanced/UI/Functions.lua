local _, ADDON = ...

ADDON.UI = {}

--region frame point handling

local savedPoints = {}

---SavePoint
---@param frame table
---@param savePoint string|nil TOP|BOTTOM|.. or nil. nil saves all current points
function ADDON.UI:SavePoint(frame, savePoint)

    if not savedPoints[frame] or not savePoint then
        savedPoints[frame] = {}
    end

    for i = 1, frame:GetNumPoints() do
        local point, relativeTo, relativePoint, xOfs, yOfs = frame:GetPoint(i)
        if point == savePoint then
            savedPoints[frame][point] = { point, relativeTo, relativePoint, xOfs, yOfs }
            break
        end
        if not savePoint then
            savedPoints[frame][point] = { point, relativeTo, relativePoint, xOfs, yOfs }
        end
    end
end

---RestorePoint
---@param frame table
---@param savePoint string|nil TOP|BOTTOM|.. or nil. nil resores all saved points
function ADDON.UI:RestorePoint(frame, savePoint)
    if savePoint and savedPoints[frame] and savedPoints[frame][savePoint] then
        frame:SetPoint(unpack(savedPoints[frame][savePoint]))
    elseif not savePoint and savedPoints[frame] then
        frame:ClearAllPoints()
        for _, v in pairs(savedPoints[frame]) do
            frame:SetPoint(unpack(v))
        end
    end
end

--endregion

--region frame size handling

local savedSize = {}

function ADDON.UI:SaveSize(frame)
    local w, h = frame:GetSize()
    savedSize[frame] = { w, h }
end

function ADDON.UI:RestoreSize(frame)
    if savedSize[frame] then
        frame:SetSize(savedSize[frame][1], savedSize[frame][2])
        return savedSize[frame][1], savedSize[frame][2]
    end
end

--endregion

function ADDON.UI:CenterDropdownButton(elementData)
    elementData:AddInitializer(function(button)
        button.fontString:ClearAllPoints()
        button.fontString:SetPoint("CENTER")
    end)
end

--region ElvUI hooks

local callbacks = {}
function ADDON.UI:RegisterUIOverhaulCallback(func)
    table.insert(callbacks, func)
end

local function hookStripTextures()
    local frame = CreateFrame('Frame')
    if frame.StripTextures then
        local mt = getmetatable(frame).__index
        local org_Strip = mt.StripTextures
        mt.StripTextures = function(self, ...)
            if _G['MountJournal'] then
                for _, callback in pairs(callbacks) do
                    callback(self)
                end
            end
            return org_Strip(self, ...)
        end
    end
end
ADDON.Events:RegisterCallback("OnLogin", hookStripTextures, "ElvUI hooks")

-- force initial update for ElvUI
-- since ElvUI is loaded before MJE and it doesn't update its panels during registration. :(
local function refreshInitialDataTexts()
    if ElvUI then
        local E  = unpack(ElvUI)
        local DT = E:GetModule('DataTexts')
        DT:LoadDataTexts()
    end
end
ADDON.Events:RegisterCallback("AfterLogin", refreshInitialDataTexts, "ElvUI DataTexts")

--endregion

function ADDON.UI.OpenContextMenu(owner, anchor, generator, ...)
    local elementDescription = MenuUtil.CreateRootMenuDescription(MenuVariants.GetDefaultContextMenuMixin());

    Menu.PopulateDescription(generator, owner, elementDescription, ...);

    local menu = Menu.GetManager():OpenMenu(owner, elementDescription, anchor);
    if menu then
        PlaySound(SOUNDKIT.IG_MAINMENU_OPTION_CHECKBOX_ON);
    end
end

-- polyfill to use a regular frame as an tooltip
-- https://warcraft.wiki.gg/wiki/API_GameTooltip_SetOwner
function ADDON.UI:SetOwner(owner, anchor, ofsX, ofsY)
    ofsX = ofsX or 0
    ofsY = ofsY or 0
    self:ClearAllPoints()
    self:SetParent(owner)
    if anchor == "ANCHOR_TOP" then
        self:SetPoint("BOTTOM", owner, "TOP", ofsX, ofsY)
    elseif anchor == "ANCHOR_RIGHT" then
        self:SetPoint("BOTTOMLEFT", owner, "TOPRIGHT", ofsX, ofsY)
    elseif anchor == "ANCHOR_BOTTOM" then
        self:SetPoint("TOP", owner, "BOTTOM", ofsX, ofsY)
    elseif anchor == "ANCHOR_LEFT" then
        self:SetPoint("BOTTOMRIGHT", owner, "TOPLEFT", ofsX, ofsY)
    elseif anchor == "ANCHOR_TOPRIGHT" then
        self:SetPoint("BOTTOMRIGHT", owner, "TOPRIGHT", ofsX, ofsY)
    elseif anchor == "ANCHOR_BOTTOMRIGHT" then
        self:SetPoint("TOPLEFT", owner, "BOTTOMRIGHT", ofsX, ofsY)
    elseif anchor == "ANCHOR_TOPLEFT" then
        self:SetPoint("BOTTOMLEFT", owner, "TOPLEFT", ofsX, ofsY)
    elseif anchor == "ANCHOR_BOTTOMLEFT" then
        self:SetPoint("TOPRIGHT", owner, "BOTTOMLEFT", ofsX, ofsY)
    end
end
