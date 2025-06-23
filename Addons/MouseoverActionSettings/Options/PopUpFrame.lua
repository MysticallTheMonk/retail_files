local addonName, addonTable = ...
local addon = addonTable.addon
local L = LibStub("AceLocale-3.0"):GetLocale(addonName)

local AceGUI = LibStub("AceGUI-3.0")
local ACD = LibStub("AceConfigDialog-3.0")

local function createAceContainer(AceContainer, parent)
    local scrollContainer = AceGUI:Create("ScrollFrame")
    scrollContainer:SetLayout("Fill")
    scrollContainer.frame:SetParent(parent)
    scrollContainer.frame:SetPoint("TOPLEFT", parent, "TOPLEFT", 20, -40)
    scrollContainer.frame:SetPoint("BOTTOMRIGHT", parent, "BOTTOMRIGHT", -20, 25)
    scrollContainer.frame:SetClipsChildren(true)
    scrollContainer.frame:Show()
    local container = AceGUI:Create("SimpleGroup")
    scrollContainer:AddChild(container)
    return container
end

local function createCloseButton(parentFrame)
    local CloseButton = CreateFrame("Button", nil, parentFrame, "UIPanelCloseButton")
    CloseButton:SetPoint("TOPRIGHT", parentFrame, "TOPRIGHT", 1, 0)
    return CloseButton
end

local function applySkin(frame)
    local frameColor = {r=0.1,g=0.1,b=0.1,a=1}
    for _, texture in pairs({
        frame.NineSlice.TopEdge,
        frame.NineSlice.BottomEdge,
        frame.NineSlice.TopRightCorner,
        frame.NineSlice.TopLeftCorner,
        frame.NineSlice.RightEdge,
        frame.NineSlice.LeftEdge,
        frame.NineSlice.BottomRightCorner,
        frame.NineSlice.BottomLeftCorner,  
    }) do
        texture:SetDesaturation(1)
        texture:SetVertexColor(frameColor.r,frameColor.g,frameColor.b,frameColor.a) 
    end
    frame.Bg:SetColorTexture(0,0,0,0.9)
end


local frame = nil
function addon:GetPopUpFrame()
    if frame then 
        return frame
    end
    local options_frame = addon:GetOptionsFrame()
    frame = CreateFrame("Frame", "MouseoverActionBarsTriggerFrame", options_frame, "DefaultPanelFlatTemplate")
    frame:Hide()
    frame:EnableMouse(true)
    createCloseButton(frame)
    frame.title = _G["MouseoverActionBarsTriggerFrameTitleText"]
    frame.Bg = frame:CreateTexture()
    frame.Bg:SetPoint("TOPLEFT", frame, "TOPLEFT", 6, -4)
    frame.Bg:SetPoint("BOTTOMRIGHT", frame, "BOTTOMRIGHT", -1, 3)
    local container = createAceContainer("SimpleGroup", frame)
    frame.container = container
    frame:SetPoint("TOPLEFT", options_frame, "TOPLEFT", 15, -55)
    frame:SetPoint("BOTTOMRIGHT", options_frame, "BOTTOMRIGHT", -15, 25)
    frame:HookScript("OnHide",function()
        container:ReleaseChildren()
    end)
    frame:HookScript("OnShow",function()
        frame:SetAlpha(0)
        local info = {
            duration = 0.28,
            startAlpha = 0,
            endAlpha = 1,
        }
        addon:Fade(frame, info)
        options_frame.searchBox:Disable()
    end)
    frame:HookScript("OnHide", function()
        options_frame.searchBox:Enable()
    end)
    options_frame:HookScript("OnHide", function()
        frame:Hide()
    end)
    options_frame.triggerFrame = frame
    applySkin(frame)
    return frame
end

function addon:ShowTriggerFrame(info)
    local frame = self:GetPopUpFrame()
    local options = self:GetTriggerOptionsTable()
    local module_name = info[#info-1]
    local displayedMoudleName 
    if string.match(module_name, "UserModule_") then
        displayedMoudleName = string.gsub(module_name, "UserModule_", "")
    else
        displayedMoudleName = L[module_name]
    end
    frame.title:SetText("\124cFF7DF9FF" .. L["trigger_frame_title_before_module_name"] .. displayedMoudleName .. L["trigger_frame_title_after_module_name"] .. "\124r")
    --this field is guiHidden and only carries the module name to save the value into the db
    options.args.module.name = module_name
    frame:Show()
    ACD:Open("MouseOverActionSettings_Options_Trigger", frame.container)
end

function addon:ShowEventDelayTimerFrame()
    local frame = self:GetPopUpFrame()
    frame.title:SetText("\124cFF7FFFD4" .. L["event_delay_timer_title"] .. "\124r")
    frame:Show()
    ACD:Open("MouseOverActionSettings_Options_EventTimer", frame.container)
end