local _, ADDON = ...

local function createJournalButton()

    -- the addon DressUp replaces DressUpFrame entirely and doesn't have a ModelScene
    if DressUpFrame.ModelScene then

        local AceGUI = LibStub("AceGUI-3.0")

        local button = AceGUI:Create("Button")
        button:SetParent({ content = DressUpFrame })
        button:SetText(ADDON.L.DRESSUP_LABEL)
        button:SetAutoWidth(true)
        if button.frame:GetWidth() < 81 then
            button:SetWidth(81)
        end
        button:SetHeight(22)
        button:SetPoint("BOTTOMLEFT", DressUpFrame, "BOTTOMLEFT", 7, 4)

        button:SetCallback("OnClick", function(self)
            local parentFrame = self.parent.content
            if parentFrame.mode == "mount" then
                local mountId = parentFrame:GetAttribute("mountID")
                if mountId then
                    SetCollectionsJournalShown(true, COLLECTIONS_JOURNAL_TAB_INDEX_MOUNTS);
                    ADDON.Api:SetSelected(mountId)
                end
            end
        end)

        hooksecurefunc(DressUpFrame.ModelScene, "ClearScene", function()
            button.frame:Hide()
        end)
        hooksecurefunc(DressUpFrame.ModelScene, "AttachPlayerToMount", function()
            if ADDON.settings.ui.previewButton then
                button.frame:Show()
            end
        end)

        ADDON.UI.DressUpJournalButton = button.frame
    end
end

local inititalized = false

ADDON:RegisterUISetting('previewButton', true, ADDON.L.SETTING_PREVIEW_LINK, function(flag)
    if flag and not inititalized then
        createJournalButton()

        hooksecurefunc("DressUpMount", function(mountId)
            if mountId then
                DressUpFrame:SetAttribute("mountID", mountId)
            end
        end)

        inititalized = true
    end
end)

ADDON.Events:RegisterCallback("OnLogin", function()
    ADDON:ApplySetting('previewButton', ADDON.settings.ui.previewButton)
end, "dressUp")
