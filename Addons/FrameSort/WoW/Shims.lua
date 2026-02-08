-- luacheck: ignore 113
---@diagnostic disable: undefined-global
---@type string, Addon
local _, addon = ...
local wow = addon.WoW.Api

-- shims for older clients
local version = GetBuildInfo and GetBuildInfo()
local nextFrameId = 1
local isWotlkPrivate = version == "3.3.5"

local function FrameShims(frame)
    -- classic
    if not frame.Text and frame.text then
        frame.Text = frame.text
    end

    -- wotlk private
    if not frame.Text then
        local name = frame.GetName and frame:GetName()
        local textFrame = name and _G[name .. "Text"]

        if textFrame then
            frame.Text = {
                SetFontObject = function(_, fontName)
                    return textFrame:SetFontObject(fontName)
                end,
                SetText = function(_, text)
                    textFrame:SetText(text)
                end,
            }
        end

        local originalCreateFontString = frame.CreateFontString
        frame.CreateFontString = function(...)
            local fontString = originalCreateFontString(...)
            FrameShims(fontString)
            return fontString
        end
    end

    -- wotlk private
    frame.SetShown = frame.SetShown or function(self, show)
        if show then
            self:Show()
        else
            self:Hide()
        end
    end

    -- wotlk private
    frame.SetAttributeNoHandler = frame.SetAttributeNoHandler or function(self, ...)
        self:SetAttribute(...)
    end

    -- wotlk private
    frame.SetObeyStepOnDrag = frame.SetObeyStepOnDrag or function() end
end

local createFrame = wow.CreateFrame

wow.CreateFrame = function(frameType, name, parent, template, id)
    if not name and isWotlkPrivate then
        -- wotlk private requires name to not be nil
        name = "FSDummyName" .. nextFrameId
        nextFrameId = nextFrameId + 1
    end

    -- wotlk private doesn't have this
    if template == "BackdropTemplate" and not BackdropTemplateMixin then
        template = nil
    end

    local frame = createFrame(frameType, name, parent, template, id)
    FrameShims(frame)
    return frame
end

wow.RegisterAttributeDriver = wow.RegisterAttributeDriver
    or function(frame, attribute, conditional)
        local attributeWithoutState = string.gsub(attribute, "state%-", "")
        wow.RegisterStateDriver(frame, attributeWithoutState, conditional)
    end

wow.UnregisterAttributeDriver = wow.UnregisterAttributeDriver
    or function(frame, attribute)
        local attributeWithoutState = string.gsub(attribute, "state%-", "")
        wow.UnregisterStateDriver(frame, attributeWithoutState)
    end

-- for unit tests
wow.CopyTable = wow.CopyTable
    or function(t)
        if type(t) ~= "table" then
            return t
        end

        local out = {}
        for k, v in pairs(t) do
            out[k] = wow.CopyTable(v)
        end

        return out
    end

wow.wipe = wow.wipe or function(t)
    for k in pairs(t) do
        t[k] = nil
    end
    return t
end

wow.IsInGroup = wow.IsInGroup
    or function()
        if GetNumGroupMembers then
            return GetNumGroupMembers() > 0
        end

        if GetNumRaidMembers and GetNumRaidMembers() > 0 then
            return true
        end

        if GetNumPartyMembers and GetNumPartyMembers() > 0 then
            return true
        end

        return false
    end

wow.IsInRaid = wow.IsInRaid or function()
    if GetNumRaidMembers and GetNumRaidMembers() > 0 then
        return true
    end

    return false
end

wow.GetTimePreciseSec = wow.GetTimePreciseSec or function()
    return debugprofilestop() / 1000
end

wow.issecretvalue = wow.issecretvalue or function()
    return false
end

wow.GetAddOnEnableState = function(name, character)
    -- in wotlk private 3.4.3 C_AddOns exists but C_AddOns.GetAddOnEnableState doesn't
    if wow.C_AddOns and wow.C_AddOns.GetAddOnEnableState then
        return C_AddOns.GetAddOnEnableState(name, character)
    end

    if GetAddOnEnableState then
        -- argument order is reversed
        return GetAddOnEnableState(character, name)
    end

    local getAddonInfo = C_AddOns and C_AddOns.GetAddOnInfo or GetAddOnInfo

    if not getAddonInfo then
        return 0
    end

    local _, _, _, loadable, reason, _, _ = getAddonInfo(name)

    if loadable and not reason then
        return 1
    else
        return 0
    end
end
