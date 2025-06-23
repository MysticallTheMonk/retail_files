---@type string, Namespace
local _, ns = ...

---@class ProfileFrame
local profileFrame = {}
ns.profileFrame = profileFrame

---@param profile ProfileSettings
local function activateProfile(profile)
    ns.settings.activeProfile = profile
    ns.settings:Save()
    ns.settingsFrame:syncWithSettings()
    ns.blocklistFrame:syncWithSettings()
    ns.profileFrame:syncWithSettings()
end

local function deleteCurrentProfile()
    ns.settings:DeleteCurrentProfile()
    ns.settings:Save()
    ns.settingsFrame:syncWithSettings()
    ns.blocklistFrame:syncWithSettings()
    ns.profileFrame:syncWithSettings()
end

---@param name string
local function createNewProfile(name)
    ns.settings:CreateNewProfile(name)
    ns.settings:Save()
    ns.settingsFrame:syncWithSettings()
    ns.blocklistFrame:syncWithSettings()
    ns.profileFrame:syncWithSettings()
end

local frame = CreateFrame("Frame", nil, UIParent)
frame:Hide()
frame.name = "Profile"
frame.parent = "TrufiGCD"
ns.utils.interfaceOptions_AddCategory(frame)

local selectActiveProfile = CreateFrame("Frame", "TrGCDActiveProfileSelect", frame, "UIDropDownMenuTemplate")
selectActiveProfile:SetPoint("TOPLEFT", -5, -50)

UIDropDownMenu_SetWidth(selectActiveProfile, 150)
UIDropDownMenu_Initialize(selectActiveProfile, function()
    local info = UIDropDownMenu_CreateInfo()

    for i, profile in pairs(ns.settings.profiles) do
        info.text = profile.name
        info.menuList = i
        info.func = function()
            activateProfile(profile)
        end
        info.notCheckable = true

        UIDropDownMenu_AddButton(info)
    end
end)

ns.frameUtils.addTooltip(selectActiveProfile, "Active profile", "Change the currently active profile")

local selectActiveProfileText = selectActiveProfile:CreateFontString(nil, "BACKGROUND")
selectActiveProfileText:SetFont(STANDARD_TEXT_FONT, 12)
selectActiveProfileText:SetText("Active profile")
selectActiveProfileText:SetPoint("TOPLEFT", 30, 12)

-- delete confirm frame
local frameConfirmDelete = CreateFrame("Frame", "TrGCDframeConfirmDelete", frame, "TooltipBorderBackdropTemplate")
frameConfirmDelete:Hide()
frameConfirmDelete:SetPoint("TOP", -90, -90)
frameConfirmDelete:SetWidth(230)
frameConfirmDelete:SetHeight(60)
frameConfirmDelete:SetFrameLevel(10)

local frameConfirmDeleteTitle = frameConfirmDelete:CreateFontString(frameConfirmDelete:GetName() .. "Title", "BACKGROUND", "GameFontHighlightSmall")
frameConfirmDeleteTitle:SetPoint("BOTTOMLEFT", frameConfirmDelete, "TOPLEFT", 5, 0)

local textureConfirmDelete = frameConfirmDelete:CreateTexture(nil, "BACKGROUND")
textureConfirmDelete:SetAllPoints(frameConfirmDelete)
textureConfirmDelete:SetColorTexture(0, 0, 0)
textureConfirmDelete:SetAlpha(0.8)

local textConfirmDelete = frameConfirmDelete:CreateFontString(nil, "BACKGROUND")
textConfirmDelete:SetFont(STANDARD_TEXT_FONT, 12)
textConfirmDelete:SetText("Confirm delete")
textConfirmDelete:SetPoint("TOP", 0, -10)

