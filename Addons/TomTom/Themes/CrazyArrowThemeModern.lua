--[[--------------------------------------------------------------------------
--  TomTom by Cladhaire <cladhaire@gmail.com>
--
--  All Rights Reserved
----------------------------------------------------------------------------]]

local addonName, addon = ...

-- Simple localization table for messages
local L = TomTomLocals

local IMAGE_ARROW = "Interface\\Addons\\TomTom\\Images\\Modern\\ArrowNavColour"
local IMAGE_ARROW_UP = "Interface\\AddOns\\TomTom\\Images\\Modern\\ArrowArrivalColour"

local theme = {
    elapsed = 0,
    arrival_throttle = 0.016,
    navigation_throttle = 0.016,
}

-- Arguments for GetSpriteRotateTexCoordsResolver and GetSpriteAnimationTexCoordsResolver
local navSpriteConfig = {2304, 3072, 256, 256, 9, 12, nil, 0, 0}
local arrivalSpriteConfig = {2304, 3072, 256, 256, 9, 12, (9 * 12)}

function theme:ApplyTheme(button)
    button:SetHeight(80)
    button:SetWidth(80)

    if not theme.arrowTexture then
        theme.arrowTexture = button:CreateTexture("TomTomCrazyArrowModernArrow", "OVERLAY")
    end

    theme.arrowTexture:SetTexture(IMAGE_ARROW)
    theme.arrowTexture:ClearAllPoints()
    theme.arrowTexture:SetPoint("TOPLEFT", 0, 0)
    theme.arrowTexture:SetPoint("BOTTOMRIGHT", 0, -10)
    theme.arrowTexture:Show()

    -- Set up coord resolvers
    if not self.navCoordResolver then
        self.navCoordResolver = addon:GetSpriteRotateTexCoordsResolver(unpack(navSpriteConfig))
    end

    if not self.arrivalCoordResolver then
        self.arrivalCoordResolver = addon:GetSpriteAnimationTexCoordsResolver(unpack(arrivalSpriteConfig))
    end
end

function theme:RemoveTheme(button)
    theme.arrowTexture:ClearAllPoints()
    theme.arrowTexture:Hide()
end

function theme:SwitchToArrivalArrow(button)
    local arrow = theme.arrowTexture
    arrow:SetTexture(IMAGE_ARROW_UP)
end

local frame = 0
local elapsedTime = 0
function theme:ArrivalArrow_OnUpdate(elapsed)
    elapsedTime  = elapsedTime + elapsed
    if elapsedTime < theme.arrival_throttle then
        return
    end
    elapsedTime = 0

    local iterations = math.floor(elapsedTime / theme.arrival_throttle)
    if iterations <= 0 then
        iterations = 1
    end

    -- Advance the animation frame
    frame = frame + iterations

    local arrow = theme.arrowTexture
    local left, right, top, bottom, clampedFrame = self.arrivalCoordResolver(frame)
    arrow:SetTexCoord(left, right, top, bottom)
    frame = clampedFrame
end

function theme:SwitchToNavigationArrow(button)
    local arrow = theme.arrowTexture
    arrow:SetTexture(IMAGE_ARROW)
end

function theme:NavigationArrow_OnUpdate(elapsed, angle)
    elapsedTime  = elapsedTime + elapsed
    if elapsedTime < theme.arrival_throttle then
        return
    end
    elapsedTime = 0

    local arrow = theme.arrowTexture
    local left, right, top, bottom = self.navCoordResolver(angle)
    arrow:SetTexCoord(left, right, top, bottom)
end

addon.CrazyArrowThemeHandler:RegisterCrazyArrowTheme("modern", L["Modern theme"], theme)
