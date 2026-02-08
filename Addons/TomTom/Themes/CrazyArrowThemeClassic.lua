--[[--------------------------------------------------------------------------
--  TomTom by Cladhaire <cladhaire@gmail.com>
--
--  All Rights Reserved
----------------------------------------------------------------------------]]

local addonName, addon = ...

-- Simple localization table for messages
local L = TomTomLocals

local IMAGE_ARROW = "Interface\\Addons\\TomTom\\Images\\Arrow-1024"
local IMAGE_ARROW_UP = "Interface\\AddOns\\TomTom\\Images\\Arrow-UP-1024"

local theme = {
    elapsed = 0,
    arrival_throttle = 0.016,
    navigation_throttle = 0.016,
}

local navSpriteConfig = {1024, 1024, 112, 84, 9, 12}
local arrivalSpriteConfig = {1024, 1024, 106, 140, 9, 6, (9 * 6)}

local elapsedTime = 0
local twopi = math.pi * 2

function theme:ApplyTheme(button)
    button:SetHeight(42)
    button:SetWidth(56)

    if not theme.arrowTexture then
        theme.arrowTexture = button:CreateTexture("TomTomCrazyArrowClassicArrow", "OVERLAY")
    end

    theme.arrowTexture:SetTexture(IMAGE_ARROW)
    theme.arrowTexture:ClearAllPoints()
    theme.arrowTexture:SetAllPoints()
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
    arrow:SetVertexColor(unpack(addon.db.profile.arrow.goodcolor))
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

    -- Advance the animation frame
    frame = frame + iterations
end

function theme:SwitchToNavigationArrow(button)
    local arrow = theme.arrowTexture
    arrow:SetHeight(56)
    arrow:SetWidth(42)
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

    -- Change the colour
    local perc = math.abs((math.pi - math.abs(angle)) / math.pi)

    local gr,gg,gb = unpack(addon.db.profile.arrow.goodcolor)
    local mr,mg,mb = unpack(addon.db.profile.arrow.middlecolor)
    local br,bg,bb = unpack(addon.db.profile.arrow.badcolor)
    local r,g,b = addon:ColorGradient(perc, br, bg, bb, mr, mg, mb, gr, gg, gb)

    -- If we're 98% heading in the right direction, then use the exact
    -- color instead of the gradient. This allows us to distinguish 'good'
    -- from 'on target'. Thanks to Gregor_Curse for the suggestion.
    if perc > 0.98 then
        r,g,b = unpack(addon.db.profile.arrow.exactcolor)
    end
    arrow:SetVertexColor(r,g,b)
end

addon.CrazyArrowThemeHandler:RegisterCrazyArrowTheme("classic", L["Classic theme"], theme)
