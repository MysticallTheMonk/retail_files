local _, ADDON = ...

local buttonList = {}
local renderToolbar

do
    local options

    if ADDON.isClassic then
        options = {
            SyncTarget = ADDON.L.SYNC_TARGET_TIP_TITLE,
            PetSlot = ADDON.L.PET_ASSIGNMENT_TITLE,
            RandomFavorite = MOUNT_JOURNAL_SUMMON_RANDOM_FAVORITE_MOUNT,
        }
    else
        options = {
            Equiment = MOUNT_EQUIPMENT_LEVEL_UP_FEATURE,
            SyncTarget = ADDON.L.SYNC_TARGET_TIP_TITLE,
            Skills = OPEN_DYNAMIC_FLIGHT_TREE_TOOLTIP,
            ToggleDynamicFlight = DYNAMIC_FLIGHT,
            ToggleRideAlong = MOUNT_JOURNAL_FILTER_RIDEALONG,
            ToggleWhirlingSurge = C_Spell.GetSpellName(361584) .. " / " .. C_Spell.GetSpellName(418592),
            Drive = GENERIC_TRAIT_FRAME_DRIVE_TITLE,
            PetSlot = ADDON.L.PET_ASSIGNMENT_TITLE,
            RandomFavorite = C_Spell.GetSpellName(150544)
        }
    end

    local defaults = CopyTable(options)
    for key in pairs(defaults) do
        defaults[key] = true
    end
    ADDON:RegisterUISetting('toolbarButtons',
        defaults,
        ADDON.L.SETTING_SHOW_TOOLBAR_BUTTONS,
        function()
            if ADDON.initialized then
                renderToolbar()
            end
        end,
        options
    )
end

renderToolbar = function()
    local lastButton
    local activeCount = 0

    local names = GetKeysArray(buttonList)
    table.sort(names)

    for _, name in ipairs(names) do
        local group = buttonList[name]
        group = tFilter(group, function(button)
            local index = button:GetAttribute("MJE_ToolbarIndex") or "none"
            local shouldShow = ADDON.settings.ui.toolbarButtons[index]
            button:SetShown(shouldShow)
            return shouldShow
        end, true)

        if #group > 0 then

            group[#group]:ClearAllPoints()

            if lastButton then
                group[#group]:SetPoint("RIGHT", lastButton, "LEFT", -10, 0)
            else
                group[#group]:SetPoint("CENTER", MountJournal, "TOPRIGHT", -24, -42)
            end

            for i = #group-1, 1, -1 do
                group[i]:ClearAllPoints()
                group[i]:SetPoint("RIGHT", group[i+1], "LEFT", -2, 0)
            end

            lastButton = group[1]
            activeCount = activeCount + 1
        end
    end

    if MountJournal.SummonRandomFavoriteSpellFrame then
        MountJournal.SummonRandomFavoriteSpellFrame.Label:SetShown(activeCount == 1 and MountJournal.SummonRandomFavoriteSpellFrame.Button:IsShown())
    end
end

function ADDON.UI:RegisterToolbarGroup(name, ...)
    local group = { ... }

    if #group > 0 then
        buttonList[name] = group

        if ADDON.initialized then
            renderToolbar()
        end
    end
end

ADDON.Events:RegisterCallback("loadUI", function()
    if MountJournal.SummonRandomFavoriteSpellFrame then
        MountJournal.SummonRandomFavoriteSpellFrame.Button:SetAttribute("MJE_ToolbarIndex", "RandomFavorite")
        ADDON.UI:RegisterToolbarGroup("00-random-mount", MountJournal.SummonRandomFavoriteSpellFrame.Button)
    else
        renderToolbar()
    end
end, 'toolbar' )