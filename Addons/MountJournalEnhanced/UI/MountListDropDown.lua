local _, ADDON = ...

local function CreateContextMenu(_, rootDescription, mountId)
    rootDescription:SetTag("MENU_MOUNT_COLLECTION_MOUNT");

    local _, spellId, _, active, isUsable, _, _, _, _, _, isCollected, menuMountID = ADDON.Api:GetMountInfoByID(mountId)

    local text;
    local checkEnabled = false;
    local needsFanfare = C_MountJournal.NeedsFanfare(menuMountID);
    if needsFanfare then
        text = UNWRAP;
    elseif active then
        text = BINDING_NAME_DISMOUNT;
    else
        text = MOUNT;
        checkEnabled = true
    end

    local mountButton = rootDescription:CreateButton(text, function()
        if needsFanfare then
            ADDON.Api:SetSelected(menuMountID)
        end
        MountJournalMountButton_UseMount(menuMountID);
    end);

    if checkEnabled then
        mountButton:SetEnabled(isUsable);
    end

    if not needsFanfare then
        local isFavorite, canFavorite = ADDON.Api:GetIsFavoriteByID(menuMountID)
        local button = rootDescription:CreateButton(isFavorite and BATTLE_PET_UNFAVORITE or BATTLE_PET_FAVORITE, function()
            ADDON.Api:SetIsFavoriteByID(menuMountID, not isFavorite)
        end);
        button:SetEnabled(isCollected and canFavorite)
    end

    if spellId then
        if ADDON.settings.hiddenMounts[spellId] then
            rootDescription:CreateButton(SHOW, function()
                ADDON.settings.hiddenMounts[spellId] = nil
                ADDON:FilterMounts()
            end)
        else
            rootDescription:CreateButton(HIDE, function()
                ADDON.settings.hiddenMounts[spellId] = true
                ADDON:FilterMounts()
            end)
        end
    end

    rootDescription:CreateButton(SET_NOTE, function()
        ADDON.UI:CreateNotesFrame(mountId)
    end)
end

function ADDON.UI:HandleListDropDown(sender, relativeTo)
    local anchor = CreateAnchor("TOPLEFT", relativeTo, "BOTTOMLEFT", 0, 5)
    ADDON.UI.OpenContextMenu(sender, anchor, CreateContextMenu, sender.mountID)
end