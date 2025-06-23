-- luacheck: no max line length
-- luacheck: globals GetBuildInfo LibStub NAuras_LibButtonGlow UIParent bit GetTime C_Timer C_NamePlate UnitGUID wipe
-- luacheck: globals SLASH_NAMEPLATECOOLDOWNS1 SlashCmdList UNKNOWN IsInGroup LE_PARTY_CATEGORY_INSTANCE IsInRaid C_ChatInfo CreateFrame
-- luacheck: globals unpack InCombatLockdown ColorPickerFrame BackdropTemplateMixin UIDropDownMenu_SetWidth UIDropDownMenu_AddButton GameFontNormal
-- luacheck: globals GameFontHighlightSmall hooksecurefunc ALL GameTooltip LocalizedClassList
-- luacheck: globals OTHER PlaySound SOUNDKIT COMBATLOG_OBJECT_REACTION_HOSTILE CombatLogGetCurrentEventInfo IsInInstance strsplit UnitName GetRealmName
-- luacheck: globals UnitReaction C_Spell

local _, addonTable = ...;

-- Libraries
local L, LRD, SML;
do
	L = LibStub("AceLocale-3.0"):GetLocale("NameplateCooldowns");
	LRD = LibStub("LibRedDropdown-1.0");
	SML = LibStub("LibSharedMedia-3.0");
	SML:Register("font", "NC_TeenBold", "Interface\\AddOns\\NameplateCooldowns\\media\\teen_bold.ttf", 255);
end

-- Utilities
local SpellTextureByID, SpellNameByID;
do
	SpellTextureByID, SpellNameByID = addonTable.SpellTextureByID, addonTable.SpellNameByID;
end

local AllSpellIDsAndIconsByName = { };
local GUIFrame;

local _G, UIParent, table_insert, C_Timer_After, GetSpellInfo, table_sort = _G, UIParent, table.insert, C_Timer.After, C_Spell.GetSpellInfo, table.sort;
local string_format, math_ceil = string.format, math.ceil;

local function GUICategory_Filters(index)
    local checkBoxEnableOnlyForTarget, buttonInstances, filterByTimeArea, sliderFilterByTimeLess, sliderFilterByTimeMore;

    -- // checkBoxEnableOnlyForTarget
    do
        checkBoxEnableOnlyForTarget = LRD.CreateCheckBox();
        checkBoxEnableOnlyForTarget:SetText(L["options:general:enable-only-for-target-nameplate"]);
        checkBoxEnableOnlyForTarget:SetOnClickHandler(function(this)
            addonTable.db.ShowCooldownsOnCurrentTargetOnly = this:GetChecked();
            addonTable.OnDbChanged();
        end);
        checkBoxEnableOnlyForTarget:SetChecked(addonTable.db.ShowCooldownsOnCurrentTargetOnly);
        checkBoxEnableOnlyForTarget:SetParent(GUIFrame.outline);
        checkBoxEnableOnlyForTarget:SetPoint("TOPLEFT", GUIFrame.outline, "TOPRIGHT", 15, -15);
        table_insert(GUIFrame.Categories[index], checkBoxEnableOnlyForTarget);
        table_insert(GUIFrame.OnDBChangedHandlers, function() checkBoxEnableOnlyForTarget:SetChecked(addonTable.db.ShowCooldownsOnCurrentTargetOnly); end);

    end

    -- // buttonInstances
    do
        local zoneTypes = {
			[addonTable.INSTANCE_TYPE_NONE] = 			L["instance-type:none"],
			[addonTable.INSTANCE_TYPE_UNKNOWN] = 		L["instance-type:unknown"],
			[addonTable.INSTANCE_TYPE_PVP] = 			L["instance-type:pvp"],
			[addonTable.INSTANCE_TYPE_PVP_BG_40PPL] = 	L["instance-type:pvp_bg_40ppl"],
			[addonTable.INSTANCE_TYPE_ARENA] = 			L["instance-type:arena"],
			[addonTable.INSTANCE_TYPE_PARTY] = 			L["instance-type:party"],
			[addonTable.INSTANCE_TYPE_RAID] = 			L["instance-type:raid"],
			[addonTable.INSTANCE_TYPE_SCENARIO] =		L["instance-type:scenario"],
		};
		local zoneIcons = {
			[addonTable.INSTANCE_TYPE_NONE] = 			SpellTextureByID[6711],
			[addonTable.INSTANCE_TYPE_UNKNOWN] = 		SpellTextureByID[175697],
			[addonTable.INSTANCE_TYPE_PVP] = 			SpellTextureByID[232352],
			[addonTable.INSTANCE_TYPE_PVP_BG_40PPL] = 	132485,
			[addonTable.INSTANCE_TYPE_ARENA] = 			SpellTextureByID[270697],
			[addonTable.INSTANCE_TYPE_PARTY] = 			SpellTextureByID[77629],
			[addonTable.INSTANCE_TYPE_RAID] = 			SpellTextureByID[3363],
			[addonTable.INSTANCE_TYPE_SCENARIO] =		SpellTextureByID[77628],
		};

        local dropdownInstances = LRD.CreateDropdownMenu();
        buttonInstances = LRD.CreateButton();
        buttonInstances:SetParent(GUIFrame.outline);
        buttonInstances:SetText(L["filters.instance-types"]);

        local function setEntries()
            local entries = { };
            for instanceType, instanceLocalizatedName in pairs(zoneTypes) do
                table_insert(entries, {
                    ["text"] = instanceLocalizatedName,
                    ["icon"] = zoneIcons[instanceType],
                    ["func"] = function(info)
                        local btn = dropdownInstances:GetButtonByText(info.text);
                        if (btn) then
                            info.disabled = not info.disabled;
                            btn:SetGray(info.disabled);
                            addonTable.db.EnabledZoneTypes[info.instanceType] = not info.disabled;
                        end
                        addonTable.OnDbChanged();
                    end,
                    ["disabled"] = not addonTable.db.EnabledZoneTypes[instanceType],
                    ["dontCloseOnClick"] = true,
                    ["instanceType"] = instanceType,
                });
            end
            table_sort(entries, function(item1, item2) return item1.instanceType < item2.instanceType; end);
            return entries;
        end

        buttonInstances:SetWidth(350);
        buttonInstances:SetHeight(40);
        buttonInstances:SetPoint("TOPLEFT", checkBoxEnableOnlyForTarget, "BOTTOMLEFT", 0, -5);
        buttonInstances:SetScript("OnClick", function(self)
            if (dropdownInstances:IsVisible()) then
                dropdownInstances:Hide();
            else
                dropdownInstances:SetList(setEntries());
                dropdownInstances:SetParent(self);
                dropdownInstances:ClearAllPoints();
                dropdownInstances:SetPoint("TOP", self, "BOTTOM", 0, 0);
                dropdownInstances:Show();
            end
        end);
        buttonInstances:SetScript("OnHide", function() dropdownInstances:Hide(); end);
        table_insert(GUIFrame.Categories[index], buttonInstances);
        table_insert(GUIFrame.OnDBChangedHandlers, function() dropdownInstances:SetList(setEntries()); dropdownInstances:Hide(); end);

    end

    -- // filterByTimeArea
    do
        filterByTimeArea = CreateFrame("Frame", nil, GUIFrame, BackdropTemplateMixin and "BackdropTemplate");
        filterByTimeArea:SetBackdrop({
            bgFile = "Interface\\Tooltips\\UI-Tooltip-Background",
            edgeFile = "Interface\\Tooltips\\UI-Tooltip-Border",
            tile = 1,
            tileSize = 16,
            edgeSize = 16,
            insets = { left = 4, right = 4, top = 4, bottom = 4 }
        });
        filterByTimeArea:SetBackdropColor(0.1, 0.1, 0.2, 1);
        filterByTimeArea:SetBackdropBorderColor(0.8, 0.8, 0.9, 0.4);
        filterByTimeArea:SetPoint("TOPLEFT", buttonInstances, "BOTTOMLEFT",  0, -10);
        filterByTimeArea:SetPoint("TOPRIGHT", buttonInstances, "BOTTOMRIGHT",  0, -10);
        filterByTimeArea:SetWidth(360);
        filterByTimeArea:SetHeight(100);
        table_insert(GUIFrame.Categories[index], filterByTimeArea);
    end

    do
        local minValue, maxValue = 0, 10*3600;
        sliderFilterByTimeLess = LRD.CreateSlider();
        sliderFilterByTimeLess:SetParent(filterByTimeArea);
        sliderFilterByTimeLess:SetHeight(100);
        sliderFilterByTimeLess:SetPoint("TOPRIGHT", filterByTimeArea, "TOP", -10, -15);
        sliderFilterByTimeLess:SetPoint("BOTTOMLEFT", filterByTimeArea, "BOTTOMLEFT", 10, 10);
        sliderFilterByTimeLess:GetTextObject():SetText("Min cooldown duration time, in seconds");
        sliderFilterByTimeLess:GetBaseSliderObject():SetValueStep(1);
        sliderFilterByTimeLess:GetBaseSliderObject():SetMinMaxValues(minValue, maxValue);
        sliderFilterByTimeLess:GetBaseSliderObject():SetValue(addonTable.db.MinCdDuration);
        sliderFilterByTimeLess:GetBaseSliderObject():SetScript("OnValueChanged", function(_, value)
            local valueNum = math_ceil(value);
            sliderFilterByTimeLess:GetEditboxObject():SetText(tostring(valueNum));
            addonTable.db.MinCdDuration = valueNum;
            addonTable.OnDbChanged();
        end);
        sliderFilterByTimeLess:GetEditboxObject():SetText(tostring(addonTable.db.MinCdDuration));
        sliderFilterByTimeLess:GetEditboxObject():SetScript("OnEnterPressed", function()
            local text = sliderFilterByTimeLess:GetEditboxObject():GetText();
            if (text ~= "") then
                local v = tonumber(text);
                if (v == nil) then
                    sliderFilterByTimeLess:GetEditboxObject():SetText(tostring(addonTable.db.MinCdDuration));
                    addonTable.Print(L["Value must be a number"]);
                else
                    if (v > maxValue) then
                        v = maxValue;
                    end
                    if (v < minValue) then
                        v = minValue;
                    end
                    sliderFilterByTimeLess:GetBaseSliderObject():SetValue(v);
                end
                sliderFilterByTimeLess:GetEditboxObject():ClearFocus();
            end
        end);
        sliderFilterByTimeLess:GetLowTextObject():SetText(tostring(minValue));
        sliderFilterByTimeLess:GetHighTextObject():SetText(tostring(maxValue));
        table.insert(GUIFrame.Categories[index], sliderFilterByTimeLess);
        table_insert(GUIFrame.OnDBChangedHandlers, function()
            sliderFilterByTimeLess:GetBaseSliderObject():SetValue(addonTable.db.MinCdDuration);
            sliderFilterByTimeLess:GetEditboxObject():SetText(tostring(addonTable.db.MinCdDuration));
        end);
    end

    do
        local minValue, maxValue = 0, 10*3600;
        sliderFilterByTimeMore = LRD.CreateSlider();
        sliderFilterByTimeMore:SetParent(filterByTimeArea);
        sliderFilterByTimeMore:SetHeight(100);
        sliderFilterByTimeMore:SetPoint("TOPLEFT", filterByTimeArea, "TOP", 10, -15);
        sliderFilterByTimeMore:SetPoint("BOTTOMRIGHT", filterByTimeArea, "BOTTOMRIGHT", -10, 10);
        sliderFilterByTimeMore:GetTextObject():SetText("Max cooldown duration time, in seconds");
        sliderFilterByTimeMore:GetBaseSliderObject():SetValueStep(1);
        sliderFilterByTimeMore:GetBaseSliderObject():SetMinMaxValues(minValue, maxValue);
        sliderFilterByTimeMore:GetBaseSliderObject():SetValue(addonTable.db.MaxCdDuration);
        sliderFilterByTimeMore:GetBaseSliderObject():SetScript("OnValueChanged", function(_, value)
            local valueNum = math_ceil(value);
            sliderFilterByTimeMore:GetEditboxObject():SetText(tostring(valueNum));
            addonTable.db.MaxCdDuration = valueNum;
            addonTable.OnDbChanged();
        end);
        sliderFilterByTimeMore:GetEditboxObject():SetText(tostring(addonTable.db.MaxCdDuration));
        sliderFilterByTimeMore:GetEditboxObject():SetScript("OnEnterPressed", function()
            local text = sliderFilterByTimeMore:GetEditboxObject():GetText();
            if (text ~= "") then
                local v = tonumber(text);
                if (v == nil) then
                    sliderFilterByTimeMore:GetEditboxObject():SetText(tostring(addonTable.db.MaxCdDuration));
                    addonTable.Print(L["Value must be a number"]);
                else
                    if (v > maxValue) then
                        v = maxValue;
                    end
                    if (v < minValue) then
                        v = minValue;
                    end
                    sliderFilterByTimeMore:GetBaseSliderObject():SetValue(v);
                end
                sliderFilterByTimeMore:GetEditboxObject():ClearFocus();
            end
        end);
        sliderFilterByTimeMore:GetLowTextObject():SetText(tostring(minValue));
        sliderFilterByTimeMore:GetHighTextObject():SetText(tostring(maxValue));
        table.insert(GUIFrame.Categories[index], sliderFilterByTimeMore);
        table_insert(GUIFrame.OnDBChangedHandlers, function()
            sliderFilterByTimeMore:GetBaseSliderObject():SetValue(addonTable.db.MaxCdDuration);
            sliderFilterByTimeMore:GetEditboxObject():SetText(tostring(addonTable.db.MaxCdDuration));
        end);
    end



