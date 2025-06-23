local _, NS = ...
local Panel = NS.Panel
local Widgets = NS.Widgets
local L = NS.L

local Dropdown = LibStub("WardzConfigDropdown-1.0")

local zones = {
    [L.ZONE_ARENA] = "arena", -- localized name, instanceType
    [L.ZONE_BATTLEGROUNDS] = "pvp",
    [L.ZONE_OUTDOORS] = "none",
    [L.ZONE_SCENARIO] = "scenario",
    [L.ZONE_DUNGEONS] = "party",
    [L.ZONE_RAIDS] = "raid",
}

local growDirections = {
    { value = "TOP", text = L.GROW_TOP },
    { value = "BOTTOM", text = L.GROW_BOTTOM },
    { value = "LEFT", text = L.GROW_LEFT },
    { value = "RIGHT", text = L.GROW_RIGHT },
}

local function Refresh(self)
    local frames = self.frames
    local unit = self.unitID
    local unitFrameSettings = DIMINISH_NS.db.unitFrames[unit]

    if not unitFrameSettings.enabled then
        frames.enabled.labelText:SetTextColor(1, 0, 0, 1)
        frames.testBtn:Disable()
    else
        frames.enabled.labelText:SetTextColor(1, 1, 1, 1)
        frames.testBtn:Enable()
    end

    Widgets:RefreshWidgets(unitFrameSettings, self)

    if unit == "player" then
        if unitFrameSettings.usePersonalNameplate then
            frames.unlockBtn:Hide()
            frames.offsetX:Show()
            frames.offsetY:Show()
        else
            frames.unlockBtn:Show()
            frames.offsetX:Hide()
            frames.offsetY:Hide()
        end
    end

    -- Refresh
    for k, category in pairs(DIMINISH_NS.CATEGORIES) do
        if frames.categories[k] then
            frames.categories[k]:SetChecked(not unitFrameSettings.disabledCategories[category])
        end
    end

    -- Refresh zones
    if frames.zones then
        for label, instance in pairs(zones) do
            if frames.zones[label] then
                if type(instance) == "table" then
                    -- all values here are always the same so just set to index 1
                    frames.zones[label]:SetChecked(unitFrameSettings.zones[instance[1]])
                else
                    frames.zones[label]:SetChecked(unitFrameSettings.zones[instance])
                end
            end
        end

        -- Toggle widgets for taunt/zone dungeon depending on if PvE mode is enabled
        if DIMINISH_NS.db.trackNPCs then
            if frames.zones[L.ZONE_DUNGEONS] and frames.zones[L.ZONE_RAIDS] then
                frames.zones[L.ZONE_DUNGEONS]:Enable()
                frames.zones[L.ZONE_RAIDS]:Enable()
            end
            if frames.categories.TAUNT then
                frames.categories.TAUNT:Enable()
            end
        else
            if frames.zones[L.ZONE_DUNGEONS] and frames.zones[L.ZONE_RAIDS] then
                frames.zones[L.ZONE_DUNGEONS]:Disable()
                frames.zones[L.ZONE_RAIDS]:Disable()
            end
            if frames.categories.TAUNT then
                frames.categories.TAUNT:Disable()
            end
        end
    end
end

