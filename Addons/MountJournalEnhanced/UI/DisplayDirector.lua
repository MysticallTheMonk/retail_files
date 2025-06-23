local _, ADDON = ...

-- MountJournal.MountDisplay.ModelScene:GetActorByTag("unwrapped"):SetAnimation(X)
--0=idle
--1=dying
--4=walking
--5=running
--6=lying
--13=walking backwards
--17=attack
--18=attack
--38=falling
--39=landing
--41=flying still
--42=flying forward
--94=mountspecial
--118=eat
--618=MountSelfIdle -- for isSelfMount
--636=MountSelfSpecial

local helpTooltip
local animationMenu
local buttons = {}

local function UpdateContainer()
    local activeButtons = 0
    local controlFrame = MountJournal.MountDisplay.ModelScene.ControlFrame
    local hPadding = controlFrame.buttonHorizontalPadding or 0
    local buttonWidth = 0

    local ElvSkin
    if ElvUI then
        local E = unpack(ElvUI)
        ElvSkin = E:GetModule('Skins')
    end
    if controlFrame.IsSkinned then
        hPadding = 1
    end

    for _, button in ipairs(buttons) do
        if button:IsShown() then
            -- ElvUI Mod
            if controlFrame.IsSkinned and not button.IsSkinned and ElvSkin then
                ElvSkin:HandleButton(button)
                button:Size(22)
                button.Icon:SetInside(nil, 2, 2)
            end

            buttonWidth = button:GetWidth()
            if activeButtons == 0 then
                button:SetPoint("LEFT", 0, 0)
            else
                button:SetPoint("LEFT", activeButtons * (buttonWidth + hPadding), 0)
            end
            activeButtons = activeButtons + 1
        end
    end

    controlFrame:SetWidth((activeButtons * (buttonWidth + hPadding)) - hPadding)
end

local function HideOriginalElements()
    local scene = MountJournal.MountDisplay.ModelScene
    if scene.RotateLeftButton then
        scene.RotateLeftButton:Hide()
    end
    if scene.RotateRightButton then
        scene.RotateRightButton:Hide()
    end
    if scene.TogglePlayer then
        scene.TogglePlayer:Hide()
    end
end

local function GetAnimationsOfCurrentMount()
    -- Look into AnimKitSegment for suiting AnimIDs. The ParentAnimKitID should only has 1 segment.
    local animations = {
        ["stand"] = 1,
        ["walk"] = 1132, -- AnimID=4
        ["walk_back"] = 4749, -- AnimID=13
        ["run"] = 603, -- AnimID=5
        ["fly_idle"] = 2015, -- AnimID=548
        ["fly"] = 3146, --AnimID=557
    }
    if ADDON.isClassic then
        animations["walk_back"] = nil
        animations["fly_idle"] = nil
        animations["fly"] = 1273 -- 556
    end

    local mountId = ADDON.Api:GetSelected()
    local _, _, _, _, mountType = C_MountJournal.GetMountInfoExtraByID(mountId)

    if not tContains(ADDON.DB.Type.flying.typeIDs, mountType) then
        animations["fly_idle"] = nil
        animations["fly"] = nil
    end

    return animations
end

local function PlayAnimationByType(type)
    local animations = GetAnimationsOfCurrentMount()
    local actor = MountJournal.MountDisplay.ModelScene:GetActorByTag("unwrapped")
    if actor then
        actor:StopAnimationKit() -- changing animation while an Animationkit runs, cancels new animation afterwards.
        actor:PlayAnimationKit(animations[type] or 1, true)
    end
end

local function SetupModelActor()
    local callback = function()
        PlayAnimationByType(ADDON.settings.ui.displayAnimation)
    end
    ADDON.Events:RegisterCallback("OnUpdateMountDisplay", callback, 'DisplayDirector')
end

local function BuildControlContainer()
    local frame = CreateFrame("Frame", nil, MountJournal.MountDisplay.ModelScene)
    frame:SetSize(32,32)
    frame:SetPoint("BOTTOM", 0, 10)
    frame:SetFrameLevel(500)
    frame:SetAlpha(0.5)
    frame:Hide()
    frame.buttonHorizontalPadding = -6
    frame.UpdateLayout = function()
    end
    frame.GetRotateIncrement = function()
        return 0.05
    end
    frame:SetScript("OnShow", function()
        frame:UpdateLayout()
    end)
    frame:SetScript("OnEnter", function()
        frame:SetAlpha(1)
    end)
    frame:SetScript("OnLeave", function()
        frame:SetAlpha(0.5)
    end)

    MountJournal.MountDisplay.ModelScene.ControlFrame = frame
    MountJournal.MountDisplay.ModelScene:HookScript("OnEnter", function()
        frame:Show()
    end)
    MountJournal.MountDisplay.ModelScene:HookScript("OnLeave", function()
        if not frame:IsMouseOver() then
            frame:Hide()
        end
    end)

    return frame
