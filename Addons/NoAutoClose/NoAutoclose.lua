local addonName, ns = ...;

--- @type { [ string ] : { checkFit: boolean, checkFitExtraWidth: number, checkFitExtraHeight: number } }
ns.hookedFrames = {};
ns.ignore = {
    BarberShopFrame = true, -- barbershop frame, better to allow it to hide the UI
    CinematicFrame = true, -- cinematic frame, better to allow it to hide the UI
    CommunitiesFrame = true,
    MacroFrame = true,
    PerksProgramFrame = true, -- trading post frame, better to allow it to hide the UI
    TokenFrame = true, -- breaks baganator's currency transfer, ignoring it doesn't impact things otherwise
    WarboardQuestChoiceFrame = true,
};
local uiSpecialFrameBlacklist = {
    PlayerSpellsFrame = true, -- cannot be safely closed with UISpecialFrames
};
NoAutoClose = ns;

local UpdateScaleForFit = UpdateScaleForFit or UIPanelUpdateScaleForFit or FrameUtil.UpdateScaleForFit;

local CHECK_FIT_DEFAULT_EXTRA_WIDTH = 20;
local CHECK_FIT_DEFAULT_EXTRA_HEIGHT = 20;

local function table_invert(t)
    local s = {};
    for k,v in pairs(t) do
        s[v] = k;
    end

    return s;
end

local function setTrue(table, key)
    TextureLoadingGroupMixin.AddTexture({textures = table}, key);
end

local function setNil(table, key)
    TextureLoadingGroupMixin.RemoveTexture({textures = table}, key);
end

EventUtil.ContinueOnAddOnLoaded(addonName, function()
    ns:Init();
end);

ns.escHandlerMap = {};
ns.handlerFrameIndex = 0;
ns.sharedAttributesFrame = CreateFrame('Frame', nil, nil, 'SecureHandlerBaseTemplate');

function ns:ShouldNotManuallyShowHide(frame, interfaceActionWasBlocked)
    local name = frame.GetName and frame:GetName();
    if
        (
            frame == WorldMapFrame and C_AddOns.IsAddOnLoaded('Carbonite')
            and Nx and Nx.db and Nx.db.profile and Nx.db.profile.Map and Nx.db.profile.Map.MaxOverride
        )
        or (uiSpecialFrameBlacklist[name])
    then
        return true;
    end

    return not interfaceActionWasBlocked;
end

function ns:OnDisplayInterfaceActionBlockedMessage()
    if InCombatLockdown() and (debugstack(3):find('in function .ShowUIPanel.') or debugstack(3):find('in function .HideUIPanel.')) then
        self.interfaceActionWasBlocked = true;
    end
end

function ns:SetDefaultPosition(frame)
    if
        (frame.IsForbidden and frame:IsForbidden())
        or (frame.IsProtected and frame:IsProtected() and InCombatLockdown())
    then
        return;
    end
    frame:ClearAllPoints();
    (frame.SetPointBase or frame.SetPoint)(
        frame,
        self.db.defaultPosition.anchor,
        UIParent,
        self.db.defaultPosition.anchor,
        self.db.defaultPosition.x,
        self.db.defaultPosition.y
    );
end

function ns:OnShowUIPanel(frame)
    local interfaceActionWasBlocked = self.interfaceActionWasBlocked;
    self.interfaceActionWasBlocked = false;
    if not frame or (frame.IsForbidden and frame:IsForbidden()) then return; end
    local name = frame.GetName and frame:GetName();
    local isHooked = self.hookedFrames[name];
    if not isHooked and frame.IsProtected and frame:IsProtected() and InCombatLockdown() then return; end

    if isHooked and ((frame.IsProtected and frame:IsProtected()) or uiSpecialFrameBlacklist[name]) then
        -- ensure that we have a secure esc handler configured for this frame
        if InCombatLockdown() then
            self:AddToCombatLockdownQueue(self.ConfigureSecureEscHandler, ns, frame);
            return; -- don't do anything else while we're in combat
        end
        self:ConfigureSecureEscHandler(frame, uiSpecialFrameBlacklist[name]);
    end

    if (frame.IsShown and not frame:IsShown()) then
        if self:ShouldNotManuallyShowHide(frame, interfaceActionWasBlocked) then return; end
        -- if possible, force show the frame, ignoring the INTERFACE_ACTION_BLOCKED message
        frame:Show();
    end
    if isHooked then
        if (frame.GetPoint and not frame:GetPoint()) then
            -- disabling the UIPanelLayout system removes the default location, so let's set one
            self:SetDefaultPosition(frame);
        end
        if (frame.IsToplevel and frame:IsToplevel() and frame.IsShown and frame:IsShown()) then
            -- if the frame is a toplevel frame, raise it to the top of the stack
            frame:Raise();
        end
        if isHooked.checkFit then
            UpdateScaleForFit(frame, isHooked.checkFitExtraWidth, isHooked.checkFitExtraHeight);
        end
    end
