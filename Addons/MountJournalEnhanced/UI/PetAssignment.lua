local _, ADDON = ...

--todo: display assigned pet model as well next to mount (?)
--todo: preview pet in entry tooltip

ADDON:RegisterBehaviourSetting('summonPreviousPetAgain', true, ADDON.L.SETTING_SUMMONPREVIOUSPET)

local toolbarButton, updateToolbarButton, triggerUpdateDataProvider
local function assignPet(petId)
    local mountId = ADDON.Api:GetSelected()
    if petId or ADDON.settings.pets.assignments[mountId] then
        ADDON.settings.pets.assignments[mountId] = petId
        updateToolbarButton()
        triggerUpdateDataProvider()
    end
end
local function getAssignedPet()
    local mountId = ADDON.Api:GetSelected()
    return mountId and ADDON.settings.pets.assignments[mountId] or nil
end

local previousPet
ADDON.Events:RegisterCallback("CastMount", function(_, mountId)
    previousPet = nil
    if not InCombatLockdown() and not IsInInstance() then
        local toSummonPet = ADDON.settings.pets.assignments[mountId]
        if toSummonPet then
            previousPet = C_PetJournal.GetSummonedPetGUID()
            if previousPet ~= toSummonPet and C_PetJournal.PetIsSummonable(toSummonPet) then
                C_PetJournal.SummonPetByGUID(toSummonPet)
            end
        end
    end
end, "pet-assignment")
ADDON.Events:RegisterCallback("OnMountDown", function(_, mountId)
    if not InCombatLockdown() and ADDON.settings.summonPreviousPetAgain and ADDON.settings.pets.assignments[mountId] then
        local assignedPet = ADDON.settings.pets.assignments[mountId]
        local toSummonPet = previousPet or assignedPet
        if previousPet ~= assignedPet and toSummonPet and C_PetJournal.GetSummonedPetGUID() == assignedPet and C_PetJournal.PetIsSummonable(toSummonPet) then
            C_PetJournal.SummonPetByGUID(toSummonPet) -- calling again dismisses pet
            previousPet = nil
        end
    end
end, "pet-assignment")

--region pet side panel
local sidePanel
local savedPetApiFilters = {}
local scrollToSelection = false
local function saveAndResetPetApiFilters()
    savedPetApiFilters = {
        search = PetJournal.searchBox:GetText(),
        type = {},
        source = {},
        collected = true,
    }
    if C_PetJournal.IsUsingDefaultFilters and  not C_PetJournal.IsUsingDefaultFilters() then --retail
        savedPetApiFilters.collected = C_PetJournal.IsFilterChecked(LE_PET_JOURNAL_FILTER_COLLECTED)
        for i = 1, C_PetJournal.GetNumPetSources(), 1 do
            savedPetApiFilters.type[i] = C_PetJournal.IsPetSourceChecked(i)
        end
        for i = 1, C_PetJournal.GetNumPetTypes(), 1 do
            savedPetApiFilters.type[i] = C_PetJournal.IsPetTypeChecked(i)
        end
        -- reset api filters
        C_PetJournal.SetDefaultFilters()
    elseif not C_PetJournal.IsUsingDefaultFilters then
        savedPetApiFilters.collected = C_PetJournal.IsFilterChecked(LE_PET_JOURNAL_FILTER_COLLECTED)
        C_PetJournal.SetFilterChecked(LE_PET_JOURNAL_FILTER_COLLECTED, true)
    end
end
local function restorePetApiFilters()
    if false == savedPetApiFilters.collected then
        C_PetJournal.SetFilterChecked(LE_PET_JOURNAL_FILTER_COLLECTED, false)
    end
    for i, v in pairs(savedPetApiFilters.source) do
        C_PetJournal.SetPetSourceChecked(i, v)
    end
    for i, v in pairs(savedPetApiFilters.type) do
        C_PetJournal.SetPetTypeFilter(i, v)
    end
    if savedPetApiFilters.search then
        C_PetJournal.SetSearchFilter(savedPetApiFilters.search)
    end
end

triggerUpdateDataProvider = function ()
    if not sidePanel or not sidePanel:IsShown() then
        return
    end

    local searchText = sidePanel.SearchBox:GetText()
    if searchText then
        C_PetJournal.SetSearchFilter(searchText) -- dosn't always triggers update event when search term didn't change
        C_PetJournal.SetFilterChecked(LE_PET_JOURNAL_FILTER_COLLECTED, true) -- always fires PET_JOURNAL_LIST_UPDATE
    else
        C_PetJournal.ClearSearchFilter() -- always fires PET_JOURNAL_LIST_UPDATE
    end
end

local function stringContains(searchString, name)
    name = name:lower()
    local pos = strfind(name, searchString, 1, true)
    return pos ~= nil