end

local function GUICategory_Borders(index)
    local checkBoxBorderTrinkets, checkBoxBorderInterrupts, checkBoxShowOldBlizzardBordersAroundIcons;

    -- // checkBoxBorderTrinkets
    do
        checkBoxBorderTrinkets = LRD.CreateCheckBoxWithColorPicker();
        checkBoxBorderTrinkets:SetText(L["Show border around trinkets"]);
        checkBoxBorderTrinkets:SetOnClickHandler(function(this)
            addonTable.db.ShowBorderTrinkets = this:GetChecked();
            addonTable.OnDbChanged();
        end);
        checkBoxBorderTrinkets:SetParent(GUIFrame.outline);
        checkBoxBorderTrinkets:SetPoint("TOPLEFT", GUIFrame.outline, "TOPRIGHT", 15, -15);
        checkBoxBorderTrinkets:SetChecked(addonTable.db.ShowBorderTrinkets);
        checkBoxBorderTrinkets:SetColor(unpack(addonTable.db.BorderTrinketsColor));

        checkBoxBorderTrinkets.ColorButton.func = function(_, _r, _g, _b, _)
            addonTable.db.BorderTrinketsColor = {_r, _g, _b};
            addonTable.OnDbChanged();
        end
        table.insert(GUIFrame.Categories[index], checkBoxBorderTrinkets);
        table_insert(GUIFrame.OnDBChangedHandlers, function() checkBoxBorderTrinkets:SetChecked(addonTable.db.ShowBorderTrinkets); checkBoxBorderTrinkets:SetColor(unpack(addonTable.db.BorderTrinketsColor)); end);
    end

    -- // checkBoxBorderInterrupts
    do
        checkBoxBorderInterrupts = LRD.CreateCheckBoxWithColorPicker();
        checkBoxBorderInterrupts:SetText(L["Show border around interrupts"]);
        checkBoxBorderInterrupts:SetOnClickHandler(function(this)
            addonTable.db.ShowBorderInterrupts = this:GetChecked();
            addonTable.OnDbChanged();
        end);
        checkBoxBorderInterrupts:SetParent(GUIFrame.outline);
        checkBoxBorderInterrupts:SetPoint("TOPLEFT", checkBoxBorderTrinkets, "BOTTOMLEFT", 0, -5);
        checkBoxBorderInterrupts:SetChecked(addonTable.db.ShowBorderInterrupts);
        checkBoxBorderInterrupts:SetColor(unpack(addonTable.db.BorderInterruptsColor));

        checkBoxBorderInterrupts.ColorButton.func = function(_, _r, _g, _b, _)
            addonTable.db.BorderInterruptsColor = {_r, _g, _b};
            addonTable.OnDbChanged();
        end

        table.insert(GUIFrame.Categories[index], checkBoxBorderInterrupts);
        table_insert(GUIFrame.OnDBChangedHandlers, function() checkBoxBorderInterrupts:SetChecked(addonTable.db.ShowBorderInterrupts); checkBoxBorderInterrupts:SetColor(unpack(addonTable.db.BorderInterruptsColor)); end);
    end

    -- // checkBoxShowOldBlizzardBordersAroundIcons
    do
        checkBoxShowOldBlizzardBordersAroundIcons = LRD.CreateCheckBox();
        checkBoxShowOldBlizzardBordersAroundIcons:SetText(L["options:borders:show-blizz-borders"]);
        checkBoxShowOldBlizzardBordersAroundIcons:SetOnClickHandler(function(this)
            addonTable.db.ShowOldBlizzardBorderAroundIcons = this:GetChecked();
            addonTable.OnDbChanged();
        end);
        checkBoxShowOldBlizzardBordersAroundIcons:SetParent(GUIFrame.outline);
        checkBoxShowOldBlizzardBordersAroundIcons:SetPoint("TOPLEFT", checkBoxBorderInterrupts, "BOTTOMLEFT", 0, -5);
        checkBoxShowOldBlizzardBordersAroundIcons:SetChecked(addonTable.db.ShowOldBlizzardBorderAroundIcons);
        table.insert(GUIFrame.Categories[index], checkBoxShowOldBlizzardBordersAroundIcons);
        table_insert(GUIFrame.OnDBChangedHandlers, function() checkBoxShowOldBlizzardBordersAroundIcons:SetChecked(addonTable.db.ShowOldBlizzardBorderAroundIcons); end);
    end

end