end

function ns:OnHideUIPanel(frame)
    local interfaceActionWasBlocked = self.interfaceActionWasBlocked;
    self.interfaceActionWasBlocked = false;
    if (not frame or (InCombatLockdown() and frame:IsProtected())) then
        return; -- can't touch this frame in combat :(
    end
    if (frame.IsShown and frame:IsShown()) then
        if self:ShouldNotManuallyShowHide(frame, interfaceActionWasBlocked) then return; end
        -- if possible, force hide the frame, ignoring the INTERFACE_ACTION_BLOCKED message
        frame:Hide();
    end
end

function ns:ReworkSettingsOpenAndClose()
    if not SettingsPanel then return; end

    -- this prevents closing the settings panel from cancelling spell casting (and therefore giving a taint error when any addon is registered)
    if SettingsPanel.TransitionBackOpeningPanel then
        function SettingsPanel:TransitionBackOpeningPanel()
            HideUIPanel(SettingsPanel);
        end
    end
    -- this closes the game menu when opening the settings ui, which makes it less buggy when pressing escape to close the settings UI
    local settingsButton = GameMenuButtonSettings or GameMenuButtonOptions;
    if settingsButton then
        settingsButton:HookScript('OnClick', function()
            if GameMenuFrame and GameMenuFrame:IsShown() then
                HideUIPanel(GameMenuFrame);
            end
        end);
    end
end

function ns:HandleUIPanel(name, info, flippedUiSpecialFrames)
    local frame = _G[name];
    if not frame or self.ignore[name] then return; end
    if ((frame.IsProtected and frame:IsProtected()) or uiSpecialFrameBlacklist[name]) then
        if InCombatLockdown() then
            self:AddToCombatLockdownQueue(ns.HandleUIPanel, ns, name, info, flippedUiSpecialFrames);
            return;
        end

        self:ConfigureSecureEscHandler(frame, uiSpecialFrameBlacklist[name]);
    end
    if (not flippedUiSpecialFrames[name] and not uiSpecialFrameBlacklist[name]) then
        flippedUiSpecialFrames[name] = true;
        tinsert(UISpecialFrames, name);
    end
    self.hookedFrames[name] = {
        checkFit = UIPanelWindows[name] and UIPanelWindows[name].checkFit,
        checkFitExtraWidth = UIPanelWindows[name] and UIPanelWindows[name].checkFitExtraWidth or CHECK_FIT_DEFAULT_EXTRA_WIDTH,
        checkFitExtraHeight = UIPanelWindows[name] and UIPanelWindows[name].checkFitExtraHeight or CHECK_FIT_DEFAULT_EXTRA_HEIGHT,
    };
    setNil(UIPanelWindows, name);
    if frame.SetAttribute then
        frame:SetAttribute('UIPanelLayout-defined', nil);
        frame:SetAttribute('UIPanelLayout-enabled', nil);
        frame:SetAttribute('UIPanelLayout-area', nil);
        frame:SetAttribute('UIPanelLayout-pushable', nil);
        frame:SetAttribute('UIPanelLayout-whileDead', nil);
    end
    if (frame.GetPoint and not frame:GetPoint()) then
        -- disabling the UIPanelLayout system removes the default location, so let's set one
        self:SetDefaultPosition(frame);
    end
end

--- @param func function
--- @param ... any # arguments
function ns:AddToCombatLockdownQueue(func, ...)
    if #self.combatLockdownQueue == 0 then
        self.eventFrame:RegisterEvent('PLAYER_REGEN_ENABLED');
    end

    tinsert(self.combatLockdownQueue, { func = func, args = { ... } });
end

function ns:PLAYER_REGEN_ENABLED()
    self.eventFrame:UnregisterEvent('PLAYER_REGEN_ENABLED');
    if #self.combatLockdownQueue == 0 then return; end

    for _, item in pairs(self.combatLockdownQueue) do
        item.func(unpack(item.args));
    end
    wipe(self.combatLockdownQueue);
end

function ns:PLAYER_REGEN_DISABLED()
    -- if any frame has become protected since it was last shown, we need to configure the secure esc handler
    --
    for frameName, _ in pairs(self.hookedFrames) do
        local frame = _G[frameName];
        if frame and frame.IsProtected and frame:IsProtected() then
            if not self.escHandlerMap[frame] then
                self:ConfigureSecureEscHandler(frame, false, true);
            end
        end
    end