end

local function InitButton(button, tooltip, tooltipText)
    -- overwrite default tooltip handling (which might cause taint)
    button:SetScript("OnEnter", function()
        button:GetParent():SetAlpha(1);
        helpTooltip:SetOwner(button, "ANCHOR_BOTTOM")
        helpTooltip:SetText(tooltip or button.tooltip, HIGHLIGHT_FONT_COLOR.r, HIGHLIGHT_FONT_COLOR.g, HIGHLIGHT_FONT_COLOR.b)
        if tooltipText or button.tooltipText then
            helpTooltip:AddLine(tooltipText or button.tooltipText, _, _, _, 1, 1)
        end
        helpTooltip:Show()
    end)
    button:SetScript("OnLeave", function()
        button:GetParent():SetAlpha(0.5);
        helpTooltip:Hide()
    end)

    table.insert(buttons, button)
end

local function BuildButton(tooltip, tooltipText)
    local button = CreateFrame("Button", nil, MountJournal.MountDisplay.ModelScene.ControlFrame, "ModelSceneControlButtonTemplate")
    InitButton(button, tooltip, tooltipText)
    button:HookScript("OnMouseDown", function()
        PlaySound(SOUNDKIT.IG_INVENTORY_ROTATE_CHARACTER)
    end)

    return button
end

local function CheckButtonStatus(self)
    self.Icon:ClearAllPoints()
    self.Icon:SetPoint("CENTER")
    if self:GetChecked() then
        self.Icon:AdjustPointsOffset(1, -1);
    end
end

local function BuildCheckButton(tooltip, tooltipText, OnInitShow)
    local button = CreateFrame("CheckButton", nil, MountJournal.MountDisplay.ModelScene.ControlFrame, "ModelSceneControlButtonTemplate")

    button:RegisterForClicks("AnyUp")
    InitButton(button, tooltip, tooltipText)
    button:HookScript("OnShow", OnInitShow)
    button:HookScript("OnShow", CheckButtonStatus)
    button:HookScript("OnClick", CheckButtonStatus)
    button:HookScript("OnMouseDown", function()
        PlaySound(SOUNDKIT.IG_INVENTORY_ROTATE_CHARACTER)
    end)

    return button
end

local function BuildRotateButton(tooltip, icon, direction)
    local button = BuildButton(tooltip, ROTATE_TOOLTIP)
    button.Icon:SetAtlas("common-icon-" .. icon)
    button:HookScript("OnMouseDown", function()
        MountJournal.MountDisplay.ModelScene:AdjustCameraYaw(direction, button:GetParent():GetRotateIncrement())
    end)
    button:HookScript("OnMouseUp", function()
        MountJournal.MountDisplay.ModelScene:StopCameraYaw()
    end)

    return button
end

local function InitializeAnimationDropDown(self, level)
    local animations = GetAnimationsOfCurrentMount()

    local order = {"stand", "walk", "walk_back", "run", "fly_idle", "fly"}
    local labels = {
        ["stand"] = ADDON.L.ANIMATION_STAND,
        ["walk"] = ADDON.L.ANIMATION_WALK,
        ["walk_back"] = ADDON.L.ANIMATION_WALK_BACK,
        ["run"] = ADDON.L.ANIMATION_RUN,
        ["fly_idle"] = ADDON.L.ANIMATION_FLY_IDLE,
        ["fly"] = ADDON.L.ANIMATION_FLY,
    }

    for _, type in ipairs(order) do
        if animations[type] then
            local info = {
                keepShownOnClick = true,
                isNotRadio = false,
                hasArrow = false,
                text = labels[type],
                checked = function()
                    return ADDON.settings.ui.displayAnimation == type
                end,
                func = function()
                    ADDON.settings.ui.displayAnimation = type
                    UIDropDownMenu_Refresh(self, nil, level)
                    PlayAnimationByType(type)
                end,
            }
            UIDropDownMenu_AddButton(info, level)
        end
    end
end