local buttonConfirmDeleteYes = CreateFrame("Button", nil, frameConfirmDelete, "UIPanelButtonTemplate")
buttonConfirmDeleteYes:SetWidth(100)
buttonConfirmDeleteYes:SetHeight(22)
buttonConfirmDeleteYes:SetPoint("TOP", -55, -30)
buttonConfirmDeleteYes:SetText("Yes")
buttonConfirmDeleteYes:SetScript("OnClick", function()
    frameConfirmDelete:Hide()
    deleteCurrentProfile()
end)

local buttonConfirmDeleteNo = CreateFrame("Button", nil, frameConfirmDelete, "UIPanelButtonTemplate")
buttonConfirmDeleteNo:SetWidth(100)
buttonConfirmDeleteNo:SetHeight(22)
buttonConfirmDeleteNo:SetPoint("TOP", 55, -30)
buttonConfirmDeleteNo:SetText("No")
buttonConfirmDeleteNo:SetScript("OnClick", function()
    frameConfirmDelete:Hide()
end)

-- delete button
local buttonDelete = CreateFrame("Button", nil, frame, "UIPanelButtonTemplate")
buttonDelete:SetWidth(100)
buttonDelete:SetHeight(22)
buttonDelete:SetPoint("TOPLEFT", 190, -53)
buttonDelete:SetText("Delete")
buttonDelete:SetScript("OnClick", function()
    if ns.utils.size(ns.settings.profiles) > 1 then
        frameConfirmDelete:Show()
    end
end)

if ns.utils.size(ns.settings.profiles) <= 1 then
    buttonDelete:Disable()
else
    buttonDelete:Enable()
end
ns.frameUtils.addTooltip(buttonDelete, "Delete", "Delete the currently active profile")

---@param name string
local function nameValid(name)
    return name and string.len(name) > 0
end

local editboxNewProfile = CreateFrame("EditBox", nil, frame, "InputBoxTemplate")
editboxNewProfile:SetWidth(160)
editboxNewProfile:SetHeight(20)
editboxNewProfile:SetPoint("TOPLEFT", 18, -120)
editboxNewProfile:SetAutoFocus(false)
editboxNewProfile:SetScript("OnEscapePressed", function(self) self:ClearFocus() end)
ns.frameUtils.addTooltip(editboxNewProfile, "New profile", "Copy the active profile settings to a new one")

local editboxNewProfileText = editboxNewProfile:CreateFontString(nil, "BACKGROUND")
editboxNewProfileText:SetFont(STANDARD_TEXT_FONT, 12)
editboxNewProfileText:SetText("New profile")
editboxNewProfileText:SetPoint("TOPLEFT", 7, 15)

local buttonCreateNew = CreateFrame("Button", nil, frame, "UIPanelButtonTemplate")
buttonCreateNew:SetWidth(60)
buttonCreateNew:SetHeight(22)
buttonCreateNew:SetPoint("TOPLEFT", 175, -118)
buttonCreateNew:SetText("New")
buttonCreateNew:Disable()

local function onNewProfileSubmit()
    local name = editboxNewProfile:GetText()
    if nameValid(name) then
        createNewProfile(name)
        buttonCreateNew:Disable()
        editboxNewProfile:SetText("")
        editboxNewProfile:ClearFocus()
    end
end
buttonCreateNew:SetScript("OnClick", onNewProfileSubmit)
editboxNewProfile:SetScript("OnEnterPressed", onNewProfileSubmit)

editboxNewProfile:SetScript("OnTextChanged", function()
    local name = editboxNewProfile:GetText()
    if nameValid(name) then
        buttonCreateNew:Enable()
    else
        buttonCreateNew:Disable()
    end
end)

profileFrame.syncWithSettings = function()
    UIDropDownMenu_SetText(selectActiveProfile, ns.settings.activeProfile.name)

    if ns.utils.size(ns.settings.profiles) <= 1 then
        buttonDelete:Disable()
    else
        buttonDelete:Enable()
    end

    --TODO: move to the units module
    for _, unit in pairs(ns.units) do
        unit.iconQueue:Resize()
        unit:Clear()
    end
end