end

local function escHandlerOnEvent(handlerFrame, event)
    if event == 'PLAYER_REGEN_ENABLED' and not handlerFrame:GetAttribute('alwaysSetBindingOnShow') then
        ClearOverrideBindings(handlerFrame);
    elseif event == 'PLAYER_REGEN_DISABLED' and handlerFrame.panel:IsVisible() then
        SetOverrideBindingClick(handlerFrame, true, 'ESCAPE', handlerFrame.name);
    end
end

--- @param frame Frame
--- @param alwaysSetBindingOnShow boolean # if true, the ESC binding will always be set when the frame is shown, regardless of combat state
--- @param callRegenDisabledCode boolean? # if true, the PLAYER_REGEN_DISABLED event will be called immediately
function ns:ConfigureSecureEscHandler(frame, alwaysSetBindingOnShow, callRegenDisabledCode)
    --[[
        Since the UIPanel system no longer taintlessly hides protected panels, we need to create a secure handler, which will
        configure a temporary keybinding for ESC, to hide the panel. Once we leave combat, we unbind it again, to go back to normal.
        The downside of this approach, is that protected frames will close 1 by 1, and that hiding the frames takes priority over e.g. canceling spell casting.
    --]]
    if self.escHandlerMap[frame] then return; end

    self.handlerFrameIndex = self.handlerFrameIndex + 1;
    local name = 'Numy_NoAutoClose_SecureEscapeHandlerFrame' .. self.handlerFrameIndex;
    local escHandler = CreateFrame('Button', name, frame, 'SecureHandlerShowHideTemplate,SecureHandlerClickTemplate');
    self.escHandlerMap[frame] = escHandler;

    escHandler.name = name;
    escHandler.panel = frame;
    escHandler:SetFrameRef('panel', frame);
    escHandler:SetFrameRef('UIParent', UIParent);
    escHandler:SetFrameRef('sharedAttributesFrame', self.sharedAttributesFrame);
    escHandler:RegisterEvent('PLAYER_REGEN_ENABLED');
    escHandler:RegisterEvent('PLAYER_REGEN_DISABLED');
    escHandler:HookScript('OnEvent', escHandlerOnEvent);
    escHandler:SetAttribute('alwaysSetBindingOnShow', alwaysSetBindingOnShow);
    escHandler:SetAttribute('_onclick', [[
        self:ClearBindings(); -- clear the bindings, just in case something is preventing the _onhide from firing
        local panel = self:GetFrameRef('panel');
        if panel:IsShown() then
            panel:Hide();
        end
    ]]);
    escHandler:SetAttribute('_onhide', [[
        self:ClearBindings();
    ]]);
    escHandler:SetAttribute('_onshow', [[
        local alwaysSetBindingOnShow = self:GetAttribute('alwaysSetBindingOnShow');
        if alwaysSetBindingOnShow or PlayerInCombat() then
            self:SetBindingClick(true, 'ESCAPE', self);
            local panel = self:GetFrameRef('panel');
            panel:Raise();
            if (not panel:GetPoint()) then
                -- disabling the UIPanelLayout system removes the default location, so let's set one
                local UIParent = self:GetFrameRef('UIParent');
                local sharedAttributesFrame = self:GetFrameRef('sharedAttributesFrame');
                local anchor, ofsx, ofsy = sharedAttributesFrame:GetAttribute('anchor'), sharedAttributesFrame:GetAttribute('x'), sharedAttributesFrame:GetAttribute('y');
                panel:SetPoint(anchor, UIParent, anchor, ofsx, ofsy);
            end
        end
    ]]);
    if callRegenDisabledCode then
        escHandlerOnEvent(escHandler, 'PLAYER_REGEN_DISABLED');
    end
end

function ns:ADDON_LOADED()
    local flippedUiSpecialFrames = table_invert(UISpecialFrames);

    for name, info in pairs(UIPanelWindows) do
        self:HandleUIPanel(name, info, flippedUiSpecialFrames);
    end
    if InCombatLockdown() and WorldMapFrame:IsProtected() then
        self:AddToCombatLockdownQueue(function()
            WorldMapFrame:SetAttribute('UIPanelLayout-defined', '1');
            WorldMapFrame:SetAttribute('UIPanelLayout-maximizePoint', 'TOP');
        end);
    else
        WorldMapFrame:SetAttribute('UIPanelLayout-defined', '1');
        WorldMapFrame:SetAttribute('UIPanelLayout-maximizePoint', 'TOP');
    end
end

