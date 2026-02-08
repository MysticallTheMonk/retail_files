local _, ADDON = ...

local MOUNT_SPELL = 1215279
local DRIVE_TRAIT_SYSTEM = 19
local DRIVE_TRAIT_TREE = 1056

local function BuildButton()
    local button = CreateFrame("Button", nil, MountJournal, "DynamicFlightFlyoutPopupButtonTemplate")
    button.texture = button:CreateTexture(nil, "ARTWORK")
    button.texture:SetTexture(6383564) -- inv_111_wheel_blue
    button.texture:SetAllPoints()

    if ElvUI then
        local E = unpack(ElvUI)
        local ElvSkin = E:GetModule('Skins')

        -- from Collectables.lua HandleDynamicFlightButton
        button:SetPushedTexture(0)
        button:GetHighlightTexture():SetColorTexture(1, 1, 1, .25)
        button:SetNormalTexture(0)

        ElvSkin:HandleIcon(button.texture)
    end

    button:HookScript("OnClick", function()
        GenericTraitUI_LoadUI()

        GenericTraitFrame:SetConfigIDBySystemID(DRIVE_TRAIT_SYSTEM)
        GenericTraitFrame:SetTreeID(DRIVE_TRAIT_TREE)
        ToggleFrame(GenericTraitFrame)
    end)

    button:HookScript("OnEnter", function(self)
        GameTooltip:SetOwner(self, "ANCHOR_RIGHT")
        GameTooltip:ClearLines()
        GameTooltip_SetTitle(GameTooltip, GENERIC_TRAIT_FRAME_DRIVE_TITLE)

        GameTooltip:Show()
    end)
    button:HookScript("OnLeave", function()
        GameTooltip:Hide()
    end)

    button:SetAttribute("MJE_ToolbarIndex", "Drive")

    return button
end

ADDON.Events:RegisterCallback("loadUI", function()
    if C_SpellBook.IsSpellInSpellBook(MOUNT_SPELL) then
        ADDON.UI:RegisterToolbarGroup('05-drive-G99', BuildButton())
    end
end, 'drive' )