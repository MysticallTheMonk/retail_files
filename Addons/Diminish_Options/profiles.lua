local _, NS = ...
local Panel = NS.Panel
local Widgets = NS.Widgets
local TestMode = NS.TestMode
local L = NS.L

local Dropdown = LibStub("WardzConfigDropdown-1.0")
local profiles = {}

local function RemoveProfileFromTable(value)
    for i, profile in ipairs(profiles) do
        for k, v in pairs(profile) do
            if v == value then
                tremove(profiles, i)
                break
            end
        end
    end
end

Panel:CreateChildPanel(L.PROFILES, function(panel)
    Widgets:CreateHeader(panel, panel.name, false, L.HEADER_PROFILES)

    for k, v in pairs(DiminishDB.profiles) do
        profiles[#profiles + 1] = { value = k, text = k }
    end

    local function RefreshPanelAndIcons()
        if TestMode:IsTestingOrAnchoring() then
            TestMode:HideAnchors()
            TestMode:Test(true)
        end
        DIMINISH_NS.Icons:OnFrameConfigChanged()
        DIMINISH_NS.Diminish:ToggleForZone()
        panel.refresh()
    end

    local function ResetProfile(deleteProfile)
        local profile = DIMINISH_NS.activeProfile
        if DiminishDB.profiles[profile] then
            DiminishDB.profiles[profile] = nil
        end

        if deleteProfile then
            DiminishDB.profileKeys[NS.PLAYER_NAME] = "Default"
            DIMINISH_NS.activeProfile = "Default"
            DIMINISH_NS.db = DiminishDB.profiles["Default"]
        else
            DiminishDB.profiles[profile] = Widgets:CopyTable(DIMINISH_NS.DEFAULT_SETTINGS, DiminishDB.profiles[profile])
            DIMINISH_NS.db = DiminishDB.profiles[profile]
        end

        RefreshPanelAndIcons()
    end

    -------------------------------------------------------------------

    local selectProfile = Dropdown.CreateDropdown(panel, L.SELECTPROFILE, L.SELECTPROFILE_TOOLTIP, profiles)
    selectProfile:SetPoint("TOPLEFT", panel, 30, -80)
    selectProfile:SetWidth(200)


    -- Reuse an existing profile
    local shareBtn = Widgets:CreateButton(panel, L.USEPROFILE, L.USEPROFILE_TOOLTIP, function(btn)
        local value = selectProfile:GetValue()
        if not value or value == EMPTY then return end
        if DIMINISH_NS.activeProfile == value then
            return Widgets:ShowError(L.PROFILEACTIVE)
        end

        DiminishDB.profileKeys[NS.PLAYER_NAME] = value
        DIMINISH_NS.db = DiminishDB.profiles[value]
        DIMINISH_NS.activeProfile = value
        DIMINISH_NS.db.version = DIMINISH_NS.DEFAULT_SETTINGS.version

        -- Copy any default settings if they don't exists in copied profile
        DIMINISH_NS.CopyDefaults({
            [value] = DIMINISH_NS.DEFAULT_SETTINGS
        }, DiminishDB.profiles)

        if DIMINISH_NS.IS_NOT_RETAIL and DIMINISH_NS.db.unitFrames.player.usePersonalNameplate then
            DIMINISH_NS.db.unitFrames.player.usePersonalNameplate = false
        end
        if DIMINISH_NS.IS_CLASSIC then
            DIMINISH_NS.db.unitFrames.focus.enabled = false
            DIMINISH_NS.db.unitFrames.arena.enabled = false
        end

        selectProfile:SetValue(nil)
        RefreshPanelAndIcons()
    end)
    shareBtn:SetPoint("RIGHT", selectProfile, 75, -8)
    shareBtn:SetWidth(70)


    -- Copy an existing profile's variables
    local copyBtn = Widgets:CreateButton(panel, L.COPY, L.COPY_TOOLTIP, function(btn)
        local value = selectProfile:GetValue()
        if not value or value == EMPTY then return end
        if DIMINISH_NS.activeProfile == value then
            return Widgets:ShowError(L.PROFILEACTIVE)
        end

        local profile = DIMINISH_NS.activeProfile
        DiminishDB.profiles[profile] = nil -- delete all values no matter what
        DiminishDB.profiles[profile] = Widgets:CopyTable(DiminishDB.profiles[value])
        DIMINISH_NS.db = DiminishDB.profiles[profile]
        DIMINISH_NS.db.version = DIMINISH_NS.DEFAULT_SETTINGS.version

        -- Copy any default settings if they don't exists in copied profile
        DIMINISH_NS.CopyDefaults({
            [profile] = DIMINISH_NS.DEFAULT_SETTINGS
        }, DiminishDB.profiles)

        if DIMINISH_NS.IS_NOT_RETAIL and DIMINISH_NS.db.unitFrames.player.usePersonalNameplate then
            DIMINISH_NS.db.unitFrames.player.usePersonalNameplate = false
        end
        if DIMINISH_NS.IS_CLASSIC then
            DIMINISH_NS.db.unitFrames.focus.enabled = false
            DIMINISH_NS.db.unitFrames.arena.enabled = false
        end

        selectProfile:SetValue(nil)
        RefreshPanelAndIcons()
    end)
    copyBtn:SetPoint("LEFT", shareBtn, 75, 0)
    copyBtn:SetWidth(70)


    -- Delete existing profile
    local deleteBtn = Widgets:CreateButton(panel, L.DELETE, L.DELETE_TOOLTIP, function(btn)
        local value = selectProfile:GetValue()
        if not value or value == EMPTY or value == "Default" then return end

        DiminishDB.profileKeys[value] = nil
        DiminishDB.profiles[value] = nil
        selectProfile:SetValue(nil)

        if value == NS.PLAYER_NAME then
            DiminishDB.profileKeys[value] = "Default"
        end

        if DIMINISH_NS.activeProfile == value then
            ResetProfile(true)
        end

        RemoveProfileFromTable(value)
        selectProfile:SetList(profiles)
    end)
    deleteBtn:SetPoint("LEFT", copyBtn, 75, 0)
    deleteBtn:SetWidth(70)


    -------------------------------------------------------------------

    local editBox = Widgets:CreateEditbox(panel, L.NEWPROFILE, L.NEWPROFILE_TOOLTIP)
    editBox:SetPoint("LEFT", selectProfile, 8, -80)
    editBox:SetScript("OnEditFocusGained", function()
        if not DiminishDB.profiles[NS.PLAYER_NAME] then
            if editBox:GetText() == "" then
                editBox:SetText(NS.PLAYER_NAME or "")
            end
        end
    end)

    -- Create new profile with given name if it doesn't exists
    -- Uses current active settings as starting point
    local editOkay = Widgets:CreateButton(panel, OKAY or "Okay", nil, function(btn)
        local value = (editBox:GetText() or ""):match("^%s*(.*%S)")
        if not value or value == "" or value == "Default" then return end

        if DiminishDB.profiles[value] then
            return Widgets:ShowError(L.PROFILEEXISTS)
        end

        DiminishDB.profileKeys[NS.PLAYER_NAME] = value

        DIMINISH_NS.CopyDefaults({
            [value] = DIMINISH_NS.db
        }, DiminishDB.profiles)

        DIMINISH_NS.db = DiminishDB.profiles[value]
        DIMINISH_NS.activeProfile = value

        -- Insert to dropdown
        profiles[#profiles + 1] = {
            value = value,
            text = value
        }

        editBox:SetText("")
        editBox:ClearFocus()
        RefreshPanelAndIcons()
    end)
    editOkay:SetPoint("RIGHT", editBox, 75, 0)
    editOkay:SetWidth(70)

    -------------------------------------------------------------------

    -- Reset current profile but not delete
    local resetBtn = Widgets:CreateButton(panel, L.RESETPROFILE, L.RESETPROFILE_TOOLTIP, function() ResetProfile(false) end)
    resetBtn:SetPoint("LEFT", editBox, 0, -100)


    local profileText = panel:CreateFontString(nil, "ARTWORK", "GameFontHighlight")
    profileText:SetJustifyH("LEFT")
    profileText:SetPoint("TOPLEFT", resetBtn, 0, 25)
    profileText:SetFont(profileText:GetFont(), 13)

    -------------------------------------------------------------------

    panel.refresh = function()
        profileText:SetText(format(L.CURRENT_PROFILE, DiminishDB.profileKeys[NS.PLAYER_NAME]))
    end
end)