local function BuildCameraPanel()
    local L = ADDON.L

    local container = MountJournal.MountDisplay.ModelScene.ControlFrame or BuildControlContainer()

    helpTooltip = CreateFrame("GameTooltip", "MJEDisplayHelpToolTip", container, "SharedNoHeaderTooltipTemplate")

    container.specialButton = BuildButton("/mountspecial")
    container.specialButton.Icon:SetTexture("Interface/GossipFrame/CampaignGossipIcons") -- from atlas: campaignavailablequesticon
    if nil == container.specialButton.Icon:GetTexture() then
        -- fallback for classic client
        container.specialButton.Icon:SetTexture("Interface/QuestTypeIcons")
        container.specialButton.Icon:SetTexCoord(0, 0.14285714285714285714285714285714, 0.275, 0.575)
    else
        container.specialButton.Icon:SetTexCoord(0.1875, 0.421875, 0.37, 0.85)
    end
    container.specialButton:HookScript("OnClick", function()
        local actor = MountJournal.MountDisplay.ModelScene:GetActorByTag("unwrapped")
        if actor then
            actor:PlayAnimationKit(1371)
            actor:PlayAnimationKit(1371) -- animation gets sometimes canceled. second call is to enforce it.
            ADDON.settings.ui.displayAnimation = "stand" -- back to normal stand
        end
    end)

    -- TODO animation ids don't fit in 4.4
    --if WOW_PROJECT_ID == WOW_PROJECT_MAINLINE then
        container.animationButton = BuildButton(ANIMATION)
        container.animationButton.Icon:SetTexture(516779) -- Interface/HELPFRAME/ReportLagIcon-Movement.blp
        container.animationButton.Icon:SetDesaturated(true)
        container.animationButton.Icon:SetVertexColor(1, 0.8, 0)
        container.animationButton.Icon:SetSize(25,25)
        container.animationButton:HookScript("OnClick", function(sender)
            if animationMenu == nil then
                animationMenu = CreateFrame("Frame", nil, container.animationButton, "UIDropDownMenuTemplate")
                UIDropDownMenu_Initialize(animationMenu, InitializeAnimationDropDown, "MENU")
                animationMenu.point = "BOTTOMLEFT"
                animationMenu.relativePoint = "TOPLEFT"
            end

            ToggleDropDownMenu(1, nil, animationMenu, sender, 0, -7)
        end)
    --end

    if MOUNT_JOURNAL_PLAYER and nil ~= C_CVar.GetCVar("mountJournalShowPlayer") then
        container.togglePlayerButton = BuildCheckButton(MOUNT_JOURNAL_PLAYER, nil, function(self)
            PlayerPreviewToggle.OnShow(self)
        end)
        container.togglePlayerButton.Icon:SetTexture(386865) -- interface/friendsframe/ui-toast-toasticons.blp
        container.togglePlayerButton.Icon:SetTexCoord(0.05, 0.2, 0.6, 0.9)
        container.togglePlayerButton.Icon:SetVertexColor(1, 0.7, 0)
        container.togglePlayerButton:HookScript("OnClick", function(self)
            if self:GetChecked() then
                C_CVar.SetCVar("mountJournalShowPlayer", 1)
            else
                C_CVar.SetCVar("mountJournalShowPlayer", 0)
            end
            MountJournal_UpdateMountDisplay(true)
        end)
    end

    container.cycleColorButton = BuildButton(L.TOGGLE_COLOR)
    container.cycleColorButton.Icon:SetAtlas("colorblind-colorwheel")
    container.cycleColorButton:HookScript("OnClick", function()
        local mountID, mountVariation = ADDON.Api:GetSelected()
        local creatureData = C_MountJournal.GetMountAllCreatureDisplayInfoByID(mountID)
        if nil == mountVariation then
            local creatureDisplayID = C_MountJournal.GetMountInfoExtraByID(mountID)
            for i, d in ipairs(creatureData) do
                if d.creatureDisplayID == creatureDisplayID then
                    mountVariation = i
                    break
                end
            end
        end
        mountVariation = mountVariation or 1

        if #creatureData >= mountVariation + 1 then
            ADDON.Api:SetSelected(mountID, mountVariation + 1)
        else
            ADDON.Api:SetSelected(mountID, 1)
        end
    end)

    if container.zoomInButton then
        InitButton(container.zoomInButton)
    else
        container.zoomInButton = BuildButton(ZOOM_IN, KEY_MOUSEWHEELUP)
        container.zoomInButton.Icon:SetAtlas("common-icon-zoomin")
        container.zoomInButton:HookScript("OnClick", function()
            MountJournal.MountDisplay.ModelScene:OnMouseWheel(1)
        end)
    end

    if container.zoomOutButton then
        InitButton(container.zoomOutButton)
    else
        container.zoomOutButton = BuildButton(ZOOM_OUT, KEY_MOUSEWHEELDOWN)
        container.zoomOutButton.Icon:SetAtlas("common-icon-zoomout")
        container.zoomOutButton:HookScript("OnClick", function()
            MountJournal.MountDisplay.ModelScene:OnMouseWheel(-1)
        end)
    end

    container.toggleAutoRotateButton = BuildCheckButton(ADDON.L.AUTO_ROTATE, nil, function(self)
        self:SetChecked(ADDON.settings.ui.autoRotateModel)
    end)
    container.toggleAutoRotateButton.Icon:SetTexture("Interface\\Addons\\MountJournalEnhanced\\UI\\icons\\rotate.png") -- icon could need some work :-/
    container.toggleAutoRotateButton:HookScript("OnClick", function(self)
        ADDON.settings.ui.autoRotateModel = self:GetChecked()
    end)

    if container.rotateLeftButton then
        InitButton(container.rotateLeftButton)
    else
        container.rotateLeftButton = BuildRotateButton(ROTATE_LEFT, "rotateleft", "left")
    end
    if container.rotateRightButton then
        InitButton(container.rotateRightButton)
    else
        container.rotateRightButton = BuildRotateButton(ROTATE_RIGHT, "rotateright", "right")
    end

    container.rotateUpButton = BuildRotateButton(L.ROTATE_UP, "rotateleft", "up")
    container.rotateUpButton.Icon:SetRotation(-math.pi / 2)

    container.rotateDownButton = BuildRotateButton(L.ROTATE_DOWN, "rotateright", "down")
    container.rotateDownButton.Icon:SetRotation(-math.pi / 2)

    if container.resetButton then
        InitButton(container.resetButton)
    else
        container.resetButton = BuildButton(RESET_POSITION)
        container.resetButton.Icon:SetAtlas("common-icon-undo")
        container.resetButton:HookScript("OnClick", function()
            local cam = MountJournal.MountDisplay.ModelScene:GetActiveCamera()
            if cam then
                local info = cam.modelSceneCameraInfo
                cam:SetPitch(info.pitch)
                cam:SetYaw(info.yaw)
                cam:SetZoomDistance(info.zoomDistance)
            end
        end)
    end

    container:HookScript("OnShow", UpdateContainer) -- hook at OnShow instead at UpdateLayout so we are running after ElvUI
    UpdateContainer()
