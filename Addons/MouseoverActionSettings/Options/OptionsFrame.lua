local addonName, addonTable = ...
local addon = addonTable.addon

local AceGUI = LibStub("AceGUI-3.0")
local ACD = LibStub("AceConfigDialog-3.0")
local L = LibStub("AceLocale-3.0"):GetLocale(addonName)

local function createAceContainer(AceContainer, parentFrame)
    local scrollContainer = AceGUI:Create("ScrollFrame")
    scrollContainer:SetLayout("Fill")
    scrollContainer.frame:SetParent(parentFrame)
    scrollContainer.frame:SetPoint("TOPLEFT", parentFrame, "TOPLEFT", 25, -65)
    scrollContainer.frame:SetPoint("BOTTOMRIGHT", parentFrame, "BOTTOMRIGHT", -25, 25)
    scrollContainer.content:SetPoint("TOPLEFT", parentFrame, "TOPLEFT", 25, -65)
    scrollContainer.content:SetPoint("BOTTOMRIGHT", parentFrame, "BOTTOMRIGHT", -25, 25)
    scrollContainer.frame:SetClipsChildren(true)
    scrollContainer.frame:Show()
    return scrollContainer
end

local function creatResizeButton(parentFrame)
    local resizeButton = CreateFrame("Button", nil, parentFrame)
    resizeButton:SetPoint("BOTTOMRIGHT",-1,1)
    resizeButton:SetSize(26, 26)
    resizeButton:SetNormalTexture("Interface\\ChatFrame\\UI-ChatIM-SizeGrabber-Up")
    resizeButton:SetHighlightTexture("Interface\\ChatFrame\\UI-ChatIM-SizeGrabber-Highlight")
    resizeButton:SetPushedTexture("Interface\\ChatFrame\\UI-ChatIM-SizeGrabber-Down")
    resizeButton:SetScript("OnMouseDown", function() 
        parentFrame:StartSizing("BOTTOMRIGHT")
    end)
    resizeButton:SetScript("OnMouseUp", function()
        parentFrame:StopMovingOrSizing("BOTTOMRIGHT")
    end)
    return resizeButton
end

local function createSearchBox(parentFrame)
    local searchBox = CreateFrame("EditBox", nil, parentFrame, "SearchBoxTemplate")
    searchBox.optionsTable = "MouseOverActionSettings_Options_Tab_1"
    searchBox:HookScript("OnTextChanged", function()
        parentFrame.container:ResumeLayout()
        addonTable.searchText = searchBox:GetText()
        parentFrame.container:ReleaseChildren()
        ACD:Open(searchBox.optionsTable, parentFrame.container)
    end)
    searchBox:HookScript("OnEnable", function(self)
        for _, region in pairs({
            "Left",
            "Middle",
            "Right"
        }) do
            self[region]:SetVertexColor(1, 1, 1, 1)
        end
    end)
    searchBox:HookScript("OnDisable", function(self)
        for _, region in pairs({
            "Left",
            "Middle",
            "Right"
        }) do
            self[region]:SetVertexColor(0.5, 0.5, 0.5, 0.5)
        end
    end)
    searchBox:SetWidth(300)
    searchBox:SetHeight(30)
    searchBox:SetPoint("TOP", parentFrame, "TOP", 0, -35)
    searchBox:SetAutoFocus(false)
    return searchBox
end


local function createTabs(parentFrame, ...)
    local TabSystem = CreateFrame("Frame", nil, parentFrame, "TabSystemTemplate")
    local tabs = {}
    TabSystem:SetTabSelectedCallback(function()end)
    TabSystem:SetPoint("TOPLEFT", parentFrame, "BOTTOMLEFT", 15, 2)
    for k,v in pairs({...}) do 
        TabSystem:AddTab(v)
        tabs[v] = TabSystem:GetTabButton(k)
    end
    TabSystem:SetTab(1)
    return TabSystem, tabs
end


local function clearFrame(frame)
    if frame.triggerFrame then
        frame.triggerFrame:Hide()
    end
    frame.searchBox:SetText("")
    addonTable.searchText = ""
    frame.container:ReleaseChildren()
end


local function applySkin(frame)
    local r,g,b = PANEL_BACKGROUND_COLOR:GetRGB()
    frame.Bg:SetColorTexture(r,g,b,0.9)

    if C_AddOns.IsAddOnLoaded("FrameColor") then
        FrameColor.API:ReloadSkin("_MouseoverActionSettings")
    end