local function GUICategory_Text(index)
    local dropdownMenuFont = LRD.CreateDropdownMenu();
    local textAnchors = { "TOPRIGHT", "RIGHT", "BOTTOMRIGHT", "TOP", "CENTER", "BOTTOM", "TOPLEFT", "LEFT", "BOTTOMLEFT" };
    local textAnchorsLocalization = {
        [textAnchors[1]] = L["anchor-point:topright"],
        [textAnchors[2]] = L["anchor-point:right"],
        [textAnchors[3]] = L["anchor-point:bottomright"],
        [textAnchors[4]] = L["anchor-point:top"],
        [textAnchors[5]] = L["anchor-point:center"],
        [textAnchors[6]] = L["anchor-point:bottom"],
        [textAnchors[7]] = L["anchor-point:topleft"],
        [textAnchors[8]] = L["anchor-point:left"],
        [textAnchors[9]] = L["anchor-point:bottomleft"]
    };
    local textSizeArea, textAnchorArea;
    local sliderTimerFontScale, sliderTimerFontSize;

    -- // dropdownFont
    do
        local fonts = { };
        local button = LRD.CreateButton();
        button:SetParent(GUIFrame);
        button:SetText(L["options:text:font"] .. ": " .. addonTable.db.Font);

        for _, font in next, SML:List("font") do
            table_insert(fonts, {
                ["text"] = font,
                ["icon"] = [[Interface\AddOns\NameplateAuras\media\font.tga]],
                ["func"] = function(info)
                    button.Text:SetText(L["options:text:font"] .. ": " .. info.text);
                    addonTable.db.Font = info.text;
                    addonTable.OnDbChanged();
                end,
                ["options:text:font"] = SML:Fetch("font", font),
            });
        end
        table_sort(fonts, function(item1, item2) return item1.text < item2.text; end);

        button:SetWidth(170);
        button:SetHeight(24);
        button:SetPoint("TOPLEFT", GUIFrame, "TOPLEFT", 160, -28);
        button:SetPoint("TOPRIGHT", GUIFrame, "TOPRIGHT", -30, -28);
        button:SetScript("OnClick", function(self)
            if (dropdownMenuFont:IsVisible()) then
                dropdownMenuFont:Hide();
            else
                dropdownMenuFont:SetList(fonts);
                dropdownMenuFont:SetParent(self);
                dropdownMenuFont:ClearAllPoints();
                dropdownMenuFont:SetPoint("TOP", self, "BOTTOM", 0, 0);
                dropdownMenuFont:Show();
            end
        end);
        table_insert(GUIFrame.Categories[index], button);

    end

    -- // textSizeArea
    do
        textSizeArea = CreateFrame("Frame", nil, GUIFrame, BackdropTemplateMixin and "BackdropTemplate");
        textSizeArea:SetBackdrop({
            bgFile = "Interface\\Tooltips\\UI-Tooltip-Background",
            edgeFile = "Interface\\Tooltips\\UI-Tooltip-Border",
            tile = 1,
            tileSize = 16,
            edgeSize = 16,
            insets = { left = 4, right = 4, top = 4, bottom = 4 }
        });
        textSizeArea:SetBackdropColor(0.1, 0.1, 0.2, 1);
        textSizeArea:SetBackdropBorderColor(0.8, 0.8, 0.9, 0.4);
        textSizeArea:SetPoint("TOPLEFT", 155, -60);
        textSizeArea:SetWidth(360);
        textSizeArea:SetHeight(71);
        table_insert(GUIFrame.Categories[index], textSizeArea);
    end

    -- // sliderTimerFontScale
    do
        local minValue, maxValue = 0.3, 3;
        sliderTimerFontScale = LRD.CreateSlider();
        sliderTimerFontScale:SetParent(textSizeArea);
        sliderTimerFontScale:SetWidth(200);
        sliderTimerFontScale:SetPoint("TOPLEFT", 150, -15);
        sliderTimerFontScale.label:SetText(L["options:text:font-scale"]);
        sliderTimerFontScale.slider:SetValueStep(0.1);
        sliderTimerFontScale.slider:SetMinMaxValues(minValue, maxValue);
        sliderTimerFontScale.slider:SetValue(addonTable.db.FontScale);
        sliderTimerFontScale.slider:SetScript("OnValueChanged", function(_, value)
            local actualValue = tonumber(string_format("%.1f", value));
            sliderTimerFontScale.editbox:SetText(tostring(actualValue));
            addonTable.db.FontScale = actualValue;
            addonTable.OnDbChanged();
        end);
        sliderTimerFontScale.editbox:SetText(tostring(addonTable.db.FontScale));
        sliderTimerFontScale.editbox:SetScript("OnEnterPressed", function()
            if (sliderTimerFontScale.editbox:GetText() ~= "") then
                local v = tonumber(sliderTimerFontScale.editbox:GetText());
                if (v == nil) then
                    sliderTimerFontScale.editbox:SetText(tostring(addonTable.db.FontScale));
                    addonTable.msg(L["Value must be a number"]);
                else
                    if (v > maxValue) then
                        v = maxValue;
                    end
                    if (v < minValue) then
                        v = minValue;
                    end
                    sliderTimerFontScale.slider:SetValue(v);
                end
                sliderTimerFontScale.editbox:ClearFocus();
            end
        end);
        sliderTimerFontScale.lowtext:SetText(tostring(minValue));
        sliderTimerFontScale.hightext:SetText(tostring(maxValue));
        table_insert(GUIFrame.OnDBChangedHandlers, function() sliderTimerFontScale.editbox:SetText(tostring(addonTable.db.FontScale)); sliderTimerFontScale.slider:SetValue(addonTable.db.FontScale); end);
    end

    -- // sliderTimerFontSize
    do
        local minValue, maxValue = 6, 96;
        sliderTimerFontSize = LRD.CreateSlider();
        sliderTimerFontSize:SetParent(textSizeArea);
        sliderTimerFontSize:SetWidth(200);
        sliderTimerFontSize:SetPoint("TOPLEFT", 150, -15);
        sliderTimerFontSize.label:SetText(L["options:text:font-size"]);
        sliderTimerFontSize.slider:SetValueStep(1);
        sliderTimerFontSize.slider:SetMinMaxValues(minValue, maxValue);
        sliderTimerFontSize.slider:SetValue(addonTable.db.TimerTextSize);
        sliderTimerFontSize.slider:SetScript("OnValueChanged", function(_, value)
            local actualValue = tonumber(string_format("%.0f", value));
            sliderTimerFontSize.editbox:SetText(tostring(actualValue));
            addonTable.db.TimerTextSize = actualValue;
            addonTable.OnDbChanged();
        end);
        sliderTimerFontSize.editbox:SetText(tostring(addonTable.db.TimerTextSize));
        sliderTimerFontSize.editbox:SetScript("OnEnterPressed", function()
            if (sliderTimerFontSize.editbox:GetText() ~= "") then
                local v = tonumber(sliderTimerFontSize.editbox:GetText());
                if (v == nil) then
                    sliderTimerFontSize.editbox:SetText(tostring(addonTable.db.TimerTextSize));
                    addonTable.msg(L["Value must be a number"]);
                else
                    if (v > maxValue) then
                        v = maxValue;
                    end
                    if (v < minValue) then
                        v = minValue;
                    end
                    sliderTimerFontSize.slider:SetValue(v);
                end
                sliderTimerFontSize.editbox:ClearFocus();
            end
        end);
        sliderTimerFontSize.lowtext:SetText(tostring(minValue));
        sliderTimerFontSize.hightext:SetText(tostring(maxValue));
        table_insert(GUIFrame.OnDBChangedHandlers, function() sliderTimerFontSize.editbox:SetText(tostring(addonTable.db.TimerTextSize)); sliderTimerFontSize.slider:SetValue(addonTable.db.TimerTextSize); end);
    end

    -- // checkBoxUseRelativeFontSize
    do
        local checkBoxUseRelativeFontSize = LRD.CreateCheckBox();
        checkBoxUseRelativeFontSize:SetText(L["options:timer-text:scale-font-size"]);
        checkBoxUseRelativeFontSize:SetOnClickHandler(function(this)
            addonTable.db.TimerTextUseRelativeScale = this:GetChecked();
            if (addonTable.db.TimerTextUseRelativeScale) then
                sliderTimerFontScale:Show();
                sliderTimerFontSize:Hide();
            else
                sliderTimerFontScale:Hide();
                sliderTimerFontSize:Show();
            end
            addonTable.OnDbChanged();
        end);
        checkBoxUseRelativeFontSize:SetChecked(addonTable.db.TimerTextUseRelativeScale);
        checkBoxUseRelativeFontSize:SetParent(textSizeArea);
        checkBoxUseRelativeFontSize:SetPoint("TOPLEFT", 10, -25);
        table_insert(GUIFrame.Categories[index], checkBoxUseRelativeFontSize);
        table_insert(GUIFrame.OnDBChangedHandlers, function()
            checkBoxUseRelativeFontSize:SetChecked(addonTable.db.TimerTextUseRelativeScale);
        end);
        checkBoxUseRelativeFontSize:SetScript("OnShow", function()
            if (addonTable.db.TimerTextUseRelativeScale) then
                sliderTimerFontScale:Show();
                sliderTimerFontSize:Hide();
            else
                sliderTimerFontScale:Hide();
                sliderTimerFontSize:Show();
            end
        end);
        checkBoxUseRelativeFontSize:SetScript("OnHide", function()
            sliderTimerFontScale:Hide();
            sliderTimerFontSize:Hide();
        end);
    end

    -- // textAnchorArea
    do
        textAnchorArea = CreateFrame("Frame", nil, GUIFrame, BackdropTemplateMixin and "BackdropTemplate");
        textAnchorArea:SetBackdrop({
            bgFile = "Interface\\Tooltips\\UI-Tooltip-Background",
            edgeFile = "Interface\\Tooltips\\UI-Tooltip-Border",
            tile = 1,
            tileSize = 16,
            edgeSize = 16,
            insets = { left = 4, right = 4, top = 4, bottom = 4 }
        });
        textAnchorArea:SetBackdropColor(0.1, 0.1, 0.2, 1);
        textAnchorArea:SetBackdropBorderColor(0.8, 0.8, 0.9, 0.4);
        textAnchorArea:SetPoint("TOP", textSizeArea, "BOTTOM", 0, -10);
        textAnchorArea:SetWidth(textSizeArea:GetWidth());
        textAnchorArea:SetHeight(100);
        table_insert(GUIFrame.Categories[index], textAnchorArea);
    end

    -- // dropdownTimerTextAnchor
    do
        local dropdownTimerTextAnchor = CreateFrame("Frame", "NC.GUI.Fonts.DropdownTimerTextAnchor", textAnchorArea, "UIDropDownMenuTemplate");
        UIDropDownMenu_SetWidth(dropdownTimerTextAnchor, 145);
        dropdownTimerTextAnchor:SetPoint("TOPLEFT", 0, -15);
        local info = {};
        dropdownTimerTextAnchor.initialize = function()
            wipe(info);
            for _, anchorPoint in pairs(textAnchors) do
                info.text = textAnchorsLocalization[anchorPoint];
                info.value = anchorPoint;
                info.func = function(self)
                    addonTable.db.TimerTextAnchor = self.value;
                    _G[dropdownTimerTextAnchor:GetName() .. "Text"]:SetText(self:GetText());
                    addonTable.OnDbChanged();
                end
                info.checked = anchorPoint == addonTable.db.TimerTextAnchor;
                UIDropDownMenu_AddButton(info);
            end
        end
        _G[dropdownTimerTextAnchor:GetName() .. "Text"]:SetText(textAnchorsLocalization[addonTable.db.TimerTextAnchor]);
        dropdownTimerTextAnchor.text = dropdownTimerTextAnchor:CreateFontString(nil, "ARTWORK", "GameFontNormalSmall");
        dropdownTimerTextAnchor.text:SetPoint("LEFT", 20, 15);
        dropdownTimerTextAnchor.text:SetText(L["options:text:anchor-point"]);
        table_insert(GUIFrame.Categories[index], dropdownTimerTextAnchor);
        table_insert(GUIFrame.OnDBChangedHandlers, function()
            local text = textAnchorsLocalization[addonTable.db.TimerTextAnchor];
            _G[dropdownTimerTextAnchor:GetName() .. "Text"]:SetText(text);
        end);
    end

    -- // dropdownTimerTextAnchorIcon
    do
        local dropdownTimerTextAnchorIcon = CreateFrame("Frame", "NC.GUI.Fonts.DropdownTimerTextAnchorIcon", textAnchorArea, "UIDropDownMenuTemplate");
        UIDropDownMenu_SetWidth(dropdownTimerTextAnchorIcon, 145);
        dropdownTimerTextAnchorIcon:SetPoint("TOPLEFT", 165, -15);
        local info = {};
        dropdownTimerTextAnchorIcon.initialize = function()
            wipe(info);
            for _, anchorPoint in pairs(textAnchors) do
                info.text = textAnchorsLocalization[anchorPoint];
                info.value = anchorPoint;
                info.func = function(self)
                    addonTable.db.TimerTextAnchorIcon = self.value;
                    _G[dropdownTimerTextAnchorIcon:GetName() .. "Text"]:SetText(self:GetText());
                    addonTable.OnDbChanged();
                end
                info.checked = anchorPoint == addonTable.db.TimerTextAnchorIcon;
                UIDropDownMenu_AddButton(info);
            end
        end
        _G[dropdownTimerTextAnchorIcon:GetName() .. "Text"]:SetText(textAnchorsLocalization[addonTable.db.TimerTextAnchorIcon]);
        dropdownTimerTextAnchorIcon.text = dropdownTimerTextAnchorIcon:CreateFontString(nil, "ARTWORK", "GameFontNormalSmall");
        dropdownTimerTextAnchorIcon.text:SetPoint("LEFT", 20, 15);
        dropdownTimerTextAnchorIcon.text:SetText(L["options:text:anchor-to-icon"]);
        table_insert(GUIFrame.Categories[index], dropdownTimerTextAnchorIcon);
        table_insert(GUIFrame.OnDBChangedHandlers, function()
            local text = textAnchorsLocalization[addonTable.db.TimerTextAnchorIcon];
            _G[dropdownTimerTextAnchorIcon:GetName() .. "Text"]:SetText(text);
        end);
    end

    -- // sliderTimerTextXOffset
    do
        local minValue, maxValue = -100, 100;
        local sliderTimerTextXOffset = LRD.CreateSlider();
        sliderTimerTextXOffset:SetParent(textAnchorArea);
        sliderTimerTextXOffset:SetWidth(165);
        sliderTimerTextXOffset:SetPoint("TOPLEFT", 15, -50);
        sliderTimerTextXOffset.label:SetText(L["anchor-point:x-offset"]);
        sliderTimerTextXOffset.slider:SetValueStep(1);
        sliderTimerTextXOffset.slider:SetMinMaxValues(minValue, maxValue);
        sliderTimerTextXOffset.slider:SetValue(addonTable.db.TimerTextXOffset);
        sliderTimerTextXOffset.slider:SetScript("OnValueChanged", function(_, value)
            local actualValue = tonumber(string_format("%.0f", value));
            sliderTimerTextXOffset.editbox:SetText(tostring(actualValue));
            addonTable.db.TimerTextXOffset = actualValue;
            addonTable.OnDbChanged();
        end);
        sliderTimerTextXOffset.editbox:SetText(tostring(addonTable.db.TimerTextXOffset));
        sliderTimerTextXOffset.editbox:SetScript("OnEnterPressed", function()
            if (sliderTimerTextXOffset.editbox:GetText() ~= "") then
                local v = tonumber(sliderTimerTextXOffset.editbox:GetText());
                if (v == nil) then
                    sliderTimerTextXOffset.editbox:SetText(tostring(addonTable.db.TimerTextXOffset));
                    addonTable.msg(L["Value must be a number"]);
                else
                    if (v > maxValue) then
                        v = maxValue;
                    end
                    if (v < minValue) then
                        v = minValue;
                    end
                    sliderTimerTextXOffset.slider:SetValue(v);
                end
                sliderTimerTextXOffset.editbox:ClearFocus();
            end
        end);
        sliderTimerTextXOffset.lowtext:SetText(tostring(minValue));
        sliderTimerTextXOffset.hightext:SetText(tostring(maxValue));
        table_insert(GUIFrame.Categories[index], sliderTimerTextXOffset);
        table_insert(GUIFrame.OnDBChangedHandlers, function() sliderTimerTextXOffset.editbox:SetText(tostring(addonTable.db.TimerTextXOffset)); sliderTimerTextXOffset.slider:SetValue(addonTable.db.TimerTextXOffset); end);
    end

    -- // sliderTimerTextYOffset
    do
        local minValue, maxValue = -100, 100;
        local sliderTimerTextYOffset = LRD.CreateSlider();
        sliderTimerTextYOffset:SetParent(textAnchorArea);
        sliderTimerTextYOffset:SetWidth(165);
        sliderTimerTextYOffset:SetPoint("TOPLEFT", 185, -50);
        sliderTimerTextYOffset.label:SetText(L["anchor-point:y-offset"]);
        sliderTimerTextYOffset.slider:SetValueStep(1);
        sliderTimerTextYOffset.slider:SetMinMaxValues(minValue, maxValue);
        sliderTimerTextYOffset.slider:SetValue(addonTable.db.TimerTextYOffset);
        sliderTimerTextYOffset.slider:SetScript("OnValueChanged", function(_, value)
            local actualValue = tonumber(string_format("%.0f", value));
            sliderTimerTextYOffset.editbox:SetText(tostring(actualValue));
            addonTable.db.TimerTextYOffset = actualValue;
            addonTable.OnDbChanged();
        end);
        sliderTimerTextYOffset.editbox:SetText(tostring(addonTable.db.TimerTextYOffset));
        sliderTimerTextYOffset.editbox:SetScript("OnEnterPressed", function()
            if (sliderTimerTextYOffset.editbox:GetText() ~= "") then
                local v = tonumber(sliderTimerTextYOffset.editbox:GetText());
                if (v == nil) then
                    sliderTimerTextYOffset.editbox:SetText(tostring(addonTable.db.TimerTextYOffset));
                    addonTable.msg(L["Value must be a number"]);
                else
                    if (v > maxValue) then
                        v = maxValue;
                    end
                    if (v < minValue) then
                        v = minValue;
                    end
                    sliderTimerTextYOffset.slider:SetValue(v);
                end
                sliderTimerTextYOffset.editbox:ClearFocus();
            end
        end);
        sliderTimerTextYOffset.lowtext:SetText(tostring(minValue));
        sliderTimerTextYOffset.hightext:SetText(tostring(maxValue));
        table_insert(GUIFrame.Categories[index], sliderTimerTextYOffset);
        table_insert(GUIFrame.OnDBChangedHandlers, function() sliderTimerTextYOffset.editbox:SetText(tostring(addonTable.db.TimerTextYOffset)); sliderTimerTextYOffset.slider:SetValue(addonTable.db.TimerTextYOffset); end);
    end

    -- // colorPickerTimerTextMore
    do
        local colorPickerTimerTextMore = LRD.CreateColorPicker();
        colorPickerTimerTextMore:SetParent(GUIFrame);
        colorPickerTimerTextMore:SetPoint("TOPLEFT", 160, -250);
        colorPickerTimerTextMore:SetText(L["options:text:color"]);
        colorPickerTimerTextMore:SetColor(unpack(addonTable.db.TimerTextColor));

        colorPickerTimerTextMore.func = function(_, _r, _g, _b, _)
            addonTable.db.TimerTextColor = {_r, _g, _b};
            addonTable.OnDbChanged();
        end

        table_insert(GUIFrame.Categories[index], colorPickerTimerTextMore);
        table_insert(GUIFrame.OnDBChangedHandlers, function() colorPickerTimerTextMore.colorSwatch:SetVertexColor(unpack(addonTable.db.TimerTextColor)); end);
    end