end

local function updateDataProvider()
    local assignedPet = getAssignedPet()
    local searchText = sidePanel.SearchBox:GetText()
    if searchText then
        searchText = searchText:lower()
    end

    local selectedIndex = 1
    local payload = {
        [1] = {
            index = 0,
            name = ADDON.L.PET_ASSIGNMENT_NONE,
            selected = assignedPet == nil,
        }
    }
    local _, numOwned = C_PetJournal.GetNumPets()
    local lastPet
    for index = 1, numOwned, 1 do
        local petID, speciesId, owned, customName, _, _, isRevoked, speciesName  = C_PetJournal.GetPetInfoByIndex(index)
        if not owned then
            break
        end

        if lastPet ~= speciesId and not isRevoked then
            -- ingame search also looks for ability names. we filter here even further. only by names
            if not searchText or (customName and stringContains(searchText, customName)) or stringContains(searchText, speciesName) then
                payload[#payload+1] = {
                    index = index,
                    selected = (assignedPet == petID),
                }
                lastPet = speciesId
                if assignedPet == petID then
                    selectedIndex = #payload
                end
            end
        elseif lastPet == speciesId and assignedPet == petID then
            payload[#payload].selected = true
            selectedIndex = #payload
        end
    end

    sidePanel.ScrollBox:SetDataProvider(CreateDataProvider(payload), ScrollBoxConstants.RetainScrollPosition)
    if scrollToSelection then
        sidePanel.ScrollBox:ScrollToElementDataIndex(selectedIndex)
        scrollToSelection = false
    end
end

local function buildSidePanel()
    local L = ADDON.L
    local AceGUI = LibStub("AceGUI-3.0")
    local window = AceGUI:Create("Window")

    -- Create frame
    window:SetTitle(L.PET_ASSIGNMENT_TITLE)
    window:SetHeight(606)
    window:SetWidth(270)
    window:ClearAllPoints()
    window:SetPoint("TOPLEFT", MountJournal, "TOPRIGHT", 0, 0)
    window:SetLayout("List")
    window:EnableResize(false)
    window.title:EnableMouse(false)
    window.frame:SetMovable(false)
    window.frame:SetFrameStrata(MountJournal:GetFrameStrata())

    local helpTooltip
    local toggleInfoDescription = function(self)
        if not HelpTip.IsShowingAny then
            -- classic has no HelpTip system yet :(

            if not helpTooltip then
                helpTooltip = CreateFrame("GameTooltip", "MJEPetAssignmentHelpToolTip", window.InfoButton, "GameTooltipTemplate")
                helpTooltip:Hide()
                helpTooltip:HookScript("OnHide", function()
                    ADDON.settings.pets.seenInfo = true
                end)
            end
            if helpTooltip:IsShown() then
                helpTooltip:Hide()
            else
                helpTooltip:SetOwner(window.InfoButton, "ANCHOR_BOTTOMRIGHT", -40, 20)
                GameTooltip_AddNormalLine(helpTooltip, ADDON.L.PET_ASSIGNMENT_INFO, true)
                helpTooltip:Show()
            end
        elseif HelpTip:IsShowingAny(self) then
            HelpTip:HideAll(self)
        else
            HelpTip:Show(self, {
                text = ADDON.L.PET_ASSIGNMENT_INFO,
                buttonStyle = HelpTip.ButtonStyle.GotIt,
                targetPoint = HelpTip.Point.BottomEdgeLeft,
                alignment = HelpTip.Alignment.Left,
                offsetX = 32,
                offsetY = 18,
                autoHorizontalSlide = true,
                onAcknowledgeCallback = function()
                    ADDON.settings.pets.seenInfo = true
                end
            })
        end
    end

    window.InfoButton = CreateFrame("Button", nil, window.frame, "MainHelpPlateButton")
    window.InfoButton:SetPoint("TOPLEFT", -6, 19)
    window.InfoButton:SetScript("OnEnter",function() end)
    window.InfoButton:HookScript("OnClick", toggleInfoDescription)

    local scrollFiller = AceGUI:Create("SimpleGroup")
    scrollFiller.frame:SetFrameStrata(MountJournal:GetFrameStrata())
    scrollFiller:SetFullWidth(true)
    scrollFiller:SetHeight(540) -- somehow bottom settings gets pushed over border. so we have to manually adjust here.
    scrollFiller:SetAutoAdjustHeight(false)
    window:AddChild(scrollFiller)

    local frame = window.frame

    frame.SearchBox = CreateFrame("EditBox", nil, scrollFiller.content, "SearchBoxTemplate")
    frame.SearchBox:SetHeight(18)
    frame.SearchBox:SetPoint("TOP", 0, -5)
    frame.SearchBox:SetPoint("LEFT", 6, 0)
    frame.SearchBox:SetPoint("RIGHT", 0, 0)
    frame.SearchBox:HookScript("OnTextChanged", function ()
        triggerUpdateDataProvider()
    end)

    frame.ScrollBox = CreateFrame("Frame", nil, scrollFiller.content, "WowScrollBoxList")
    frame.ScrollBox:SetPoint("LEFT", 5, 0)
    frame.ScrollBox:SetPoint("RIGHT", -20, 0)
    frame.ScrollBox:SetPoint("TOP", frame.SearchBox, "BOTTOM", 0, -5)
    frame.ScrollBox:SetPoint("BOTTOM", 0, 5)

    frame.ScrollBar = CreateFrame("EventFrame", nil, scrollFiller.content, "MinimalScrollBar")
    frame.ScrollBar:ClearAllPoints()
    frame.ScrollBar:SetPoint("TOP", frame.ScrollBox, "TOP", 0, 0)
    frame.ScrollBar:SetPoint("RIGHT", -5, 0)
    frame.ScrollBar:SetPoint("BOTTOM", frame.ScrollBox, "BOTTOM", 0, 0)

    local view = CreateScrollBoxListLinearView();
	view:SetElementInitializer("CompanionListButtonTemplate", function(button, elementData)
	    button:SetHeight(29)
        button.icon:SetSize(29, 29)
        button.icon:ClearAllPoints()
        button.icon:SetPoint("RIGHT", button, "LEFT", -2, 0)
        button.petTypeIcon:SetHeight(27)
        button.dragButton:Hide()
        button:RegisterForDrag() --turn off
        button:RegisterForClicks("LeftButtonUp", "RightButtonUp")
        PetJournal_InitPetButton(button, elementData)
        button.name:ClearAllPoints()
        button.name:SetPoint("LEFT", button.icon, "RIGHT", 10, button.subName:IsShown() and 5 or 0)
        button.subName:SetPoint("TOPLEFT", button.name, "BOTTOMLEFT", 0, -1)

        button.selected = elementData.selected
        button.selectedTexture:SetShown(elementData.selected)
        if elementData.name then
            button.name:SetText(elementData.name)
            button.name:SetFontObject("GameFontNormal")
        end

        button:SetScript("OnClick", function (self, mouseButton)
            if mouseButton == "RightButton" then
                if C_PetJournal.PetIsSummonable(self.petID) then
                    C_PetJournal.SummonPetByGUID(self.petID)
                end
            else
                assignPet(self.petID)
            end
        end)

        --todo?: skin with ElvUI. see: ElvUI/Mainline/Modules/Skins/Collectables.lua::JournalScrollButtons()
	end);
    view:SetPadding(0,0,29,0,0)
    view:SetElementExtent(29)
    ScrollUtil.InitScrollBoxListWithScrollBar(frame.ScrollBox, frame.ScrollBar, view)

    local summonAgain = AceGUI:Create("CheckBox")
    summonAgain:SetLabel(ADDON.L.SETTING_SUMMONPREVIOUSPET)
    summonAgain:SetFullWidth(true)
    summonAgain:SetValue(ADDON.settings.summonPreviousPetAgain)
    summonAgain:SetCallback("OnValueChanged", function(_, _, value)
        ADDON:ApplySetting('summonPreviousPetAgain', value)
    end)
    summonAgain:SetHeight(28)
    summonAgain.text:SetHeight(28)
    summonAgain.text:SetTextHeight(11)
    summonAgain.text:SetJustifyV("BOTTOM")
    window:AddChild(summonAgain)

    frame:Hide()
    frame:HookScript("OnShow", function ()
        scrollToSelection = true
        saveAndResetPetApiFilters()
        if not ADDON.settings.pets.seenInfo then
            toggleInfoDescription(window.InfoButton)
        end
        toolbarButton:SetChecked(true)
    end)
    frame:HookScript("OnHide", function ()
        restorePetApiFilters()
        toolbarButton:SetChecked(false)
    end)
    frame:RegisterEvent("PET_JOURNAL_LIST_UPDATE")
    frame:HookScript("OnEvent", function(_, event)
        if event == "PET_JOURNAL_LIST_UPDATE" and frame:IsShown() then
            updateDataProvider()
        end
    end)
    MountJournal:HookScript("OnHide", function ()
        frame:Hide()
    end)

    if ElvUI then
        local E = unpack(ElvUI)
        local ElvSkin = E:GetModule('Skins')
        ElvSkin:HandleEditBox(frame.SearchBox)
        ElvSkin:HandleTrimScrollBar(frame.ScrollBar)
        window.InfoButton:Hide()
    end

    ADDON.UI.PetAssignmentInfoButton = window.InfoButton

    return frame
end
local function toggleSidePanel()
    if not sidePanel then
        sidePanel = buildSidePanel()
        sidePanel:Show()
    else
        sidePanel:SetShown(not sidePanel:IsShown())
    end
end

--endregion

--region toolbar button
local function DisplayTooltip(self)
    local L = ADDON.L

    local petGUID = getAssignedPet()
    local petName = L.PET_ASSIGNMENT_NONE
    if petGUID then
        local _, customName, _, _, _, _, _, name = C_PetJournal.GetPetInfoByPetID(petGUID)
        petName = customName or name
    end

    GameTooltip:SetOwner(self, "ANCHOR_RIGHT")
    GameTooltip:ClearLines()
    GameTooltip_SetTitle(GameTooltip, L.PET_ASSIGNMENT_TITLE)
    GameTooltip_AddNormalLine(GameTooltip, L.PET_ASSIGNMENT_TOOLTIP_CURRENT.." "..petName, true)
    GameTooltip_AddInstructionLine(GameTooltip, L.PET_ASSIGNMENT_TOOLTIP_LEFT)
    GameTooltip_AddInstructionLine(GameTooltip, L.PET_ASSIGNMENT_TOOLTIP_RIGHT)
    GameTooltip:Show()
end

updateToolbarButton = function()
    local petGUID = getAssignedPet()
    local icon = petGUID and select(9, C_PetJournal.GetPetInfoByPetID(petGUID))
    toolbarButton.Icon:SetTexture(icon or 132599)
end
local function buildToolbarButton()
    local button = CreateFrame("CheckButton", nil, MountJournal)
    button:SetSize(30, 30)
    -- from DynamicFlightFlyoutButtonTemplate
    button:SetSize(30, 30)
    button.NormalTexture = button:CreateTexture()
    button.NormalTexture:SetAtlas("UI-HUD-ActionBar-IconFrame")
    button.NormalTexture:SetSize(31, 31)
    button:SetNormalTexture(button.NormalTexture)
    button.PushedTexture = button:CreateTexture()
    button.PushedTexture:SetAtlas("UI-HUD-ActionBar-IconFrame-Down")
    button.PushedTexture:SetSize(31, 31)
    button:SetPushedTexture(button.PushedTexture)
    button.HighlightTexture = button:CreateTexture()
    button.HighlightTexture:SetAtlas("UI-HUD-ActionBar-IconFrame-Mouseover")
    button.HighlightTexture:SetSize(31, 31)
    button:SetHighlightTexture(button.HighlightTexture)
    button.CheckedTexture = button:CreateTexture()
    button.CheckedTexture:SetAtlas("UI-HUD-ActionBar-IconFrame-Down")
    button.CheckedTexture:SetSize(31, 31)
    button:SetCheckedTexture(button.CheckedTexture)

    button.Icon = button:CreateTexture(nil, "ARTWORK")
    button.Icon:SetAllPoints()

    button:RegisterForClicks("AnyUp")
    button:HookScript("OnCLick", function (_, mouseButton)
        if mouseButton == "LeftButton" then
            toggleSidePanel()
        elseif mouseButton == "RightButton" then
            assignPet(C_PetJournal.GetSummonedPetGUID())
        end
    end)
    button:HookScript("OnEnter", DisplayTooltip)
    button:HookScript("OnLeave", function()
        GameTooltip:Hide()
    end)

    if ElvUI then
        local E = unpack(ElvUI)
        local ElvSkin = E:GetModule('Skins')

        -- from Collectables.lua HandleDynamicFlightButton
        button:SetPushedTexture(0)
        button:GetHighlightTexture():SetColorTexture(1, 1, 1, .25)
        button:SetNormalTexture(0)
        button:SetCheckedTexture(E.media.normTex)
        button:GetCheckedTexture():SetColorTexture(1, 1, 1, .25)

        ElvSkin:HandleIcon(button.Icon)
    end

    button:Show()
    button:SetAttribute("MJE_ToolbarIndex", "PetSlot")
    ADDON.UI.PetAssignmentToolbarButton = button

    return button
end
--endregion

ADDON.Events:RegisterCallback("loadUI", function()
    if not toolbarButton then
        toolbarButton = buildToolbarButton()
    end
    ADDON.UI:RegisterToolbarGroup("01-petslot", toolbarButton)
end, "pet-assignment")

ADDON.Events:RegisterCallback("OnUpdateMountDisplay", function()
    if not toolbarButton then
        toolbarButton = buildToolbarButton()
    end
    updateToolbarButton()
    scrollToSelection = true
    triggerUpdateDataProvider()
end, "pet-assignment")