ns.playerInteractionHideMap = {
    [Enum.PlayerInteractionType.Gossip] = 'GossipFrame',
    [Enum.PlayerInteractionType.QuestGiver] = 'QuestFrame',
};

function ns:PLAYER_INTERACTION_MANAGER_FRAME_SHOW(_, type)
    for mapType, frameName in pairs(self.playerInteractionHideMap) do
        local frame = _G[frameName];
        if type ~= mapType and frame.IsShown and frame:IsShown() then
            HideUIPanel(_G[frameName]);
        end
    end
end

function ns:PLAYER_INTERACTION_MANAGER_FRAME_HIDE(_, type)
    if self.playerInteractionHideMap[type] then
        local frame = _G[self.playerInteractionHideMap[type]];
        if frame and frame.IsShown and frame:IsShown() then
            HideUIPanel(frame);
        end
    end
end

function ns:Init()
    hooksecurefunc('ShowUIPanel', function(frame) self:OnShowUIPanel(frame); end);
    hooksecurefunc('HideUIPanel', function(frame) self:OnHideUIPanel(frame); end);
    hooksecurefunc('RegisterUIPanel', function() self:ADDON_LOADED(); end);
    hooksecurefunc('DisplayInterfaceActionBlockedMessage', function() self:OnDisplayInterfaceActionBlockedMessage(); end);
    hooksecurefunc('RestoreUIPanelArea', function(frame) self:SetDefaultPosition(frame); end);
    self:ReworkSettingsOpenAndClose();

    self.eventFrame = CreateFrame('Frame');
    self.eventFrame:HookScript('OnEvent', function(_, event, ...) self[event](self, event, ...); end);
    self.eventFrame:RegisterEvent('ADDON_LOADED');
    self.eventFrame:RegisterEvent('PLAYER_INTERACTION_MANAGER_FRAME_SHOW');
    self.eventFrame:RegisterEvent('PLAYER_INTERACTION_MANAGER_FRAME_HIDE');
    self.eventFrame:RegisterEvent('PLAYER_REGEN_DISABLED');

    self.combatLockdownQueue = {};

    self:initOptions()
end

function ns:initOptions()
    NoAutoCloseDB = NoAutoCloseDB or {};
    self.db = NoAutoCloseDB;
    local defaults = {
        defaultPosition = {
            anchor = 'TOPLEFT',
            x = 50,
            y = -50,
        },
    };
    for k, v in pairs(defaults) do
        if self.db[k] == nil then
            self.db[k] = v;
        end
    end
    local function updatePositionAttributes(anchor, x, y)
        self.sharedAttributesFrame:SetAttribute('anchor', anchor);
        self.sharedAttributesFrame:SetAttribute('x', x);
        self.sharedAttributesFrame:SetAttribute('y', y);
    end

    local panel = CreateFrame('Frame');
    panel.name = 'NoAutoClose';

    local title = panel:CreateFontString('ARTWORK', nil, 'GameFontNormalLarge');
    title:SetPoint('TOPLEFT', 10, -15);
    title:SetText('No Auto Close');

    local defaultPositionHeader = panel:CreateFontString('ARTWORK', nil, 'GameFontNormal');
    defaultPositionHeader:SetPoint('TOPLEFT', title, 'BOTTOMLEFT', 0, -15);
    defaultPositionHeader:SetText('Default Position');

    local defaultPositionDescription = panel:CreateFontString('ARTWORK', nil, 'GameFontHighlight');
    defaultPositionDescription:SetPoint('TOPLEFT', defaultPositionHeader, 'BOTTOMLEFT', 5, -5);
    defaultPositionDescription:SetText('Set the default position for panels that are handled by NoAutoClose.');

    local currentDefaultPosition = panel:CreateFontString('ARTWORK', nil, 'GameFontHighlight');
    currentDefaultPosition:SetPoint('TOPLEFT', defaultPositionDescription, 'BOTTOMLEFT', 0, -5);
    local function updatePositionText()
        currentDefaultPosition:SetText(('Current default position: %s (%.2f, %.2f)'):format(self.db.defaultPosition.anchor, self.db.defaultPosition.x, self.db.defaultPosition.y));
    end
    updatePositionText();
    local moverFrame = self:GetMoverFrame(function(anchor, x, y)
        self.db.defaultPosition.anchor = anchor;
        self.db.defaultPosition.x = x;
        self.db.defaultPosition.y = y;
        updatePositionText();
        if InCombatLockdown() then
            self:AddToCombatLockdownQueue(updatePositionAttributes, anchor, x, y);
        else
            updatePositionAttributes(anchor, x, y);
        end
    end);
    panel:SetScript('OnHide', function() moverFrame:Hide(); end);

    local showMoverButton = CreateFrame('Button', nil, panel, 'UIPanelButtonTemplate');
    showMoverButton:SetPoint('TOPLEFT', currentDefaultPosition, 'BOTTOMLEFT', 0, -5);
    showMoverButton:SetSize(150, 25);
    showMoverButton:SetText('Move default position');
    showMoverButton:SetScript('OnClick', function()
        moverFrame:SetShown(not moverFrame:IsShown());
    end);
    -- todo: add a dropdown for the anchor, and number inputs for x and y

    local resetToDefaultButton = CreateFrame('Button', nil, panel, 'UIPanelButtonTemplate');
    resetToDefaultButton:SetPoint('TOPLEFT', showMoverButton, 'BOTTOMLEFT', 0, -5);
    resetToDefaultButton:SetSize(150, 25);
    resetToDefaultButton:SetText('Reset to default');
    resetToDefaultButton:SetScript('OnClick', function()
        self.db.defaultPosition = defaults.defaultPosition;
        updatePositionText();
        moverFrame:ClearAllPoints();
        moverFrame:SetPoint(self.db.defaultPosition.anchor, self.db.defaultPosition.x, self.db.defaultPosition.y);
    end);

    local category, _ = Settings.RegisterCanvasLayoutCategory(panel, panel.name);
    category.ID = panel.name;
    Settings.RegisterAddOnCategory(category);

    SLASH_NOAUTOCLOSE1 = '/noautoclose';
    SLASH_NOAUTOCLOSE2 = '/nac';
    SlashCmdList['NOAUTOCLOSE'] = function() Settings.OpenToCategory(panel.name); end;