end

local function ShowGUICategory(index)
    for _, v in pairs(GUIFrame.Categories) do
        for _, l in pairs(v) do
            l:Hide();
        end
    end
    for _, v in pairs(GUIFrame.Categories[index]) do
        v:Show();
    end
end

local function OnGUICategoryClick(self)
    GUIFrame.CategoryButtons[GUIFrame.ActiveCategory].text:SetTextColor(1, 0.82, 0);
    GUIFrame.CategoryButtons[GUIFrame.ActiveCategory]:UnlockHighlight();
    GUIFrame.ActiveCategory = self.index;
    self.text:SetTextColor(1, 1, 1);
    self:LockHighlight();
    PlaySound(SOUNDKIT.IG_MAINMENU_OPTION_CHECKBOX_ON);
    ShowGUICategory(GUIFrame.ActiveCategory);
end

local function CreateGUICategory()
    local b = CreateFrame("Button", nil, GUIFrame.outline);
    b:SetWidth(GUIFrame.outline:GetWidth()-8);
    b:SetHeight(18);
    b:SetScript("OnClick", OnGUICategoryClick);
    b:SetHighlightTexture("Interface\\QuestFrame\\UI-QuestTitleHighlight");
    b:GetHighlightTexture():SetAlpha(0.7);
    b.text = b:CreateFontString(nil, "ARTWORK", "GameFontNormal");
    b.text:SetPoint("LEFT", 3, 0);
    GUIFrame.CategoryButtons[#GUIFrame.CategoryButtons + 1] = b;
    return b;
end

local function GUICategory_General(index)
    local checkBoxFullOpacityAlways, checkboxShowCDOnAllies, checkboxShowInactiveCD, checkBoxIgnoreNameplateScale;
    local frameAnchors = { "TOPRIGHT", "RIGHT", "BOTTOMRIGHT", "TOP", "CENTER", "BOTTOM", "TOPLEFT", "LEFT", "BOTTOMLEFT" };
    local frameAnchorsLocalization = {
        [frameAnchors[1]] = L["anchor-point:topright"],
        [frameAnchors[2]] = L["anchor-point:right"],
        [frameAnchors[3]] = L["anchor-point:bottomright"],
        [frameAnchors[4]] = L["anchor-point:top"],
        [frameAnchors[5]] = L["anchor-point:center"],
        [frameAnchors[6]] = L["anchor-point:bottom"],
        [frameAnchors[7]] = L["anchor-point:topleft"],
        [frameAnchors[8]] = L["anchor-point:left"],
        [frameAnchors[9]] = L["anchor-point:bottomleft"]
    };

    local sliderIconSize;
    do
        local minValue, maxValue = 1, 100;
        sliderIconSize = LRD.CreateSlider();
        sliderIconSize:SetParent(GUIFrame.outline);
        sliderIconSize:SetHeight(100);
        sliderIconSize:SetPoint("TOPLEFT", GUIFrame.outline, "TOPRIGHT", 15, -15);
        sliderIconSize:SetPoint("TOPRIGHT", GUIFrame, "TOPRIGHT", -20, 0);
        sliderIconSize:GetTextObject():SetText(L["Icon size"]);
        sliderIconSize:GetBaseSliderObject():SetValueStep(1);
        sliderIconSize:GetBaseSliderObject():SetMinMaxValues(minValue, maxValue);
        sliderIconSize:GetBaseSliderObject():SetValue(addonTable.db.IconSize);
        sliderIconSize:GetBaseSliderObject():SetScript("OnValueChanged", function(_, value)
            sliderIconSize:GetEditboxObject():SetText(tostring(math_ceil(value)));
            addonTable.db.IconSize = math_ceil(value);
            addonTable.OnDbChanged();
        end);
        sliderIconSize:GetEditboxObject():SetText(tostring(addonTable.db.IconSize));
        sliderIconSize:GetEditboxObject():SetScript("OnEnterPressed", function()
            if (sliderIconSize:GetEditboxObject():GetText() ~= "") then
                local v = tonumber(sliderIconSize:GetEditboxObject():GetText());
                if (v == nil) then
                    sliderIconSize:GetEditboxObject():SetText(tostring(addonTable.db.IconSize));
                    addonTable.Print(L["Value must be a number"]);
                else
                    if (v > maxValue) then
                        v = maxValue;
                    end
                    if (v < minValue) then
                        v = minValue;
                    end
                    sliderIconSize:GetBaseSliderObject():SetValue(v);
                end
                sliderIconSize:GetEditboxObject():ClearFocus();
            end
        end);
        sliderIconSize:GetLowTextObject():SetText(tostring(minValue));
        sliderIconSize:GetHighTextObject():SetText(tostring(maxValue));
        table.insert(GUIFrame.Categories[index], sliderIconSize);
        table_insert(GUIFrame.OnDBChangedHandlers, function()
            sliderIconSize:GetBaseSliderObject():SetValue(addonTable.db.IconSize);
            sliderIconSize:GetEditboxObject():SetText(tostring(addonTable.db.IconSize));
        end);
    end

    local sliderIconSpacing;
    do
        local minValue, maxValue = 0, 50;
        sliderIconSpacing = LRD.CreateSlider();
        sliderIconSpacing:SetParent(GUIFrame.outline);
        sliderIconSpacing:SetWidth(sliderIconSize:GetWidth());
        sliderIconSpacing:SetPoint("TOP", sliderIconSize, "BOTTOM", 0, 45);
        sliderIconSpacing.label:SetText(L["options:general:space-between-icons"]);
        sliderIconSpacing.slider:SetValueStep(1);
        sliderIconSpacing.slider:SetMinMaxValues(minValue, maxValue);
        sliderIconSpacing.slider:SetValue(addonTable.db.IconSpacing);
        sliderIconSpacing.slider:SetScript("OnValueChanged", function(_, value)
            sliderIconSpacing.editbox:SetText(tostring(math_ceil(value)));
            addonTable.db.IconSpacing = math_ceil(value);
            addonTable.OnDbChanged();
        end);
        sliderIconSpacing.editbox:SetText(tostring(addonTable.db.IconSpacing));
        sliderIconSpacing.editbox:SetScript("OnEnterPressed", function()
            if (sliderIconSpacing.editbox:GetText() ~= "") then
                local v = tonumber(sliderIconSpacing.editbox:GetText());
                if (v == nil) then
                    sliderIconSpacing.editbox:SetText(tostring(addonTable.db.IconSpacing));
                    addonTable.msg(L["Value must be a number"]);
                else
                    if (v > maxValue) then
                        v = maxValue;
                    end
                    if (v < minValue) then
                        v = minValue;
                    end
                    sliderIconSpacing.slider:SetValue(v);
                end
                sliderIconSpacing.editbox:ClearFocus();
            end
        end);
        sliderIconSpacing.lowtext:SetText(tostring(minValue));
        sliderIconSpacing.hightext:SetText(tostring(maxValue));
        table_insert(GUIFrame.Categories[index], sliderIconSpacing);
        table_insert(GUIFrame.OnDBChangedHandlers, function() sliderIconSpacing.slider:SetValue(addonTable.db.IconSpacing); sliderIconSpacing.editbox:SetText(tostring(addonTable.db.IconSpacing)); end);
    end

    local sliderIconXOffset;
    do
        sliderIconXOffset = LRD.CreateSlider();
        sliderIconXOffset:SetParent(GUIFrame.outline);
        sliderIconXOffset:SetPoint("TOP", sliderIconSpacing, "BOTTOM", 0, 45);
        sliderIconXOffset:SetWidth(sliderIconSize:GetWidth());
        sliderIconXOffset:GetTextObject():SetText(L["Icon X-coord offset"]);
        sliderIconXOffset:GetBaseSliderObject():SetValueStep(1);
        sliderIconXOffset:GetBaseSliderObject():SetMinMaxValues(-200, 200);
        sliderIconXOffset:GetBaseSliderObject():SetValue(addonTable.db.IconXOffset);
        sliderIconXOffset:GetBaseSliderObject():SetScript("OnValueChanged", function(_, value)
            sliderIconXOffset:GetEditboxObject():SetText(tostring(math_ceil(value)));
            addonTable.db.IconXOffset = math_ceil(value);
            addonTable.OnDbChanged();
        end);
        sliderIconXOffset:GetEditboxObject():SetText(tostring(addonTable.db.IconXOffset));
        sliderIconXOffset:GetEditboxObject():SetScript("OnEnterPressed", function()
            if (sliderIconXOffset:GetEditboxObject():GetText() ~= "") then
                local v = tonumber(sliderIconXOffset:GetEditboxObject():GetText());
                if (v == nil) then
                    sliderIconXOffset:GetEditboxObject():SetText(tostring(addonTable.db.IconXOffset));
                    addonTable.Print(L["Value must be a number"]);
                else
                    if (v > 200) then
                        v = 200;
                    end
                    if (v < -200) then
                        v = -200;
                    end
                    sliderIconXOffset:GetBaseSliderObject():SetValue(v);
                end
                sliderIconXOffset:GetEditboxObject():ClearFocus();
            end
        end);
        sliderIconXOffset:GetLowTextObject():SetText("-200");
        sliderIconXOffset:GetHighTextObject():SetText("200");
        table.insert(GUIFrame.Categories[index], sliderIconXOffset);
        table_insert(GUIFrame.OnDBChangedHandlers, function() sliderIconXOffset:GetBaseSliderObject():SetValue(addonTable.db.IconXOffset); sliderIconXOffset:GetEditboxObject():SetText(tostring(addonTable.db.IconXOffset)); end);
    end

    local sliderIconYOffset;
    do
        sliderIconYOffset = LRD.CreateSlider();
        sliderIconYOffset:SetWidth(sliderIconSize:GetWidth());
        sliderIconYOffset:SetParent(GUIFrame.outline);
        sliderIconYOffset:SetPoint("TOP", sliderIconXOffset, "BOTTOM", 0, 45);
        sliderIconYOffset:GetTextObject():SetText(L["Icon Y-coord offset"]);
        sliderIconYOffset:GetBaseSliderObject():SetValueStep(1);
        sliderIconYOffset:GetBaseSliderObject():SetMinMaxValues(-200, 200);
        sliderIconYOffset:GetBaseSliderObject():SetValue(addonTable.db.IconYOffset);
        sliderIconYOffset:GetBaseSliderObject():SetScript("OnValueChanged", function(_, value)
            sliderIconYOffset:GetEditboxObject():SetText(tostring(math_ceil(value)));
            addonTable.db.IconYOffset = math_ceil(value);
            addonTable.OnDbChanged();
        end);
        sliderIconYOffset:GetEditboxObject():SetText(tostring(addonTable.db.IconYOffset));
        sliderIconYOffset:GetEditboxObject():SetScript("OnEnterPressed", function()
            if (sliderIconYOffset:GetEditboxObject():GetText() ~= "") then
                local v = tonumber(sliderIconYOffset:GetEditboxObject():GetText());
                if (v == nil) then
                    sliderIconYOffset:GetEditboxObject():SetText(tostring(addonTable.db.IconYOffset));
                    addonTable.Print(L["Value must be a number"]);
                else
                    if (v > 200) then
                        v = 200;
                    end
                    if (v < -200) then
                        v = -200;
                    end
                    sliderIconYOffset:GetBaseSliderObject():SetValue(v);
                end
                sliderIconYOffset:GetEditboxObject():ClearFocus();
            end
        end);
        sliderIconYOffset:GetLowTextObject():SetText("-200");
        sliderIconYOffset:GetHighTextObject():SetText("200");
        table.insert(GUIFrame.Categories[index], sliderIconYOffset);
        table_insert(GUIFrame.OnDBChangedHandlers, function() sliderIconYOffset:GetBaseSliderObject():SetValue(addonTable.db.IconYOffset); sliderIconYOffset:GetEditboxObject():SetText(tostring(addonTable.db.IconYOffset)); end);
    end

    local dropdownFrameAnchor;
    do
        dropdownFrameAnchor = CreateFrame("Frame", "NC.GUI.Fonts.DropdownFrameAnchor", GUIFrame, "UIDropDownMenuTemplate");
        UIDropDownMenu_SetWidth(dropdownFrameAnchor, 310);
        dropdownFrameAnchor:SetPoint("TOP", sliderIconYOffset, "BOTTOM", 0, 45);
        local info = {};
        dropdownFrameAnchor.initialize = function()
            wipe(info);
            for _, anchorPoint in pairs(frameAnchors) do
                info.text = frameAnchorsLocalization[anchorPoint];
                info.value = anchorPoint;
                info.func = function(self)
                    addonTable.db.CDFrameAnchor = self.value;
                    _G[dropdownFrameAnchor:GetName() .. "Text"]:SetText(self:GetText());
                    addonTable.OnDbChanged();
                end
                info.checked = anchorPoint == addonTable.db.CDFrameAnchor;
                UIDropDownMenu_AddButton(info);
            end
        end
        _G[dropdownFrameAnchor:GetName() .. "Text"]:SetText(frameAnchorsLocalization[addonTable.db.CDFrameAnchor]);
        dropdownFrameAnchor.text = dropdownFrameAnchor:CreateFontString(nil, "ARTWORK", "GameFontNormalSmall");
        dropdownFrameAnchor.text:SetPoint("LEFT", 20, 15);
        dropdownFrameAnchor.text:SetText(L["options:general:anchor-point"]);
        table_insert(GUIFrame.Categories[index], dropdownFrameAnchor);
        table_insert(GUIFrame.OnDBChangedHandlers, function() _G[dropdownFrameAnchor:GetName() .. "Text"]:SetText(frameAnchorsLocalization[addonTable.db.CDFrameAnchor]); end);
    end

    local dropdownFrameAnchorToParent
    do
        dropdownFrameAnchorToParent = CreateFrame("Frame", "NC.GUI.Fonts.DropdownFrameAnchorToParent", GUIFrame, "UIDropDownMenuTemplate");
        UIDropDownMenu_SetWidth(dropdownFrameAnchorToParent, 310);
        dropdownFrameAnchorToParent:SetPoint("TOP", dropdownFrameAnchor, "BOTTOM", 0, -5);
        local info = {};
        dropdownFrameAnchorToParent.initialize = function()
            wipe(info);
            for _, anchorPoint in pairs(frameAnchors) do
                info.text = frameAnchorsLocalization[anchorPoint];
                info.value = anchorPoint;
                info.func = function(self)
                    addonTable.db.CDFrameAnchorToParent = self.value;
                    _G[dropdownFrameAnchorToParent:GetName() .. "Text"]:SetText(self:GetText());
                    addonTable.OnDbChanged();
                end
                info.checked = anchorPoint == addonTable.db.CDFrameAnchorToParent;
                UIDropDownMenu_AddButton(info);
            end
        end
        _G[dropdownFrameAnchorToParent:GetName() .. "Text"]:SetText(frameAnchorsLocalization[addonTable.db.CDFrameAnchorToParent]);
        dropdownFrameAnchorToParent.text = dropdownFrameAnchorToParent:CreateFontString(nil, "ARTWORK", "GameFontNormalSmall");
        dropdownFrameAnchorToParent.text:SetPoint("LEFT", 20, 15);
        dropdownFrameAnchorToParent.text:SetText(L["options:general:anchor-point-to-parent"]);
        table_insert(GUIFrame.Categories[index], dropdownFrameAnchorToParent);
        table_insert(GUIFrame.OnDBChangedHandlers, function() _G[dropdownFrameAnchorToParent:GetName() .. "Text"]:SetText(frameAnchorsLocalization[addonTable.db.CDFrameAnchorToParent]); end);
    end

    local dropdownIconSortMode;
    do
        local sortModes = {
            [addonTable.SORT_MODE_NONE] = "none",
            [addonTable.SORT_MODE_TRINKET_INTERRUPT_OTHER] = "trinkets, then interrupts, then other spells",
            [addonTable.SORT_MODE_INTERRUPT_TRINKET_OTHER] = "interrupts, then trinkets, then other spells",
            [addonTable.SORT_MODE_TRINKET_OTHER] = "trinkets, then other spells",
            [addonTable.SORT_MODE_INTERRUPT_OTHER] = "interrupts, then other spells",
        };

        dropdownIconSortMode = CreateFrame("Frame", "NC.GUI.General.DropdownIconSortMode", GUIFrame, "UIDropDownMenuTemplate");
        UIDropDownMenu_SetWidth(dropdownIconSortMode, 310);
        dropdownIconSortMode:SetPoint("TOP", dropdownFrameAnchorToParent, "BOTTOM", 0, -5);
        local info = {};
        dropdownIconSortMode.initialize = function()
            wipe(info);
            for sortMode, sortModeL in pairs(sortModes) do
                info.text = sortModeL;
                info.value = sortMode;
                info.func = function(self)
                    addonTable.db.IconSortMode = self.value;
                    _G[dropdownIconSortMode:GetName().."Text"]:SetText(self:GetText());
                end
                info.checked = (addonTable.db.IconSortMode == info.value);
                UIDropDownMenu_AddButton(info);
            end
        end
        _G[dropdownIconSortMode:GetName().."Text"]:SetText(sortModes[addonTable.db.IconSortMode]);
        dropdownIconSortMode.text = dropdownIconSortMode:CreateFontString("NC.GUI.General.DropdownIconSortMode.Label", "ARTWORK", "GameFontNormalSmall");
        dropdownIconSortMode.text:SetPoint("LEFT", 20, 15);
        dropdownIconSortMode.text:SetText(L["general.sort-mode"]);
        table.insert(GUIFrame.Categories[index], dropdownIconSortMode);
        table_insert(GUIFrame.OnDBChangedHandlers, function() _G[dropdownIconSortMode:GetName().."Text"]:SetText(sortModes[addonTable.db.IconSortMode]); end);
    end

    local dropdownIconGrowDirection;
    do

        local iconGrowDirections = {
            [addonTable.ICON_GROW_DIRECTION_RIGHT] = L["icon-grow-direction:right"],
            [addonTable.ICON_GROW_DIRECTION_LEFT] = L["icon-grow-direction:left"],
            [addonTable.ICON_GROW_DIRECTION_UP] = L["icon-grow-direction:up"],
            [addonTable.ICON_GROW_DIRECTION_DOWN] = L["icon-grow-direction:down"],
        };

        dropdownIconGrowDirection = CreateFrame("Frame", "NC.GUI.General.DropdownIconGrowDirection", GUIFrame, "UIDropDownMenuTemplate");
        UIDropDownMenu_SetWidth(dropdownIconGrowDirection, 310);
        dropdownIconGrowDirection:SetPoint("TOP", dropdownIconSortMode, "BOTTOM", 0, -5);
        local info = {};
        dropdownIconGrowDirection.initialize = function()
            wipe(info);
            for direction, directionL in pairs(iconGrowDirections) do
                info.text = directionL;
                info.value = direction;
                info.func = function(self)
                    addonTable.db.IconGrowDirection = self.value;
                    _G[dropdownIconGrowDirection:GetName().."Text"]:SetText(self:GetText());
                    addonTable.OnDbChanged();
                end
                info.checked = (addonTable.db.IconGrowDirection == info.value);
                UIDropDownMenu_AddButton(info);
            end
        end
        _G[dropdownIconGrowDirection:GetName().."Text"]:SetText(iconGrowDirections[addonTable.db.IconGrowDirection]);
        dropdownIconGrowDirection.text = dropdownIconGrowDirection:CreateFontString("NC.GUI.General.DropdownIconGrowDirection.Label", "ARTWORK", "GameFontNormalSmall");
        dropdownIconGrowDirection.text:SetPoint("LEFT", 20, 15);
        dropdownIconGrowDirection.text:SetText(L["options:general:icon-grow-direction"]);
        table.insert(GUIFrame.Categories[index], dropdownIconGrowDirection);
        table_insert(GUIFrame.OnDBChangedHandlers, function() _G[dropdownIconGrowDirection:GetName().."Text"]:SetText(iconGrowDirections[addonTable.db.IconGrowDirection]); end);
    end

    -- // checkBoxFullOpacityAlways
    do
        checkBoxFullOpacityAlways = LRD.CreateCheckBox();
        checkBoxFullOpacityAlways:SetText(L["options:general:full-opacity-always"]);
        LRD.SetTooltip(checkBoxFullOpacityAlways, L["options:general:full-opacity-always:tooltip"]);
        checkBoxFullOpacityAlways:SetOnClickHandler(function(this)
            addonTable.db.FullOpacityAlways = this:GetChecked();
            addonTable.OnDbChanged();
        end);
        checkBoxFullOpacityAlways:SetParent(GUIFrame.outline);
        checkBoxFullOpacityAlways:SetPoint("TOPLEFT", dropdownIconGrowDirection, "BOTTOMLEFT", 0, -10);
        checkBoxFullOpacityAlways:SetChecked(addonTable.db.FullOpacityAlways);
        table.insert(GUIFrame.Categories[index], checkBoxFullOpacityAlways);
        table_insert(GUIFrame.OnDBChangedHandlers, function() checkBoxFullOpacityAlways:SetChecked(addonTable.db.FullOpacityAlways); end);
    end

    -- // checkBoxIgnoreNameplateScale
    do
        checkBoxIgnoreNameplateScale = LRD.CreateCheckBox();
        checkBoxIgnoreNameplateScale:SetText(L["options:general:ignore-nameplate-scale"]);
        LRD.SetTooltip(checkBoxIgnoreNameplateScale, L["options:general:ignore-nameplate-scale:tooltip"]);
        checkBoxIgnoreNameplateScale:SetOnClickHandler(function(this)
            addonTable.db.IgnoreNameplateScale = this:GetChecked();
            addonTable.OnDbChanged();
        end);
        checkBoxIgnoreNameplateScale:SetParent(GUIFrame.outline);
        checkBoxIgnoreNameplateScale:SetPoint("TOPLEFT", checkBoxFullOpacityAlways, "BOTTOMLEFT", 0, 0);
        checkBoxIgnoreNameplateScale:SetChecked(addonTable.db.IgnoreNameplateScale);
        table.insert(GUIFrame.Categories[index], checkBoxIgnoreNameplateScale);
        table_insert(GUIFrame.OnDBChangedHandlers, function() checkBoxIgnoreNameplateScale:SetChecked(addonTable.db.IgnoreNameplateScale); addonTable.OnDbChanged(); end);
    end

    -- checkboxShowCDOnAllies
    do
        checkboxShowCDOnAllies = LRD.CreateCheckBox();
        checkboxShowCDOnAllies:SetText(L["options:general:show-cd-on-allies"]);
        checkboxShowCDOnAllies:SetOnClickHandler(function(this)
            addonTable.db.ShowCDOnAllies = this:GetChecked();
        end);
        checkboxShowCDOnAllies:SetParent(GUIFrame.outline);
        checkboxShowCDOnAllies:SetPoint("TOPLEFT", checkBoxIgnoreNameplateScale, "BOTTOMLEFT", 0, 0);
        checkboxShowCDOnAllies:SetChecked(addonTable.db.ShowCDOnAllies);
        table.insert(GUIFrame.Categories[index], checkboxShowCDOnAllies);
        table_insert(GUIFrame.OnDBChangedHandlers, function() checkboxShowCDOnAllies:SetChecked(addonTable.db.ShowCDOnAllies); end);
    end

    -- checkboxShowInactiveCD
    do
        checkboxShowInactiveCD = LRD.CreateCheckBox();
        checkboxShowInactiveCD:SetText(L["options:general:show-inactive-cd"]);
        LRD.SetTooltip(checkboxShowInactiveCD, L["options:general:show-inactive-cd:tooltip"])
        checkboxShowInactiveCD:SetOnClickHandler(function(this)
            addonTable.db.ShowInactiveCD = this:GetChecked();
            addonTable.OnDbChanged();
        end);
        checkboxShowInactiveCD:SetParent(GUIFrame.outline);
        checkboxShowInactiveCD:SetPoint("TOPLEFT", checkboxShowCDOnAllies, "BOTTOMLEFT", 0, 0);
        checkboxShowInactiveCD:SetChecked(addonTable.db.ShowInactiveCD);
        table.insert(GUIFrame.Categories[index], checkboxShowInactiveCD);
        table_insert(GUIFrame.OnDBChangedHandlers, function() checkboxShowInactiveCD:SetChecked(addonTable.db.ShowInactiveCD); end);
    end

    local checkboxCooldownTooltip;
    do
        checkboxCooldownTooltip = LRD.CreateCheckBox();
        checkboxCooldownTooltip:SetText(L["options:general:show-cooldown-tooltip"]);
        checkboxCooldownTooltip:SetOnClickHandler(function(this)
            addonTable.db.ShowCooldownTooltip = this:GetChecked();
            addonTable.OnDbChanged();
            GameTooltip:Hide();
        end);
        checkboxCooldownTooltip:SetChecked(addonTable.db.ShowCooldownTooltip);
        checkboxCooldownTooltip:SetParent(GUIFrame.outline);
        checkboxCooldownTooltip:SetPoint("TOPLEFT", checkboxShowInactiveCD, "BOTTOMLEFT", 0, 0);
        table_insert(GUIFrame.Categories[index], checkboxCooldownTooltip);
        table_insert(GUIFrame.OnDBChangedHandlers, function() checkboxCooldownTooltip:SetChecked(addonTable.db.ShowCooldownTooltip); end);
    end

    local checkboxInverseLogic;
    do
        checkboxInverseLogic = LRD.CreateCheckBox();
        checkboxInverseLogic:SetText(L["options:general:inverse-logic"]);
        LRD.SetTooltip(checkboxInverseLogic, L["options:general:inverse-logic:tooltip"]);
        checkboxInverseLogic:SetOnClickHandler(function(this)
            addonTable.db.InverseLogic = this:GetChecked();
            addonTable.OnDbChanged();
        end);
        checkboxInverseLogic:SetChecked(addonTable.db.InverseLogic);
        checkboxInverseLogic:SetParent(GUIFrame.outline);
        checkboxInverseLogic:SetPoint("TOPLEFT", checkboxCooldownTooltip, "BOTTOMLEFT", 0, 0);
        table_insert(GUIFrame.Categories[index], checkboxInverseLogic);
        table_insert(GUIFrame.OnDBChangedHandlers, function() checkboxInverseLogic:SetChecked(addonTable.db.InverseLogic); end);
    end

    local checkboxCooldown;
    do
        checkboxCooldown = LRD.CreateCheckBox();
        checkboxCooldown:SetText(L["options:general:show-cooldown-animation"]);
        LRD.SetTooltip(checkboxCooldown, L["options:general:show-cooldown-animation:tooltip"]);
        checkboxCooldown:SetOnClickHandler(function(this)
            addonTable.db.ShowCooldownAnimation = this:GetChecked();
            addonTable.OnDbChanged();
        end);
        checkboxCooldown:SetChecked(addonTable.db.ShowCooldownAnimation);
        checkboxCooldown:SetParent(GUIFrame.outline);
        checkboxCooldown:SetPoint("TOPLEFT", checkboxInverseLogic, "BOTTOMLEFT", 0, 0);
        table_insert(GUIFrame.Categories[index], checkboxCooldown);
        table_insert(GUIFrame.OnDBChangedHandlers, function() checkboxCooldown:SetChecked(addonTable.db.ShowCooldownAnimation); end);
    end

end

local function GUICategory_Other(index)
    local controls = { };
    local selectedSpellId = 0;
    local dropdownMenuSpells = LRD.CreateDropdownMenu();
    local spellArea, selectSpell, checkboxEnabled, checkboxGlow, areaGlow, sliderGlowThreshold, dropdownClassSelector, areaCustomCD, checkboxCustomCD, editboxCustomCD;
    local selectedClass = addonTable.ALL_CLASSES;

    -- // spellArea
    do
        spellArea = CreateFrame("Frame", nil, GUIFrame, BackdropTemplateMixin and "BackdropTemplate");
        spellArea:SetBackdrop({
            bgFile = "Interface\\Tooltips\\UI-Tooltip-Background",
            edgeFile = "Interface\\Tooltips\\UI-Tooltip-Border",
            tile = 1,
            tileSize = 16,
            edgeSize = 16,
            insets = { left = 4, right = 4, top = 4, bottom = 4 }
        });
        spellArea:SetBackdropColor(0.1, 0.1, 0.2, 1);
        spellArea:SetBackdropBorderColor(0.8, 0.8, 0.9, 0.4);
        spellArea:SetPoint("TOPLEFT", GUIFrame.outline, "TOPRIGHT", 10, -35);
        spellArea:SetPoint("BOTTOMLEFT", GUIFrame.outline, "BOTTOMRIGHT", 10, 0);
        spellArea:SetWidth(360);

        spellArea.scrollArea = CreateFrame("ScrollFrame", nil, spellArea, "UIPanelScrollFrameTemplate");
        spellArea.scrollArea:SetPoint("TOPLEFT", spellArea, "TOPLEFT", 0, -3);
        spellArea.scrollArea:SetPoint("BOTTOMRIGHT", spellArea, "BOTTOMRIGHT", -8, 3);
        spellArea.scrollArea:Show();

        spellArea.controlsFrame = CreateFrame("Frame", nil, spellArea.scrollArea);
        spellArea.scrollArea:SetScrollChild(spellArea.controlsFrame);
        spellArea.controlsFrame:SetWidth(360);
        spellArea.controlsFrame:SetHeight(spellArea:GetHeight() + 150);

        spellArea.scrollBG = CreateFrame("Frame", nil, spellArea, BackdropTemplateMixin and "BackdropTemplate")
        spellArea.scrollBG:SetBackdrop({
            bgFile = [[Interface\Tooltips\UI-Tooltip-Background]],
            edgeFile = [[Interface\Tooltips\UI-Tooltip-Border]], edgeSize = 16,
            insets = { left = 4, right = 3, top = 4, bottom = 3 }
        });
        spellArea.scrollBG:SetBackdropColor(0, 0, 0)
        spellArea.scrollBG:SetBackdropBorderColor(0.4, 0.4, 0.4)
        spellArea.scrollBG:SetWidth(20);
        spellArea.scrollBG:SetHeight(spellArea.scrollArea:GetHeight());
        spellArea.scrollBG:SetPoint("TOPRIGHT", spellArea.scrollArea, "TOPRIGHT", 23, 0)

        table_insert(controls, spellArea);
    end

    -- // enable & disable all spells buttons
    do

        local enableAllSpellsButton = LRD.CreateButton();
        enableAllSpellsButton.clickedOnce = false;
        enableAllSpellsButton:SetParent(dropdownMenuSpells);
        enableAllSpellsButton:SetPoint("TOPLEFT", dropdownMenuSpells, "BOTTOMLEFT", 0, -10);
        enableAllSpellsButton:SetHeight(18);
        enableAllSpellsButton:SetWidth(dropdownMenuSpells:GetWidth() / 2 - 10);
        enableAllSpellsButton:SetText(L["options:spells:enable-all-spells"]);
        enableAllSpellsButton:SetScript("OnClick", function(self)
            if (self.clickedOnce) then
                for spellID in pairs(addonTable.db.SpellCDs) do
                    addonTable.db.SpellCDs[spellID].enabled = true;
                end
                addonTable.OnDbChanged();
                selectSpell:Click();
                self.clickedOnce = false;
                self:SetText(L["options:spells:enable-all-spells"]);
            else
                self.clickedOnce = true;
                self:SetText(L["options:spells:please-push-once-more"]);
                C_Timer_After(3, function()
                    self.clickedOnce = false;
                    self:SetText(L["options:spells:enable-all-spells"]);
                end);
            end
        end);
        enableAllSpellsButton:SetScript("OnHide", function(self)
            self.clickedOnce = false;
            self:SetText(L["options:spells:enable-all-spells"]);
        end);

        local disableAllSpellsButton = LRD.CreateButton();
        disableAllSpellsButton.clickedOnce = false;
        disableAllSpellsButton:SetParent(dropdownMenuSpells);
        disableAllSpellsButton:SetPoint("LEFT", enableAllSpellsButton, "RIGHT", 10, 0);
        disableAllSpellsButton:SetPoint("TOPRIGHT", dropdownMenuSpells, "BOTTOMRIGHT", 0, -10);
        disableAllSpellsButton:SetHeight(18);
        disableAllSpellsButton:SetText(L["options:spells:disable-all-spells"]);
        disableAllSpellsButton:SetScript("OnClick", function(self)
            if (self.clickedOnce) then
                for spellID in pairs(addonTable.db.SpellCDs) do
                    addonTable.db.SpellCDs[spellID].enabled = false;
                end
                addonTable.OnDbChanged();
                selectSpell:Click();
                self.clickedOnce = false;
                self:SetText(L["options:spells:disable-all-spells"]);
            else
                self.clickedOnce = true;
                self:SetText(L["options:spells:please-push-once-more"]);
                C_Timer_After(3, function()
                    self.clickedOnce = false;
                    self:SetText(L["options:spells:disable-all-spells"]);
                end);
            end
        end);
        disableAllSpellsButton:SetScript("OnHide", function(self)
            self.clickedOnce = false;
            self:SetText(L["options:spells:disable-all-spells"]);
        end);

    end

    local function HideGameTooltip()
        GameTooltip:Hide();
    end

    local function ResetSelectSpell()
        for _, control in pairs(controls) do
            control:Hide();
        end
        selectSpell.Text:SetText(L["options:spells:click-to-select-spell"]);
        selectSpell:SetScript("OnEnter", nil);
        selectSpell:SetScript("OnLeave", nil);
        selectSpell.icon:Hide();
    end

    local function OnSpellSelected(buttonInfo)
        local spellID = buttonInfo.info;
        for _, control in pairs(controls) do
            control:Show();
        end
        selectedSpellId = spellID;
        selectSpell.Text:SetText(SpellNameByID[spellID]);
        selectSpell:SetScript("OnEnter", function(self)
            GameTooltip:SetOwner(self, "ANCHOR_BOTTOMRIGHT");
            GameTooltip:SetSpellByID(spellID);
            GameTooltip:AddLine("NC CD: " .. addonTable.AllCooldowns[spellID]);
            GameTooltip:Show();
        end);
        selectSpell:HookScript("OnLeave", function() GameTooltip:Hide(); end);
        selectSpell.icon:SetTexture(SpellTextureByID[spellID]);
        selectSpell.icon:Show();
        checkboxEnabled:SetChecked(addonTable.db.SpellCDs[selectedSpellId].enabled);
        if (addonTable.db.SpellCDs[selectedSpellId].glow == nil) then
            checkboxGlow:SetTriState(0);
            sliderGlowThreshold:Hide();
            areaGlow:SetHeight(40);
        elseif (addonTable.db.SpellCDs[selectedSpellId].glow == addonTable.GLOW_TIME_INFINITE) then
            checkboxGlow:SetTriState(2);
            sliderGlowThreshold:Hide();
            areaGlow:SetHeight(40);
        else
            checkboxGlow:SetTriState(1);
            sliderGlowThreshold.slider:SetValue(addonTable.db.SpellCDs[selectedSpellId].glow);
            areaGlow:SetHeight(80);
        end
        if (addonTable.db.SpellCDs[selectedSpellId].customCD ~= nil) then
            checkboxCustomCD:SetChecked(true);
            areaCustomCD:SetHeight(80);
            editboxCustomCD:Show();
            editboxCustomCD:SetText(tostring(addonTable.db.SpellCDs[selectedSpellId].customCD));
        else
            checkboxCustomCD:SetChecked(false);
            areaCustomCD:SetHeight(40);
            editboxCustomCD:Hide();
        end
    end

    local function GetListForSpells()
        local t = { };
        for class, cds in pairs(addonTable.CDs) do
            for spellID in pairs(cds) do
                if (SpellNameByID[spellID] ~= nil) then
                    if (selectedClass == addonTable.ALL_CLASSES or selectedClass == class) then
                        local spellInfo = addonTable.db.SpellCDs[spellID] or addonTable.GetDefaultDBEntryForSpell();
                        table_insert(t, {
                            icon = SpellTextureByID[spellID],
                            text = SpellNameByID[spellID],
                            info = spellID,
                            disabled = not spellInfo.enabled,
                            onEnter = function(self)
                                GameTooltip:SetOwner(self, "ANCHOR_RIGHT");
                                GameTooltip:SetSpellByID(spellID);
                                GameTooltip:AddLine("NC CD: " .. addonTable.AllCooldowns[spellID]);
                                GameTooltip:Show();
                            end,
                            onLeave = HideGameTooltip,
                            func = OnSpellSelected,
                            checkBoxEnabled = true,
                            checkBoxState = spellInfo.enabled,
                            onCheckBoxClick = function(checkbox)
                                addonTable.db.SpellCDs[spellID].enabled = checkbox:GetChecked();
                                addonTable.OnDbChanged();
                                dropdownMenuSpells:GetButtonByText(SpellNameByID[spellID]):SetGray(not checkbox:GetChecked());
                            end,
                        });
                    end
                end
            end
        end
        table_sort(t, function(item1, item2) return item1.text < item2.text; end);
        return t;
    end

    -- // selectSpell
    do
        selectSpell = LRD.CreateButton();
        selectSpell:SetParent(GUIFrame);
        selectSpell:SetText(L["options:spells:click-to-select-spell"]);
        selectSpell:SetWidth(285);
        selectSpell:SetHeight(24);
        selectSpell.icon = selectSpell:CreateTexture(nil, "OVERLAY");
        selectSpell.icon:SetPoint("RIGHT", selectSpell.Text, "LEFT", -3, 0);
        selectSpell.icon:SetWidth(20);
        selectSpell.icon:SetHeight(20);
        selectSpell.icon:SetTexCoord(0.07, 0.93, 0.07, 0.93);
        selectSpell.icon:Hide();
        selectSpell:SetPoint("BOTTOMLEFT", spellArea, "TOPLEFT", 15, 5);
        selectSpell:SetPoint("BOTTOMRIGHT", spellArea, "TOPRIGHT", -15, 5);
        selectSpell:SetScript("OnClick", function(button)
            dropdownMenuSpells:SetList(GetListForSpells());
            dropdownMenuSpells:SetParent(button);
            dropdownMenuSpells:ClearAllPoints();
            dropdownMenuSpells:SetPoint("TOP", button, "BOTTOM", 0, -35);
            dropdownMenuSpells:SetSize(350, 370);
            dropdownMenuSpells:Show();
            dropdownMenuSpells.searchBox:SetFocus();
            dropdownMenuSpells.searchBox:SetText("");
            ResetSelectSpell();
            HideGameTooltip();
        end);
        selectSpell:SetScript("OnHide", function()
            ResetSelectSpell();
            dropdownMenuSpells:Hide();
        end);
        table_insert(GUIFrame.Categories[index], selectSpell);
    end

    -- // dropdownClassSelector
    do
        local classTokens = { };
        local classes = LocalizedClassList();
        classTokens[#classTokens+1] = addonTable.ALL_CLASSES;
        for token in pairs(classes) do
            classTokens[#classTokens+1] = token;
        end
        classTokens[#classTokens+1] = addonTable.UNKNOWN_CLASS;
        classes[addonTable.UNKNOWN_CLASS] = OTHER;
        classes[addonTable.ALL_CLASSES] = ALL;

        dropdownClassSelector = CreateFrame("Frame", "NC.GUI.Spell.dropdownClassSelector", dropdownMenuSpells, "UIDropDownMenuTemplate");
        UIDropDownMenu_SetWidth(dropdownClassSelector, 300);
        dropdownClassSelector:SetPoint("TOP", selectSpell, "BOTTOM", 0, -5);
        local info = {};
        dropdownClassSelector.initialize = function()
            wipe(info);
            for _, classToken in pairs(classTokens) do
                info.text = classes[classToken];
                info.value = classToken;
                info.func = function(self)
                    selectedClass = self.value;
                    dropdownMenuSpells:SetList(GetListForSpells());
                    _G[dropdownClassSelector:GetName().."Text"]:SetText(self:GetText());
                end
                info.checked = info.value == selectedClass;
                UIDropDownMenu_AddButton(info);
            end
        end
        _G[dropdownClassSelector:GetName().."Text"]:SetText(classes[selectedClass]);
        table.insert(GUIFrame.Categories[index], dropdownClassSelector);
    end

    -- // checkboxEnabled
    do
        checkboxEnabled = LRD.CreateCheckBox();
        checkboxEnabled:SetText(L["options:spells:enable-tracking-of-this-spell"]);
        checkboxEnabled:SetOnClickHandler(function(self)
            addonTable.db.SpellCDs[selectedSpellId].enabled = self:GetChecked();
            addonTable.OnDbChanged();
        end);
        checkboxEnabled:SetParent(spellArea.controlsFrame);
        checkboxEnabled:SetPoint("TOPLEFT", 15, -15);
        table_insert(controls, checkboxEnabled);
    end

    -- // areaGlow
    do
        areaGlow = CreateFrame("Frame", nil, spellArea.controlsFrame, BackdropTemplateMixin and "BackdropTemplate");
        areaGlow:SetBackdrop({
            bgFile = "Interface\\Tooltips\\UI-Tooltip-Background",
            edgeFile = "Interface\\Tooltips\\UI-Tooltip-Border",
            tile = 1,
            tileSize = 16,
            edgeSize = 16,
            insets = { left = 4, right = 4, top = 4, bottom = 4 }
        });
        areaGlow:SetBackdropColor(0.1, 0.1, 0.2, 1);
        areaGlow:SetBackdropBorderColor(0.8, 0.8, 0.9, 0.4);
        areaGlow:SetPoint("TOPLEFT", checkboxEnabled, "BOTTOMLEFT", 0, -10);
        areaGlow:SetWidth(340);
        areaGlow:SetHeight(80);
        table_insert(controls, areaGlow);
    end

    -- // checkboxGlow
    do
        checkboxGlow = LRD.CreateCheckBoxTristate();
        checkboxGlow:SetTextEntries({
            addonTable.colorize_text(L["options:spells:icon-glow"], 1, 1, 1),
            addonTable.colorize_text(L["options:spells:icon-glow-threshold"], 0, 1, 1),
            addonTable.colorize_text(L["options:spells:icon-glow-always"], 0, 1, 0),
        });
        checkboxGlow:SetOnClickHandler(function(self)
            if (self:GetTriState() == 0) then
                addonTable.db.SpellCDs[selectedSpellId].glow = nil; -- // making addonTable.db smaller
                sliderGlowThreshold:Hide();
                areaGlow:SetHeight(40);
            elseif (self:GetTriState() == 1) then
                addonTable.db.SpellCDs[selectedSpellId].glow = 5;
                sliderGlowThreshold:Show();
                sliderGlowThreshold.slider:SetValue(5);
                areaGlow:SetHeight(80);
            else
                addonTable.db.SpellCDs[selectedSpellId].glow = addonTable.GLOW_TIME_INFINITE;
                sliderGlowThreshold:Hide();
                areaGlow:SetHeight(40);
            end
            addonTable.OnDbChanged();
        end);
        checkboxGlow:SetParent(areaGlow);
        checkboxGlow:SetPoint("TOPLEFT", 10, -10);
        table_insert(controls, checkboxGlow);
    end

    -- // sliderGlowThreshold
    do
        local minV, maxV = 1, 30;
        sliderGlowThreshold = LRD.CreateSlider();
        sliderGlowThreshold:SetParent(areaGlow);
        sliderGlowThreshold:SetWidth(320);
        sliderGlowThreshold:SetPoint("TOPLEFT", 18, -23);
        sliderGlowThreshold.label:ClearAllPoints();
        sliderGlowThreshold.label:SetPoint("CENTER", sliderGlowThreshold, "CENTER", 0, 15);
        sliderGlowThreshold.label:SetText();
        sliderGlowThreshold:ClearAllPoints();
        sliderGlowThreshold:SetPoint("TOPLEFT", areaGlow, "TOPLEFT", 10, 5);
        sliderGlowThreshold.slider:ClearAllPoints();
        sliderGlowThreshold.slider:SetPoint("LEFT", 3, 0)
        sliderGlowThreshold.slider:SetPoint("RIGHT", -3, 0)
        sliderGlowThreshold.slider:SetValueStep(1);
        sliderGlowThreshold.slider:SetMinMaxValues(minV, maxV);
        sliderGlowThreshold.slider:SetScript("OnValueChanged", function(_, value)
            sliderGlowThreshold.editbox:SetText(tostring(math_ceil(value)));
            addonTable.db.SpellCDs[selectedSpellId].glow = math_ceil(value);
            addonTable.OnDbChanged();
        end);
        sliderGlowThreshold.editbox:SetScript("OnEnterPressed", function()
            if (sliderGlowThreshold.editbox:GetText() ~= "") then
                local v = tonumber(sliderGlowThreshold.editbox:GetText());
                if (v == nil) then
                    sliderGlowThreshold.editbox:SetText(tostring(addonTable.db.SpellCDs[selectedSpellId].glow));
                    addonTable.Print(L["Value must be a number"]);
                else
                    if (v > maxV) then
                        v = maxV;
                    end
                    if (v < minV) then
                        v = minV;
                    end
                    sliderGlowThreshold.slider:SetValue(v);
                end
                sliderGlowThreshold.editbox:ClearFocus();
            end
        end);
        sliderGlowThreshold.lowtext:SetText("1");
        sliderGlowThreshold.hightext:SetText("30");
        table_insert(controls, sliderGlowThreshold);
    end

    -- // areaCustomCD
    do
        areaCustomCD = CreateFrame("Frame", nil, spellArea.controlsFrame, BackdropTemplateMixin and "BackdropTemplate");
        areaCustomCD:SetBackdrop({
            bgFile = "Interface\\Tooltips\\UI-Tooltip-Background",
            edgeFile = "Interface\\Tooltips\\UI-Tooltip-Border",
            tile = 1,
            tileSize = 16,
            edgeSize = 16,
            insets = { left = 4, right = 4, top = 4, bottom = 4 }
        });
        areaCustomCD:SetBackdropColor(0.1, 0.1, 0.2, 1);
        areaCustomCD:SetBackdropBorderColor(0.8, 0.8, 0.9, 0.4);
        areaCustomCD:SetPoint("TOPLEFT", areaGlow, "BOTTOMLEFT", 0, -10);
        areaCustomCD:SetWidth(340);
        areaCustomCD:SetHeight(80);
        table_insert(controls, areaCustomCD);
    end

    -- // checkboxCustomCD
    do
        checkboxCustomCD = LRD.CreateCheckBox();
        checkboxCustomCD:SetText(L["options:spells:custom-cooldown"]);
        checkboxCustomCD:SetOnClickHandler(function(self)
            if (not self:GetChecked()) then
                addonTable.db.SpellCDs[selectedSpellId].customCD = nil;
                addonTable.BuildCooldownValues();
                areaCustomCD:SetHeight(40);
                editboxCustomCD:Hide();
            else
                areaCustomCD:SetHeight(80);
                editboxCustomCD:Show();
            end
        end);
        checkboxCustomCD:SetParent(areaCustomCD);
        checkboxCustomCD:SetPoint("TOPLEFT", 10, -10);
        table_insert(controls, checkboxCustomCD);
    end

    -- // editboxCustomCD
    do
        editboxCustomCD = CreateFrame("EditBox", nil, areaCustomCD, BackdropTemplateMixin and "BackdropTemplate");
        editboxCustomCD:SetAutoFocus(false);
        editboxCustomCD:SetFontObject(GameFontHighlightSmall);
        editboxCustomCD.text = editboxCustomCD:CreateFontString(nil, "ARTWORK", "GameFontNormal");
        editboxCustomCD.text:SetPoint("TOPLEFT", checkboxCustomCD, "BOTTOMRIGHT", 0, -10);
        editboxCustomCD.text:SetText(L["options:spells:custom-cooldown-value"]);
        editboxCustomCD:SetPoint("LEFT", editboxCustomCD.text, "RIGHT", 5, 0);
        editboxCustomCD:SetPoint("RIGHT", areaCustomCD, "RIGHT", -15, 0);
        editboxCustomCD:SetHeight(20);
        editboxCustomCD:SetJustifyH("LEFT");
        editboxCustomCD:EnableMouse(true);
        editboxCustomCD:SetBackdrop({
            bgFile = "Interface\\ChatFrame\\ChatFrameBackground",
            edgeFile = "Interface\\ChatFrame\\ChatFrameBackground",
            tile = true, edgeSize = 1, tileSize = 5,
        });
        editboxCustomCD:SetBackdropColor(0, 0, 0, 0.5);
        editboxCustomCD:SetBackdropBorderColor(0.3, 0.3, 0.30, 0.80);
        editboxCustomCD:SetScript("OnEscapePressed", function() editboxCustomCD:ClearFocus(); end);
        editboxCustomCD:SetScript("OnEnterPressed", function(self)
            local text = self:GetText();
            local value = tonumber(text);
            if (value ~= nil) then
                addonTable.db.SpellCDs[selectedSpellId].customCD = value;
                addonTable.BuildCooldownValues();
            end
            self:ClearFocus();
        end);
        table_insert(controls, editboxCustomCD);
    end

    -- // building spell cache
    do
        local frame = CreateFrame("frame", nil, GUIFrame, BackdropTemplateMixin and "BackdropTemplate");
        frame:SetBackdrop({
            bgFile = "Interface\\Tooltips\\UI-Tooltip-Background",
            edgeFile = "Interface\\Tooltips\\UI-Tooltip-Border",
            tile = 1,
            tileSize = 16,
            edgeSize = 16,
            insets = { left = 4, right = 4, top = 4, bottom = 4 }
        });
        frame:SetBackdropColor(0.1, 0.1, 0.2, 1);
        frame:SetBackdropBorderColor(0.8, 0.8, 0.9, 0.4);
        frame:SetPoint("TOP", GUIFrame, "BOTTOM", 0, 0);
        frame:SetWidth(GUIFrame:GetWidth()/2);
        frame:SetHeight(40);
        frame.text = frame:CreateFontString(nil, "ARTWORK", "GameFontNormal");
        frame.text:SetPoint("CENTER", frame, "CENTER", 5, 0);
        frame:Hide();

        GUIFrame:HookScript("OnShow", function()
            frame:Show();
            selectSpell:Disable();
            local scanAllSpells = coroutine.create(function()
                local id = 0;
                local maxId = 2*1000*1000;
                while (id < maxId) do
                    id = id + 1;
                    local spellInfo = GetSpellInfo(id);
                    local name = spellInfo ~= nil and spellInfo.name or nil;
                    local icon = spellInfo ~= nil and spellInfo.iconID or nil;
                    if (name and name ~= "") then
                        if (AllSpellIDsAndIconsByName[name] == nil) then AllSpellIDsAndIconsByName[name] = { }; end
                        AllSpellIDsAndIconsByName[name][id] = icon;
                    end
                    if (id % (maxId/100) == 0) then
                        frame.text:SetText(string_format(L["options:building-cache"], math_ceil(id*100/maxId)));
                    end
                    coroutine.yield();
                end
                if (not addonTable.TestModeActive) then
                    selectSpell:Enable();
                end
                frame:Hide();
            end);
            addonTable.coroutine_queue("scanAllSpells", scanAllSpells);
        end);
        GUIFrame:HookScript("OnHide", function()
            addonTable.coroutine_delete("scanAllSpells");
            wipe(AllSpellIDsAndIconsByName);
        end);
    end

    hooksecurefunc(addonTable, "EnableTestMode", function()
      if (selectSpell:IsVisible()) then
          for _, button in pairs(GUIFrame.CategoryButtons) do
              if (button.text:GetText() == L["options:category:spells"]) then
                  button:Click();
              end
          end
      end
      selectSpell:Disable();
      selectSpell:SetText(L["options:spells:click-to-select-spell:test-mode"]);
    end);
    hooksecurefunc(addonTable, "DisableTestMode", function()
      selectSpell:SetText(L["options:spells:click-to-select-spell"]);
      selectSpell:Enable();
    end);

end

local function InitializeGUI()
    GUIFrame = CreateFrame("Frame", "NC_GUIFrame", UIParent, BackdropTemplateMixin and "BackdropTemplate");
    GUIFrame:SetHeight(560);
    GUIFrame:SetWidth(540);
    GUIFrame:SetPoint("CENTER", UIParent, "CENTER", 0, 80);
    GUIFrame:SetBackdrop({
        bgFile = "Interface\\ChatFrame\\ChatFrameBackground",
        edgeFile = "Interface\\Tooltips\\UI-Tooltip-Border",
        tile = 1,
        tileSize = 16,
        edgeSize = 16,
        insets = { left = 3, right = 3, top = 3, bottom = 3 }
    });
    GUIFrame:SetBackdropColor(0.25, 0.24, 0.32, 1);
    GUIFrame:SetBackdropBorderColor(0.1,0.1,0.1,1);
    GUIFrame:EnableMouse(1);
    GUIFrame:SetMovable(1);
    GUIFrame:SetFrameStrata("DIALOG");
    GUIFrame:SetToplevel(1);
    GUIFrame:SetClampedToScreen(1);
    GUIFrame:SetScript("OnMouseDown", function() GUIFrame:StartMoving(); end);
    GUIFrame:SetScript("OnMouseUp", function() GUIFrame:StopMovingOrSizing(); end);
    GUIFrame:Hide();

    GUIFrame.CategoryButtons = {};
    GUIFrame.ActiveCategory = 1;

    local header = GUIFrame:CreateFontString("NC_GUIHeader", "ARTWORK", "GameFontHighlight");
    header:SetFont(GameFontNormal:GetFont(), 22, "THICKOUTLINE");
    header:SetPoint("BOTTOM", GUIFrame, "TOP", 0, 0);
    header:SetText("NameplateCooldowns");

    GUIFrame.outline = CreateFrame("Frame", nil, GUIFrame, BackdropTemplateMixin and "BackdropTemplate");
    GUIFrame.outline:SetBackdrop({
        bgFile = "Interface\\Tooltips\\UI-Tooltip-Background",
        edgeFile = "Interface\\Tooltips\\UI-Tooltip-Border",
        tile = 1,
        tileSize = 16,
        edgeSize = 16,
        insets = { left = 4, right = 4, top = 4, bottom = 4 }
    });
    GUIFrame.outline:SetBackdropColor(0.1, 0.1, 0.2, 1);
    GUIFrame.outline:SetBackdropBorderColor(0.8, 0.8, 0.9, 0.4);
    GUIFrame.outline:SetPoint("TOPLEFT", 12, -12);
    GUIFrame.outline:SetPoint("BOTTOMLEFT", 12, 12);
    GUIFrame.outline:SetWidth(140);

    local closeButton = CreateFrame("Button", "NC_GUICloseButton", GUIFrame, "UIPanelButtonTemplate");
    closeButton:SetWidth(24);
    closeButton:SetHeight(24);
    closeButton:SetPoint("TOPRIGHT", 0, 22);
    closeButton:SetScript("OnClick", function() GUIFrame:Hide(); end);
    closeButton.text = closeButton:CreateFontString(nil, "ARTWORK", "GameFontNormal");
    closeButton.text:SetPoint("CENTER", closeButton, "CENTER", 1, -1);
    closeButton.text:SetText("X");

    GUIFrame.Categories = {};
    GUIFrame.SpellIcons = {};
    GUIFrame.OnDBChangedHandlers = { };

    for index, value in pairs({ L["General"], L["Filters"], L["options:category:borders"], L["options:category:text"], L["options:category:spells"] }) do
        local b = CreateGUICategory();
        b.index = index;
        b.text:SetText(value);
        if (index == 1) then
            b:LockHighlight();
            b.text:SetTextColor(1, 1, 1);
        end
        if (index < 6) then
            b:SetPoint("TOPLEFT", GUIFrame.outline, "TOPLEFT", 5, (index-1) * -18 - 6);
        else
            b:SetPoint("TOPLEFT", GUIFrame.outline, "TOPLEFT", 5, (index-1) * -18 - 26);
        end

        GUIFrame.Categories[index] = {};

        if (value == L["General"]) then
            GUICategory_General(index, value);
        elseif (value == L["Filters"]) then
            GUICategory_Filters(index, value);
        elseif (value == L["options:category:borders"]) then
            GUICategory_Borders(index, value);
        elseif (value == L["options:category:text"]) then
            GUICategory_Text(index, value);
        else
            GUICategory_Other(index, value);
        end
    end

    local buttonTestMode;
    do
        buttonTestMode = LRD.CreateButton();
        buttonTestMode:SetParent(GUIFrame.outline);
        buttonTestMode:SetText(L["options:general:test-mode"]);
        buttonTestMode:SetPoint("BOTTOMLEFT", GUIFrame.outline, "BOTTOMLEFT", 4, 4);
        buttonTestMode:SetPoint("BOTTOMRIGHT", GUIFrame.outline, "BOTTOMRIGHT", -4, 4);
        buttonTestMode:SetHeight(30);
        buttonTestMode:SetScript("OnClick", function()
            if (not addonTable.TestModeActive) then
                addonTable.EnableTestMode();
            else
                addonTable.DisableTestMode();
            end
        end);
    end

    local buttonProfiles;
    do
        buttonProfiles = LRD.CreateButton();
        buttonProfiles:SetParent(GUIFrame.outline);
        buttonProfiles:SetText(L["options:profiles"]);
        buttonProfiles:SetHeight(30);
        buttonProfiles:SetPoint("BOTTOMLEFT", buttonTestMode, "TOPLEFT", 0, 0);
        buttonProfiles:SetPoint("BOTTOMRIGHT", buttonTestMode, "TOPRIGHT", 0, 0);
        buttonProfiles:SetScript("OnClick", function()
            LibStub("AceConfigDialog-3.0"):Open("NameplateCooldowns.profiles");
            GUIFrame:Hide();
        end);
    end
end

function addonTable.GuiOnDbReload()
    if (GUIFrame) then
        for _, func in pairs(GUIFrame.OnDBChangedHandlers) do
            func();
        end
    end
end

function addonTable.ShowGUI()
    if (not InCombatLockdown()) then
        if (not GUIFrame) then
            InitializeGUI();
        end
        GUIFrame:Show();
        OnGUICategoryClick(GUIFrame.CategoryButtons[1]);
    else
        addonTable.Print(L["Options are not available in combat!"]);
    end
end