end

ADDON.Events:RegisterCallback("loadUI", function()
    HideOriginalElements()
    SetupModelActor()
    BuildCameraPanel()

    -- fix display rotation and adds up and down as possibilities
    MountJournal.MountDisplay.ModelScene:SetScript("OnUpdate", function(self, elapsed)
        if self.activeCamera then
            local yawDirection = self.yawDirection;
            local increment = self.increment;
            if yawDirection == "left" then
                self.activeCamera:AdjustYaw(-1, 0, increment);
            elseif yawDirection == "right" then
                self.activeCamera:AdjustYaw(1, 0, increment);
            elseif yawDirection == "up" then
                self.activeCamera:AdjustYaw(0, -1, increment);
            elseif yawDirection == "down" then
                self.activeCamera:AdjustYaw(0, 1, increment);
            end

            self.activeCamera:OnUpdate(elapsed);
        end
    end);

    MountJournal.MountDisplay.ModelScene:HookScript("OnUpdate", function(self, elapsed)
        if ADDON.settings.ui.autoRotateModel then
            self:GetActiveCamera():HandleMouseMovement(ORBIT_CAMERA_MOUSE_MODE_YAW_ROTATION, elapsed * -0.8, false)
        end
    end);
end, "display director")

local function updateVisibility()
    local mountID = ADDON.Api:GetSelected()
    if mountID then
        local controlFrame = MountJournal.MountDisplay.ModelScene.ControlFrame
        if controlFrame.togglePlayerButton then
            local _, _, _, isSelfMount = C_MountJournal.GetMountInfoExtraByID(mountID)
            controlFrame.togglePlayerButton:SetShown(not isSelfMount)
        end
        if controlFrame.cycleColorButton then
            local creatureData = C_MountJournal.GetMountAllCreatureDisplayInfoByID(mountID)
            controlFrame.cycleColorButton:SetShown(#creatureData > 1)
        end
        if controlFrame.rotateUpButton and controlFrame.rotateDownButton then
            controlFrame.rotateUpButton:SetShown(ADDON.settings.ui.unlockDisplayCamera)
            controlFrame.rotateDownButton:SetShown(ADDON.settings.ui.unlockDisplayCamera)
        end

        UpdateContainer()
    end
end

ADDON.Events:RegisterCallback("OnUpdateMountDisplay", function()
    if #buttons < 3 then
        -- might be just bad timing, so lets delay by a frame to be sure
        C_Timer.After(0, updateVisibility)
    else
        updateVisibility()
    end
end, "display director")