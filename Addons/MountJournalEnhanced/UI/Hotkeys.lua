local _, ADDON = ...

-- Keyboard Shortcuts:
-- UP: Select Previous Mount
-- DOWN: Select Next Mount
-- HOME: Select first Mount
-- END: Select last Mount

local function FetchCurrentSelectedIndex()
    local target = MountJournal.selectedMountID
    if target then
        return MountJournal.ScrollBox:FindByPredicate(function(element)
            return element.mountID == target
        end)
    end
end

local function JumpTo(index)
    MountJournal.ScrollBox:ScrollToElementDataIndex(index)
    local frame = MountJournal.ScrollBox:FindFrame(MountJournal.ScrollBox:FindElementData(index))
    if frame then
        frame:Click()
    end
end

local function Select(step, totalDisplayed)
    local currentIndex = FetchCurrentSelectedIndex()
    if currentIndex == nil then
        return JumpTo(1)
    end

    local index = currentIndex + step
    if index < 1 then
        JumpTo(1)
    elseif index > totalDisplayed then
        JumpTo(totalDisplayed)
    else
        JumpTo(index)
    end
end

ADDON:RegisterUISetting('enableCursorKeys', true, ADDON.L.SETTING_CURSOR_KEYS)

local function registerHandler()
   -- I had issues handling the input directly at the MountJournal frame. So I'm using the ScrollFrame instead.
   MountJournal.ScrollBox:HookScript("OnKeyDown", function(self, key)
       if InCombatLockdown() then
           return
       end

       local totalDisplayed
       if (key == "DOWN" or key == "UP" or key == "HOME" or key == "END") and ADDON.settings.ui.enableCursorKeys and not IsModifierKeyDown() then
           totalDisplayed = ADDON.Api:GetDataProvider():GetSize()
           if totalDisplayed > 0 then
               if key == "END" then
                   JumpTo(totalDisplayed)
               elseif key == "HOME" then
                   JumpTo(1)
               elseif key == "UP" then
                   Select(-1, totalDisplayed)
               elseif key == "DOWN" then
                   Select(1, totalDisplayed)
               end

               self:SetPropagateKeyboardInput(false)
               return
           end
       end
       self:SetPropagateKeyboardInput(true)
   end)
end

ADDON.Events:RegisterCallback("loadUI", function()
    if InCombatLockdown() then
        ADDON.Events:RegisterFrameEventAndCallback("PLAYER_REGEN_ENABLED", function()
            registerHandler()
            ADDON.Events:UnregisterCallback("PLAYER_REGEN_ENABLED", '')
        end, 'hotkeys')
    else
        registerHandler()
    end
end, "hotkeys")