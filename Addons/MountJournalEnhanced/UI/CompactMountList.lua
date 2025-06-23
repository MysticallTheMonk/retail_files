local ADDON_NAME, ADDON = ...

local MOUNT_BUTTON_HEIGHT = 29

local function SaveButtonLayout(button)
    ADDON.UI:SavePoint(button)
    ADDON.UI:SaveSize(button)
    ADDON.UI:SaveSize(button.DragButton)
    ADDON.UI:SaveSize(button.icon)
    ADDON.UI:SavePoint(button.icon)
    ADDON.UI:SavePoint(button.name)
    ADDON.UI:SavePoint(button.new)
    ADDON.UI:SavePoint(button.factionIcon)
end
local function RestoreButtonLayout(button)
    ADDON.UI:RestoreSize(button)
    ADDON.UI:RestorePoint(button)
    ADDON.UI:RestorePoint(button.icon)
    ADDON.UI:RestoreSize(button.icon)
    ADDON.UI:RestoreSize(button.DragButton)
    ADDON.UI:RestorePoint(button.name)
    ADDON.UI:RestorePoint(button.new)
    ADDON.UI:RestorePoint(button.factionIcon)
end

local function ModifyButton(button)
    button:SetHeight(MOUNT_BUTTON_HEIGHT)
    button.DragButton:SetSize(MOUNT_BUTTON_HEIGHT, MOUNT_BUTTON_HEIGHT)
    button.icon:SetSize(MOUNT_BUTTON_HEIGHT, MOUNT_BUTTON_HEIGHT)
    button.icon:ClearAllPoints()
    button.icon:SetPoint("RIGHT", button, "LEFT", -2, 0)

    if button.IsSkinned then
        -- ElvUI customization
        button.icon:SetSize(MOUNT_BUTTON_HEIGHT - 2, MOUNT_BUTTON_HEIGHT - 2)
    end

    button.name:SetPoint("LEFT", button, "LEFT", 10, 1)
    button.name:SetPoint("RIGHT", button, "RIGHT", -10, 1)

    button.new:ClearAllPoints()
    button.new:SetPoint("CENTER", button.DragButton)

    button.factionIcon:ClearAllPoints()
    button.factionIcon:SetPoint('TOPRIGHT', -2, -2)
    button.factionIcon:SetPoint('TOPLEFT', button, "TOPRIGHT", 2 - MOUNT_BUTTON_HEIGHT, -2)
    button.factionIcon:SetPoint('BOTTOMRIGHT', -2, 2)
end

local function UpdateButton(button, elementData)
    if ADDON.settings.ui.compactMountList then
        local mountID = elementData.mountID
        local isSteadyFlight = select(13, ADDON.Api:GetMountInfoByID(mountID))

        if button.name:GetNumLines() > 1 then
            -- name region might have been stretched in height before. so we reset it's size here.
            local text = button.name:GetText()
            button.name:SetText("")
            button.name:SetSize(button:GetWidth() - 20, 0)
            button.name:SetText(text)
        end

        local yOffset = 1;
        if isSteadyFlight then
            if button.name:GetNumLines() == 1 then
                yOffset = 6;
            else
                yOffset = 5;
            end
        end
        button.name:SetPoint("LEFT", button, "LEFT", 10, yOffset)
        button.name:SetPoint("RIGHT", button, "RIGHT", -10, yOffset)
    end
end

ADDON:RegisterUISetting('compactMountList', true, ADDON.L.SETTING_COMPACT_LIST, function(flag)
    if ADDON.initialized then
        local box = MountJournal.ScrollBox
        local view = box:GetView()
        if flag then
            box:ForEachFrame(function(button, elementData)
                SaveButtonLayout(button)
                ModifyButton(button)
                UpdateButton(button, elementData)
            end)
            local owner = ADDON_NAME .. 'compact'
            ScrollUtil.AddAcquiredFrameCallback(box, function(_, button, _, new)
                if new then
                    SaveButtonLayout(button)
                end
                if ADDON.settings.ui.compactMountList then
                    ModifyButton(button)
                else
                    RestoreButtonLayout(button)
                end
            end, owner)
            ScrollUtil.AddReleasedFrameCallback(box, function(_, button)
                RestoreButtonLayout(button)
            end, owner)
            view:SetPadding(0, 0, MOUNT_BUTTON_HEIGHT + 2, 0, 0)
            view:SetElementExtent(MOUNT_BUTTON_HEIGHT)
        else
            box:UnregisterCallback(ScrollBoxListMixin.Event.OnAcquiredFrame, ADDON_NAME .. 'compact')
            box:UnregisterCallback(ScrollBoxListMixin.Event.OnReleasedFrame, ADDON_NAME .. 'compact')
            box:ForEachFrame(function(button)
                RestoreButtonLayout(button)
            end)
            view:SetPadding(0, 0, 44, 0, 0)
            view:SetElementExtent(46)
        end
        box:FullUpdate(false)
        view:Layout()
    end
end)

ADDON.Events:RegisterCallback("loadUI", function()
    ADDON:ApplySetting('compactMountList', ADDON.settings.ui.compactMountList)

    -- MountJournal_InitMountButton() is also called directly within MountJournal_SetSelected().
    -- So we can't just use a scrollbox event.
    hooksecurefunc("MountJournal_InitMountButton", UpdateButton)
end, "compact")