end

local frame = nil
function addon:GetOptionsFrame(AceContainer)
    if frame then 
        return frame
    end
    local AceContainer = AceContainer and AceContainer or "SimpleGroup"
    frame = CreateFrame("Frame", "MouseoverActionSettingsOptions", UIParent, "PortraitFrameTemplate")
    frame:Hide()
    frame:SetScript("OnShow", function()
        --in case the addon got disabled via the minimap button this is needed
        addon:Enable()
    end)
    tinsert(UISpecialFrames, frame:GetName())
    frame:SetFrameStrata("DIALOG")
    frame.title = _G["MouseoverActionSettingsOptionsTitleText"]
    frame.title:SetText("Mouseover Action Settings")
    MouseoverActionSettingsOptionsPortrait:SetTexture(addonTable.texturePaths.PortraitIcon)
    frame:SetSize(950,560)
    frame:SetPoint("CENTER", UIparent, "CENTER")
    frame:SetMovable(true)
    frame:SetResizable(true)
    frame:SetUserPlaced(true)
    frame:SetResizeBounds(950, 560, 950)
    frame:SetClampedToScreen(true)
    frame:SetClampRectInsets(400, -400, 0, 180)
    frame:RegisterForDrag("LeftButton")
    frame.TitleContainer:SetScript("OnMouseDown", function()
        frame:StartMoving()
    end)
    frame.TitleContainer:SetScript("OnMouseUp", function()
        frame:StopMovingOrSizing()
    end)
    frame.resizeButton = creatResizeButton(frame)
    local container = createAceContainer(AceContainer, frame)
    frame.searchBox = createSearchBox(frame)
    frame.container = container
    frame.TabSystem, frame.tabs = createTabs(frame, L["Action Bars"], L["HUD"], L["Tinker Zone"], L["Link"], L["Config"], L["Profiles"])
    frame.tabs[L["Action Bars"]]:HookScript("OnClick", function()
        clearFrame(frame)
        frame.searchBox:Show()
        frame.searchBox.optionsTable = "MouseOverActionSettings_Options_Tab_1"
        ACD:Open("MouseOverActionSettings_Options_Tab_1",container)
    end)
    frame.tabs[L["HUD"]]:HookScript("OnClick", function()
        clearFrame(frame)
        frame.searchBox:Show()
        frame.searchBox.optionsTable = "MouseOverActionSettings_Options_Tab_2"
        ACD:Open("MouseOverActionSettings_Options_Tab_2",container)
    end)
    frame.tabs[L["Tinker Zone"]]:HookScript("OnClick", function()
        clearFrame(frame)
        frame.searchBox:Hide()
        ACD:Open("MouseOverActionSettings_Options_Tab_3",container)
    end)
    if not self.db.global.TinkerZone then
        frame.tabs[L["Tinker Zone"]]:Hide()
    end
    frame.tabs[L["Link"]]:HookScript("OnClick", function()
        clearFrame(frame)
        frame.searchBox:Show()
        frame.searchBox.optionsTable = "MouseOverActionSettings_Options_Tab_4"
        addon:CreateLinkGroupEntrys()
        ACD:Open("MouseOverActionSettings_Options_Tab_4",container)
    end)
    frame.tabs[L["Config"]]:HookScript("OnClick", function()
        clearFrame(frame)
        frame.searchBox:Hide()
        ACD:Open("MouseOverActionSettings_Options_Tab_5",container)
    end)
    frame.tabs[L["Profiles"]]:HookScript("OnClick", function()
        clearFrame(frame)
        frame.searchBox:Hide()
        ACD:Open("MouseOverActionSettings_Options_Tab_6",container)
    end)
    frame:SetScript("OnEvent", frame.Hide)
    frame:HookScript("OnShow", function()
        frame.TabSystem:SetTab(1)
        ACD:Open("MouseOverActionSettings_Options_Tab_1",container)
        frame.searchBox:Show()
        frame:RegisterEvent("PLAYER_REGEN_DISABLED")
    end)
    frame:HookScript("OnHide",function()
        clearFrame(frame)
        frame.searchBox.optionsTable = "MouseOverActionSettings_Options_Tab_1"
        frame:UnregisterEvent("PLAYER_REGEN_ENABLED")
    end)
    applySkin(frame)
    return frame
end

function addon:HideOptionsFrame()
    if not frame then
        return
    end
    frame:Hide()
end