end

function ns:GetMoverFrame(onMoveCallback)
    local NineSliceLayout =
    {
        ["TopRightCorner"] = { atlas = "%s-NineSlice-Corner", mirrorLayout = true, x=8, y=8 },
        ["TopLeftCorner"] = { atlas = "%s-NineSlice-Corner", mirrorLayout = true, x=-8, y=8 },
        ["BottomLeftCorner"] = { atlas = "%s-NineSlice-Corner", mirrorLayout = true, x=-8, y=-8 },
        ["BottomRightCorner"] = { atlas = "%s-NineSlice-Corner",  mirrorLayout = true, x=8, y=-8 },
        ["TopEdge"] = { atlas = "_%s-NineSlice-EdgeTop" },
        ["BottomEdge"] = { atlas = "_%s-NineSlice-EdgeBottom" },
        ["LeftEdge"] = { atlas = "!%s-NineSlice-EdgeLeft" },
        ["RightEdge"] = { atlas = "!%s-NineSlice-EdgeRight" },
        ["Center"] = { atlas = "%s-NineSlice-Center", x = -8, y = 8, x1 = 8, y1 = -8, },
    };

    local frame = CreateFrame('Frame', 'NoAutoCloseMoverFrame', UIParent);
    frame:SetSize(150, 100);
    frame:SetPoint(self.db.defaultPosition.anchor, self.db.defaultPosition.x, self.db.defaultPosition.y);
    frame:SetFrameStrata('DIALOG');
    frame:SetFrameLevel(9990);
    frame.layoutType = 'UniqueCornersLayout';
    frame.layoutTextureKit = 'OptionsFrame';
    NineSliceUtil.ApplyLayout(frame, NineSliceLayout, 'editmode-actionbar-highlight');

    local closeButton = CreateFrame('Button', nil, frame, 'UIPanelCloseButton');
    closeButton:SetFrameStrata('DIALOG')
    closeButton:SetFrameLevel(9999);
    closeButton:SetPoint('TOPRIGHT', frame, 'TOPRIGHT', 0, 0);
    closeButton:SetScript('OnClick', function()
        frame:Hide();
    end);

    local label = frame:CreateFontString(nil, 'OVERLAY', 'GameFontHighlightSmall');
    label:SetAllPoints();
    label:SetIgnoreParentScale(true);
    label:SetJustifyH('CENTER');
    label:SetJustifyV('MIDDLE');
    label:SetText('NoAutoClose');

    frame.onMoveCallback = onMoveCallback;
    frame:SetMovable(true);
    frame:SetScript('OnMouseDown', function()
        frame:StartMoving();
    end);
    frame:SetScript('OnMouseUp', function()
        frame:StopMovingOrSizing();
        frame:SetUserPlaced(false);
        local anchor, _, _, x, y = frame:GetPoint();
        frame.onMoveCallback(anchor, x, y);
    end);
    frame:Hide();

    return frame;
end