for unitFrame, unit in pairs(NS.unitFrames) do
    Panel:CreateChildPanel(unitFrame, function(panel)
        Widgets:CreateHeader(panel, unitFrame, false, format(L.HEADER_UNITFRAME, unitFrame))
        panel.unitID = unit
        panel.refresh = Refresh

        local frames = panel.frames
        local db = NS.GetDBProxy("unitFrames", unit)

        local subVisuals = Widgets:CreateSubHeader(panel, L.HEADER_ICONS)
        subVisuals:SetPoint("TOPLEFT", 16, -50)


        frames.enabled = Widgets:CreateCheckbox(panel, L.ENABLED, L.ENABLED_TOOLTIP, function()
            db.enabled = not db.enabled
            if not db.enabled then
                frames.enabled.labelText:SetTextColor(1, 0, 0, 1)
                frames.testBtn:Disable()
            else
                frames.enabled.labelText:SetTextColor(1 ,1, 1, 1)
                frames.testBtn:Enable()
            end

            DIMINISH_NS.Diminish:ToggleForZone()
        end)
        frames.enabled:SetPoint("LEFT", subVisuals, 10, -70)

        if unit == "target" or unit == "focus" or unit == "nameplate" then
            frames.watchFriendly = Widgets:CreateCheckbox(panel, L.WATCHFRIENDLY, L.WATCHFRIENDLY_TOOLTIP, function()
                db.watchFriendly = not db.watchFriendly
                DIMINISH_NS.Diminish:ToggleForZone()
            end)
            frames.watchFriendly:SetPoint("LEFT", frames.enabled, 0, -40)
        end


        if unit ~= "nameplate" then
            frames.anchorUIParent = Widgets:CreateCheckbox(panel, L.ANCHORUIPARENT, L.ANCHORUIPARENT_TOOLTIP, function()
                db.anchorUIParent = not db.anchorUIParent

                if db.usePersonalNameplate and db.anchorUIParent then
                    db.usePersonalNameplate = false
                    frames.usePersonalNameplate:SetChecked(false)
                end

                DIMINISH_NS.Icons:CreateUIParentOffsets(db, unit)
                DIMINISH_NS.Icons:OnFrameConfigChanged() -- reanchors from UIParent to UnitFrame or vice versa
                DIMINISH_NS.Diminish:GROUP_ROSTER_UPDATE()
                if NS.TestMode:IsTestingOrAnchoring() then
                    NS.TestMode:HideAnchors()
                end
                panel.refresh(panel)
            end)

            frames.anchorUIParent:SetPoint("LEFT", frames.watchFriendly or frames.enabled, 0, -40)
        end


        if unit == "player" and not DIMINISH_NS.IS_NOT_RETAIL then
            frames.usePersonalNameplate = Widgets:CreateCheckbox(panel, L.ATTACH_PERSONAL_NAMEPLATE, L.ATTACH_PERSONAL_NAMEPLATE_TOOLTIP, function()
                db.usePersonalNameplate = not db.usePersonalNameplate

                DIMINISH_NS.Icons:OnFrameConfigChanged()

                if db.usePersonalNameplate and db.anchorUIParent then
                    db.anchorUIParent = false
                    frames.anchorUIParent:SetChecked(false)
                end

                if NS.TestMode:IsTestingOrAnchoring() then
                    NS.TestMode:HideAnchors()
                end

                DIMINISH_NS.Diminish:ToggleForZone()
                panel.refresh(panel)
            end)

            frames.usePersonalNameplate:SetPoint("LEFT", frames.anchorUIParent, 0, -40)
        end


        frames.growDirection = Dropdown.CreateDropdown(panel, L.GROWDIRECTION, L.GROWDIRECTION_TOOLTIP, growDirections)
        frames.growDirection:SetSize(150, 45)
        frames.growDirection:SetPoint("LEFT", frames.usePersonalNameplate or frames.anchorUIParent or frames.watchFriendly or frames.enabled, 0, -45)
        frames.growDirection.OnValueChanged = function(self, value)
            if not value or value == EMPTY then return end
            db.growDirection = value

            DIMINISH_NS.Icons:OnFrameConfigChanged()
            if NS.TestMode:IsTestingOrAnchoring() then
                NS.TestMode:HideAnchors()
            end
        end


        frames.iconSize = Widgets:CreateSlider(panel, L.ICONSIZE, L.ICONSIZE_TOOLTIP, 10, 80, 1, function(frame, value)
            db.iconSize = value
            DIMINISH_NS.Icons:OnFrameConfigChanged()
        end)
        frames.iconSize:SetPoint("LEFT", frames.growDirection, 10, -60)


        frames.iconPadding = Widgets:CreateSlider(panel, L.ICONPADDING, L.ICONPADDING_TOOLTIP, 0, 40, 1, function(frame, value)
            db.iconPadding = value
            DIMINISH_NS.Icons:OnFrameConfigChanged()
        end)
        frames.iconPadding:SetPoint("LEFT", frames.iconSize, 0, -50)


        frames.timerTextSize = Widgets:CreateSlider(panel, L.TIMERTEXTSIZE, L.TIMERTEXTSIZE_TOOLTIP, 7, 35, 1, function(_, value)
            db.timerTextSize = value
            DIMINISH_NS.Icons:OnFrameConfigChanged()
        end)
        frames.timerTextSize:SetPoint("LEFT", frames.iconPadding, 0, -50)

        if unit == "nameplate" or unit == "player" then
            -- Blizzard blocked :GetCenter() and such for nameplates in 8.2 which broke our drag anchoring,
            -- so add sliders for setting positions for nameplate icons. This is a temp solution.
            frames.offsetX = Widgets:CreateSlider(panel, "Position X", "Set X position for nameplate icons. Blizzard broke our drag-to-move functionality in patch 8.2 for nameplates so this is a temp workaround.", -200, 200, 1, function(_, value)
                db.offsetX = value
                DIMINISH_NS.Icons:OnFrameConfigChanged()
            end)
            frames.offsetX:SetPoint("LEFT", frames.timerTextSize, 0, -50)

            frames.offsetY = Widgets:CreateSlider(panel, "Position Y", "Set Y position for nameplate icons. Blizzard broke our drag-to-move functionality in patch 8.2 for nameplates so this is a temp workaround.", -200, 200, 1, function(_, value)
                db.offsetY = value
                DIMINISH_NS.Icons:OnFrameConfigChanged()
            end)
            frames.offsetY:SetPoint("LEFT", frames.offsetX, 0, -50)
        end

        -------------------------------------------------------------------

        do
            local GetSpellTexture = function(...)
                if _G.GetSpellTexture then
                    return _G.GetSpellTexture(...)
                elseif C_Spell and C_Spell.GetSpellTexture then
                    return C_Spell.GetSpellTexture(...)
                end
            end
            local subCategories = Widgets:CreateSubHeader(panel, L.HEADER_CATEGORIES)
            subCategories:SetPoint("RIGHT", -64, 10)

            local tip = panel:CreateFontString(nil, "ARTWORK", "GameFontNormal")
            tip:SetJustifyH("LEFT")
            tip:SetFont(STANDARD_TEXT_FONT, 9)
            tip:SetText(L.TEXTURECHANGE_NOTE)
            tip:SetPoint("CENTER", subCategories, 17, -45)

            -- Popup for changing icon texture manually
            StaticPopupDialogs["DIMINISH_TEXTURES"] = StaticPopupDialogs["DIMINISH_TEXTURES"] or {
                text = L.TEXTURECHANGE,
                button1 = _G.ACCEPT,
                button2 = _G.CANCEL,
                OnAccept = function(self)
                    local text = self.editBox:GetText()
                    if text == nil or text == "" then
                        DIMINISH_NS.db.categoryTextures[self.category] = nil
                        Widgets:ShowError(L.RESET)
                        return
                    end

                    local texture = GetSpellTexture(text)
                    if texture then
                        DIMINISH_NS.db.categoryTextures[self.category] = texture
                    else
                        Widgets:ShowError(L.INVALID_SPELLID)
                    end
                end,
                OnShow = function(self)
                    if not frames.iconPreview then
                        frames.iconPreview = CreateFrame("Frame")
                        frames.iconPreview.icon = frames.iconPreview:CreateTexture(nil, "OVERLAY")
                        frames.iconPreview.icon:SetAllPoints(frames.iconPreview)
                        frames.iconPreview:SetSize(32, 32)
                    end
                    frames.iconPreview:SetParent(self)
                    frames.iconPreview:SetPoint("LEFT", 30, -4)
                    frames.iconPreview:Show()

                    -- setting dialog.texture doesn't work for OnShow because its fired too fast
                    -- so delay using dialog.texture until next script execution cycle
                    C_Timer.After(0.1, function()
                        if DIMINISH_NS.db.categoryTextures[self.category] then
                            frames.iconPreview.icon:SetTexture(DIMINISH_NS.db.categoryTextures[self.category])
                        else
                            frames.iconPreview.icon:SetTexture("Interface\\ICONS\\inv_misc_questionmark")
                        end
                    end)
                end,
                OnHide = function()
                    frames.iconPreview:Hide()
                    frames.iconPreview:ClearAllPoints()
                    frames.iconPreview:SetParent(nil)
                end,
                EditBoxOnTextChanged = function(editbox)
                    local texture = GetSpellTexture(editbox:GetText())
                    if texture then
                        frames.iconPreview.icon:SetTexture(texture)
                        editbox:GetParent().button1:Enable()
                    else
                        frames.iconPreview.icon:SetTexture("Interface\\ICONS\\inv_misc_questionmark")

                        -- when text is blank we enable the button to allow reset of icon
                        -- else only enable it when valid texture is found
                        if editbox:GetText() == "" then
                            editbox:GetParent().button1:Enable()
                        else
                            editbox:GetParent().button1:Disable()
                        end
                    end
                end,
                hasEditBox = true,
                timeout = 0,
                whileDead = true,
                hideOnEscape = true,
                preferredIndex = 4,
            }

            -- Generate checkbox toggle for every category
            frames.categories = {}
            local x, y = -10, 10
            local dbCategories = NS.GetDBProxy("unitFrames", unit, "disabledCategories")

            local scrollBg = Widgets:CreatePanelBackground(panel)
            scrollBg:SetPoint("BOTTOMLEFT", subCategories, -10, -238)
            scrollBg:SetSize(250, 200)

            local scrollArea = CreateFrame("ScrollFrame", "Diminish_ScrollArea"..unit, scrollBg, "UIPanelScrollFrameTemplate")
            scrollArea:SetPoint("TOPLEFT", scrollBg, "TOPLEFT", 5, -5)
            scrollArea:SetPoint("BOTTOMRIGHT", scrollBg, "BOTTOMRIGHT", -5, 5)

            scrollArea.child = CreateFrame("Frame", "Diminish_ScrollChild"..unit, scrollArea)
            scrollArea:SetScrollChild(scrollArea.child)
            scrollArea.child:SetPoint("CENTER", subCategories, 0, 0)
            scrollArea.child:SetSize(250, 200)

            for k, category in pairs(DIMINISH_NS.CATEGORIES) do
                local continue = true
                if category == DIMINISH_NS.CATEGORIES.taunt and unit ~= "focus" and unit ~= "target" and unit ~= "nameplate" then
                    -- only show Taunt for focus/target panel
                    continue = false
                end

                if continue then
                    frames.categories[k] = Widgets:CreateCheckbox(scrollArea.child, category, L.CATEGORIES_TOOLTIP, function(self)
                        dbCategories[category] = self:GetChecked() == false and true or false
                    end)

                    frames.categories[k]:ClearAllPoints()
                    frames.categories[k]:SetPoint("TOPLEFT", y, x)
                    frames.categories[k]:SetChecked(true)
                    frames.categories[k]:HookScript("OnMouseDown", function(self, button)
                        if button == "RightButton" then
                            local dialog = StaticPopup_Show("DIMINISH_TEXTURES", category)
                            dialog.category = category
                        end
                    end)
                    x = x - 30
                end
            end
        end

        -------------------------------------------------------------------

        local subZones = Widgets:CreateSubHeader(panel, L.HEADER_ZONE)
        subZones:SetPoint("TOPRIGHT", -64, -50)

        frames.zones = {}
        local x = -60
        local dbZones = NS.GetDBProxy("unitFrames", unit, "zones")

        -- Generate checkbox toggle for every zone option
        for label, instance in pairs(zones) do
            local continue = true
            if (label == L.ZONE_DUNGEONS or label == L.ZONE_RAIDS) and unit ~= "focus" and unit ~= "target" and unit ~= "nameplate" then
                -- only show L.ZONE_DUNGEONS/RAID for focus/target/nameplate panel
                continue = false
            end

            -- Only show arena/bg zone for arena (BGs also uses arena frames)
            if unit == "arena" and (label ~= L.ZONE_ARENA and label ~= L.ZONE_BATTLEGROUNDS) then
                continue = false
            end

            if continue then
                frames.zones[label] = Widgets:CreateCheckbox(panel, label, L.ZONES_TOOLTIP, function(self)
                    if type(instance) == "table" then
                        for i = 1, #instance do
                            dbZones[instance[i]] = self:GetChecked() and true or false
                        end
                    else
                        dbZones[instance] = self:GetChecked() and true or false
                    end

                    DIMINISH_NS.Diminish:ToggleForZone()
                end)

                frames.zones[label]:SetPoint("LEFT", subZones, 10, x)
                x = x - 28
            end
        end

        frames.testBtn = Widgets:CreateButton(panel, L.TEST, L.TEST_TOOLTIP, function(btn)
            local InActiveBattlefield = _G.InActiveBattlefield or _G.C_PvP.IsActiveBattlefield
            if InCombatLockdown() or InActiveBattlefield() or (IsActiveBattlefieldArena and IsActiveBattlefieldArena()) then
                return Widgets:ShowError(L.COMBATLOCKDOWN_ERROR)
            end
            NS.TestMode:Test()
        end)
        frames.testBtn:SetPoint("BOTTOMRIGHT", panel, -15, 15)


        if unit ~= "nameplate" then
            frames.unlockBtn = Widgets:CreateButton(panel, L.UNLOCK, L.UNLOCK_TOOLTIP, function(btn)
                if InCombatLockdown() then
                    return Widgets:ShowError(L.COMBATLOCKDOWN_ERROR)
                end

                if not NS.TestMode:IsAnchoring() then
                    NS.TestMode:ShowAnchors(unit)
                else
                    NS.TestMode:HideAnchors(unit)
                end
            end)
            frames.unlockBtn:SetPoint("BOTTOMLEFT", panel, 15, 15)
            frames.unlockBtn:SetSize(200, 25)
        end


        frames.resetPosBtn = Widgets:CreateButton(panel, L.RESETPOS, L.RESETPOS_TOOLTIP, function(btn)
            local defaults = DIMINISH_NS.DEFAULT_SETTINGS.unitFrames[unit]
            db.offsetY = defaults.offsetY
            db.offsetX = defaults.offsetX
            db.growDirection = defaults.growDirection
            db.offsetsY = nil
            db.offsetsX = nil

            frames.growDirection:SetValue(nil)
            DIMINISH_NS.Icons:OnFrameConfigChanged()
            if NS.TestMode:IsTestingOrAnchoring() then
                NS.TestMode:HideAnchors()
                NS.TestMode:Test(true)
            end
        end)
        frames.resetPosBtn:SetPoint("LEFT", frames.testBtn, -120, 0)
        frames.resetPosBtn:SetWidth(120)

        if unit == "player" then
            if db.usePersonalNameplate then
                frames.unlockBtn:Hide()
                frames.offsetX:Show()
                frames.offsetY:Show()
            else
                frames.unlockBtn:Show()
                frames.offsetX:Hide()
                frames.offsetY:Hide()
            end
        end
    end)
end
