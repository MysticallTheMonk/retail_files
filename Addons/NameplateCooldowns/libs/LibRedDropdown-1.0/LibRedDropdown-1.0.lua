-- luacheck: no max line length
-- luacheck: globals LibStub IndentationLib CreateFrame UIParent BackdropTemplateMixin Spell hooksecurefunc GameFontHighlightSmall unpack GetBuildInfo CLOSE ColorPickerFrame
-- luacheck: globals OpacitySliderFrame ChatFontNormal ACCEPT INFO C_Spell

local wowBuild = select(4, GetBuildInfo());

local LIB_NAME = "LibRedDropdown-1.0";
local lib = LibStub:NewLibrary(LIB_NAME, 22);
if (not lib) then return; end -- No upgrade needed

local table_insert, string_find, string_format, max = table.insert, string.find, string.format, math.max;
local C_Spell_GetSpellTexture =  C_Spell.GetSpellTexture;

local IndentationLib = IndentationLib;

local BUTTON_COLOR_NORMAL = {0.38, 0, 0, 1};

local function table_contains_value(t, v)
	for _, value in pairs(t) do
		if (value == v) then
			return true;
		end
	end
	return false;
end

local function ColorizeText(text, r, g, b)
	return string_format("|cff%02x%02x%02x%s|r", r*255, g*255, b*255, text);
end

function lib.CreateDropdownMenu()
	local SPACE_BETWEEN_BUTTON_AND_CLOSEBUTTON = 3;
	local SCROLL_AREA_Y_OFFSET = -30;

	local selectorEx = CreateFrame("Frame", nil, UIParent, BackdropTemplateMixin and "BackdropTemplate");
	selectorEx:SetPoint("CENTER", UIParent, "CENTER", 0, 0);
	selectorEx:SetSize(350, 300);
	selectorEx:SetBackdrop({
		bgFile = "Interface\\Tooltips\\UI-Tooltip-Background",
		edgeFile = "Interface\\Tooltips\\UI-Tooltip-Border",
		tile = 1,
		tileSize = 16,
		edgeSize = 16,
		insets = { left = 4, right = 4, top = 4, bottom = 4 }
	});
	selectorEx:SetBackdropColor(0.1, 0.1, 0.2, 1);
	selectorEx:SetBackdropBorderColor(0.8, 0.8, 0.9, 0.4);

	selectorEx.customSearchHandler = nil;
	selectorEx.searchBox = CreateFrame("EditBox", nil, selectorEx, "InputBoxTemplate");
	selectorEx.searchBox:SetAutoFocus(false);
	selectorEx.searchBox:SetFontObject(GameFontHighlightSmall);
	selectorEx.searchBox:SetPoint("TOPLEFT", selectorEx, "TOPLEFT", 10, -5);
	selectorEx.searchBox:SetPoint("RIGHT", selectorEx, "RIGHT", -10, 0);
	selectorEx.searchBox:SetHeight(20);
	selectorEx.searchBox:SetWidth(175);
	selectorEx.searchBox:SetJustifyH("LEFT");
	selectorEx.searchBox:EnableMouse(true);
	selectorEx.searchBox:SetScript("OnEscapePressed", function() selectorEx.searchBox:ClearFocus(); end);
	selectorEx.searchBox:SetScript("OnTextChanged", function(self)
		local text = self:GetText();
		if (text == "") then
			selectorEx:SetList(selectorEx.list);
		else
			local t = { };
			if (selectorEx.customSearchHandler == nil) then
				for _, value in pairs(selectorEx.list) do
					if (string_find(value.text:lower(), text:lower())) then
						table_insert(t, value);
					end
				end
			else
				t = selectorEx.customSearchHandler(text);
			end

			selectorEx:SetList(t, true);
			selectorEx.scrollArea:SetVerticalScroll(0);
		end
	end);
	local searchBoxText = selectorEx.searchBox:CreateFontString(nil, "ARTWORK", "GameFontDisable");
	searchBoxText:SetPoint("LEFT", 0, 0);
	searchBoxText:SetText("Click to search...");
	selectorEx.searchBox:SetScript("OnEditFocusGained", function() searchBoxText:Hide(); end);
	selectorEx.searchBox:SetScript("OnEditFocusLost", function()
		local text = selectorEx.searchBox:GetText();
		if (text == nil or text == "") then
			searchBoxText:Show();
		end
	end);
	selectorEx.searchBox.hint = CreateFrame("Frame", nil, selectorEx.searchBox);
	selectorEx.searchBox.hint:SetWidth(selectorEx.searchBox:GetHeight());
	selectorEx.searchBox.hint:SetHeight(selectorEx.searchBox:GetHeight());
	selectorEx.searchBox.hint:SetPoint("RIGHT", selectorEx.searchBox, "RIGHT", -4, 0);
	selectorEx.searchBox.hint.texture = selectorEx.searchBox.hint:CreateTexture(nil, "OVERLAY");
	selectorEx.searchBox.hint.texture:SetTexture("Interface\\common\\help-i");
	selectorEx.searchBox.hint.texture:SetAllPoints(selectorEx.searchBox.hint);
	selectorEx.searchBox.hint:Hide();

	selectorEx.scrollArea = CreateFrame("ScrollFrame", nil, selectorEx, "UIPanelScrollFrameTemplate");
	selectorEx.scrollArea:SetPoint("TOPLEFT", selectorEx, "TOPLEFT", 5, SCROLL_AREA_Y_OFFSET);
	selectorEx.scrollArea:SetPoint("BOTTOMRIGHT", selectorEx, "BOTTOMRIGHT", -30, 5);
	selectorEx.scrollArea:Show();

	selectorEx.scrollAreaChildFrame = CreateFrame("Frame", nil, selectorEx.scrollArea);
	selectorEx.scrollArea:SetScrollChild(selectorEx.scrollAreaChildFrame);
	selectorEx.scrollAreaChildFrame:SetWidth(selectorEx.scrollArea:GetWidth() - 10);
	selectorEx.scrollAreaChildFrame:SetHeight(288);

	selectorEx.buttons = { };
	selectorEx.list = { };
	selectorEx.currentPosition = -1;

	local function GetButton(s, counter)
		if (s.buttons[counter] == nil) then
			local line = CreateFrame("frame", nil, s.scrollAreaChildFrame);
			line:SetHeight(20);
			line:SetPoint("TOPLEFT", 5, -counter * 22 + 20);
			line:SetPoint("RIGHT", 0, 0);
			line:Show();
			local button = lib.CreateButton();
			local originalShow = button.Show;
			button.Show = function(self) originalShow(self); line:Show(); end
			local originalHide = button.Hide;
			button.Hide = function(self) originalHide(self); line:Hide(); end
			button:SetParent(line);
			button.font, button.fontSize, button.fontFlags = button.Text:GetFont();

			button.Icon = button:CreateTexture();
			button.Icon:SetTexCoord(0.07, 0.93, 0.07, 0.93);
			button.Icon:SetPoint("LEFT", line, "LEFT", 0, 0);
			button.Icon:SetWidth(line:GetHeight());
			button.Icon:SetHeight(line:GetHeight());

			button.closeButton = lib.CreateButton();
			button.closeButton:SetParent(line);
			button.closeButton:SetWidth(line:GetHeight());
			button.closeButton:SetHeight(line:GetHeight());
			button.closeButton:SetPoint("RIGHT", line, "RIGHT", 0, 0);
			button.closeButton.Text:SetText("X");

			button:SetHeight(line:GetHeight());
			button:SetPoint("LEFT", button.Icon, "RIGHT", SPACE_BETWEEN_BUTTON_AND_CLOSEBUTTON, 0);
			button:SetPoint("RIGHT", button.closeButton, "LEFT", -SPACE_BETWEEN_BUTTON_AND_CLOSEBUTTON, 0);
			button:Hide();

			s.buttons[counter] = button;
			return button;
		else
			return s.buttons[counter];
		end
	end

	-- value.text, value.font, value.icon, value.func, value.onEnter, value.onLeave, value.disabled, value.dontCloseOnClick, value.checkBoxEnabled,
	--value.onCheckBoxClick, value.checkBoxState, onCloseButtonClick, buttonColor
	selectorEx.SetList = function(s, t, dontUpdateInternalList)
		for _, button in pairs(s.buttons) do
			button:SetGray(false);
			button:Hide();
			button.Text:SetFont(button.font, button.fontSize, button.fontFlags);
			button.Text:SetText(); -- not tested
			button.closeButton:Hide();
			button.closeButton:SetScript("OnClick", nil);
			button:SetScript("OnClick", nil);
			button:SetCheckBoxVisible(false);
			button.Normal:SetColorTexture(unpack(BUTTON_COLOR_NORMAL));
		end
		local counter = 1;
		for _, value in pairs(t) do
			local button = GetButton(s, counter);
			button.Text:SetText(value.text);
			if (value.font ~= nil) then
				button.Text:SetFont(value.font, button.fontSize, button.fontFlags);
			end
			if (value.disabled) then
				button:SetGray(true);
			end
			if (value.icon ~= nil) then
				button.Icon:SetTexture(value.icon);
				button.Icon:Show();
				button:SetPoint("LEFT", button.Icon, "RIGHT", SPACE_BETWEEN_BUTTON_AND_CLOSEBUTTON, 0);
			else
				button.Icon:Hide();
				button:SetPoint("LEFT", button:GetParent(), "LEFT", 0, 0);
			end
			if (value.func ~= nil) then
				button:SetScript("OnClick", function()
					value:func();
					if (not value.dontCloseOnClick) then
						s:Hide();
					end
				end);
			end
			if (value.checkBoxEnabled) then
				button:SetCheckBoxVisible(true);
				button:SetCheckBoxOnClickHandler(value.onCheckBoxClick);
				button:SetChecked(value.checkBoxState);
			end
			if (value.onCloseButtonClick ~= nil) then
				button.closeButton:Show();
				button:SetPoint("RIGHT", button.closeButton, "LEFT", -SPACE_BETWEEN_BUTTON_AND_CLOSEBUTTON, 0);
				button.closeButton:SetScript("OnClick", function()
					value:onCloseButtonClick();
				end);
			else
				button.closeButton:Hide();
				button:SetPoint("RIGHT", button:GetParent(), "RIGHT", 0, 0);
			end
			if (value.buttonColor ~= nil) then
				button.Normal:SetColorTexture(unpack(value.buttonColor));
			end
			button:SetScript("OnEnter", value.onEnter);
			button:SetScript("OnLeave", value.onLeave);
			button:Show();
			counter = counter + 1;
		end
		if (not dontUpdateInternalList) then
			s.list = t;
		end
	end

	selectorEx.GetButtonByText = function(s, text)
		for _, button in pairs(s.buttons) do
			if (button.Text:GetText() == text) then
				return button;
			end
		end
		return nil;
	end

	selectorEx.SetCustomSearchHandler = function(_self, _handler)
		_self.customSearchHandler = _handler;
	end

	selectorEx.SetSearchBoxHint = function(_self, _hint)
		if (_hint ~= nil and _hint ~= "") then
			_self.searchBox.hint:Show();
			lib.SetTooltip(_self.searchBox.hint, _hint, "LEFT");
		else
			_self.searchBox.hint:Hide();
		end
	end

	selectorEx.GetList = function(_self)
		return _self.list;
	end

	selectorEx:SetList({});
	selectorEx:Hide();
	selectorEx:HookScript("OnShow", function(self)
		self:SetFrameStrata("TOOLTIP");

		if (self.autoAdjustHeight and #self.buttons > 0) then
			local _, _, _, _, yOffset = self.buttons[#self.buttons]:GetPoint();
			self:SetHeight(-SCROLL_AREA_Y_OFFSET + -yOffset + self.buttons[#self.buttons]:GetHeight() + 10);
		end

		self.scrollArea:SetVerticalScroll(self.currentPosition == -1 and 0 or self.currentPosition);
		self.scrollAreaChildFrame:SetWidth(self.scrollArea:GetWidth());
		self.scrollAreaChildFrame:SetHeight(self:GetHeight() - 12);
	end);
	selectorEx:HookScript("OnHide", function(self)
		self.searchBox:SetText("");
		self.currentPosition = self.scrollArea:GetVerticalScroll();
	end);

	return selectorEx;
end

function lib.CreateDropdownMenu2()
	local SPACE_BETWEEN_BUTTON_AND_CLOSEBUTTON = 3;
	local SCROLL_AREA_Y_OFFSET = -30;

	local selectorEx = CreateFrame("Frame", nil, UIParent, BackdropTemplateMixin and "BackdropTemplate");
	selectorEx:SetPoint("CENTER", UIParent, "CENTER", 0, 0);
	selectorEx:SetSize(350, 300);
	selectorEx:SetBackdrop({
		bgFile = "Interface\\Tooltips\\UI-Tooltip-Background",
		edgeFile = "Interface\\Tooltips\\UI-Tooltip-Border",
		tile = 1,
		tileSize = 16,
		edgeSize = 16,
		insets = { left = 4, right = 4, top = 4, bottom = 4 }
	});
	selectorEx:SetBackdropColor(0.1, 0.1, 0.2, 1);
	selectorEx:SetBackdropBorderColor(0.8, 0.8, 0.9, 0.4);

	selectorEx.searchTextChangedHandler = nil;
	selectorEx.buttons = { };
	selectorEx.list = { };
	selectorEx.currentPosition = -1;
	selectorEx.dataSource = nil;

	selectorEx.searchBox = CreateFrame("EditBox", nil, selectorEx, "InputBoxTemplate");
	selectorEx.searchBox:SetAutoFocus(false);
	selectorEx.searchBox:SetFontObject(GameFontHighlightSmall);
	selectorEx.searchBox:SetPoint("TOPLEFT", selectorEx, "TOPLEFT", 10, -5);
	selectorEx.searchBox:SetPoint("RIGHT", selectorEx, "RIGHT", -10, 0);
	selectorEx.searchBox:SetHeight(20);
	selectorEx.searchBox:SetWidth(175);
	selectorEx.searchBox:SetJustifyH("LEFT");
	selectorEx.searchBox:EnableMouse(true);
	selectorEx.searchBox:SetScript("OnEscapePressed", function() selectorEx.searchBox:ClearFocus(); end);
	selectorEx.searchBox:SetScript("OnTextChanged", function(self)
		if (selectorEx.searchTextChangedHandler == nil) then
			return;
		end

		local text = self:GetText();
		selectorEx:searchTextChangedHandler(text);
		selectorEx.scrollArea:SetVerticalScroll(0);
	end);
	local searchBoxText = selectorEx.searchBox:CreateFontString(nil, "ARTWORK", "GameFontDisable");
	searchBoxText:SetPoint("LEFT", 0, 0);
	searchBoxText:SetText("Click to search...");
	selectorEx.searchBox:SetScript("OnEditFocusGained", function() searchBoxText:Hide(); end);
	selectorEx.searchBox:SetScript("OnEditFocusLost", function()
		local text = selectorEx.searchBox:GetText();
		if (text == nil or text == "") then
			searchBoxText:Show();
		end
	end);
	selectorEx.searchBox.hint = CreateFrame("Frame", nil, selectorEx.searchBox);
	selectorEx.searchBox.hint:SetWidth(selectorEx.searchBox:GetHeight());
	selectorEx.searchBox.hint:SetHeight(selectorEx.searchBox:GetHeight());
	selectorEx.searchBox.hint:SetPoint("RIGHT", selectorEx.searchBox, "RIGHT", -4, 0);
	selectorEx.searchBox.hint.texture = selectorEx.searchBox.hint:CreateTexture(nil, "OVERLAY");
	selectorEx.searchBox.hint.texture:SetTexture("Interface\\common\\help-i");
	selectorEx.searchBox.hint.texture:SetAllPoints(selectorEx.searchBox.hint);
	selectorEx.searchBox.hint:Hide();

	selectorEx.scrollArea = CreateFrame("ScrollFrame", nil, selectorEx, "UIPanelScrollFrameTemplate");
	selectorEx.scrollArea:SetPoint("TOPLEFT", selectorEx, "TOPLEFT", 5, SCROLL_AREA_Y_OFFSET);
	selectorEx.scrollArea:SetPoint("BOTTOMRIGHT", selectorEx, "BOTTOMRIGHT", -30, 5);
	selectorEx.scrollArea:Show();

	selectorEx.scrollAreaChildFrame = CreateFrame("Frame", nil, selectorEx.scrollArea);
	selectorEx.scrollArea:SetScrollChild(selectorEx.scrollAreaChildFrame);
	selectorEx.scrollAreaChildFrame:SetWidth(selectorEx.scrollArea:GetWidth());
	selectorEx.scrollAreaChildFrame:SetHeight(288);

	local function GetButton(s, counter)
		if (s.buttons[counter] == nil) then
			local line = CreateFrame("frame", nil, s.scrollAreaChildFrame);
			line:SetHeight(20);
			line:SetPoint("TOPLEFT", 5, -counter * 22 + 20);
			line:SetPoint("RIGHT", 0, 0);
			line:Show();
			local button = lib.CreateButton();
			local originalShow = button.Show;
			button.Show = function(self) originalShow(self); line:Show(); end
			local originalHide = button.Hide;
			button.Hide = function(self) originalHide(self); line:Hide(); end
			button:SetParent(line);
			button.font, button.fontSize, button.fontFlags = button.Text:GetFont();

			button.Icon = button:CreateTexture();
			button.Icon:SetTexCoord(0.07, 0.93, 0.07, 0.93);
			button.Icon:SetPoint("LEFT", line, "LEFT", 0, 0);
			button.Icon:SetWidth(line:GetHeight());
			button.Icon:SetHeight(line:GetHeight());

			button.closeButton = lib.CreateButton();
			button.closeButton:SetParent(line);
			button.closeButton:SetWidth(line:GetHeight());
			button.closeButton:SetHeight(line:GetHeight());
			button.closeButton:SetPoint("RIGHT", line, "RIGHT", 0, 0);
			button.closeButton.Text:SetText("X");

			button:SetHeight(line:GetHeight());
			button:SetPoint("LEFT", button.Icon, "RIGHT", SPACE_BETWEEN_BUTTON_AND_CLOSEBUTTON, 0);
			button:SetPoint("RIGHT", button.closeButton, "LEFT", -SPACE_BETWEEN_BUTTON_AND_CLOSEBUTTON, 0);
			button:Hide();

			s.buttons[counter] = button;
			return button;
		else
			return s.buttons[counter];
		end
	end

	-- value.text, value.font, value.icon, value.func, value.onEnter, value.onLeave, value.disabled, value.dontCloseOnClick, value.checkBoxEnabled,
	--value.onCheckBoxClick, value.checkBoxState, onCloseButtonClick, buttonColor
	local function SetList(s, t)
		for _, button in pairs(s.buttons) do
			button:SetGray(false);
			button:Hide();
			button.Text:SetFont(button.font, button.fontSize, button.fontFlags);
			button.Text:SetText();
			button.closeButton:Hide();
			button.closeButton:SetScript("OnClick", nil);
			button:SetScript("OnClick", nil);
			button:SetCheckBoxVisible(false);
			button.Normal:SetColorTexture(unpack(BUTTON_COLOR_NORMAL));
		end
		local counter = 1;
		for _, value in pairs(t) do
			local button = GetButton(s, counter);
			button.Text:SetText(value.text);
			if (value.font ~= nil) then
				button.Text:SetFont(value.font, button.fontSize, button.fontFlags);
			end
			if (value.disabled) then
				button:SetGray(true);
			end
			if (value.icon ~= nil) then
				button.Icon:SetTexture(value.icon);
				button.Icon:Show();
				button:SetPoint("LEFT", button.Icon, "RIGHT", SPACE_BETWEEN_BUTTON_AND_CLOSEBUTTON, 0);
			else
				button.Icon:Hide();
				button:SetPoint("LEFT", button:GetParent(), "LEFT", 0, 0);
			end
			if (value.func ~= nil) then
				button:SetScript("OnClick", function()
					value:func();
					if (not value.dontCloseOnClick) then
						s:Hide();
					else
						s:Update();
					end
				end);
			end
			if (value.checkBoxEnabled) then
				button:SetCheckBoxVisible(true);
				button:SetCheckBoxOnClickHandler(function(_self)
					value.onCheckBoxClick(_self);
					s:Update();
				end);
				button:SetChecked(value.checkBoxState);
			end
			if (value.onCloseButtonClick ~= nil) then
				button.closeButton:Show();
				button:SetPoint("RIGHT", button.closeButton, "LEFT", -SPACE_BETWEEN_BUTTON_AND_CLOSEBUTTON, 0);
				button.closeButton:SetScript("OnClick", function()
					value:onCloseButtonClick();
					s:Update();
				end);
			else
				button.closeButton:Hide();
				button:SetPoint("RIGHT", button:GetParent(), "RIGHT", 0, 0);
			end
			if (value.buttonColor ~= nil) then
				button.Normal:SetColorTexture(unpack(value.buttonColor));
			end
			button:SetScript("OnEnter", value.onEnter);
			button:SetScript("OnLeave", value.onLeave);
			button:Show();
			counter = counter + 1;
		end

		s.list = t;
	end

	selectorEx.SetDataSource = function(_self, _func)
		if (type(_func) ~= "function") then
			error("Parameter must be a function");
		end
		_self.dataSource = _func;
	end

	selectorEx.Update = function(_self)
		local data = _self:dataSource();
		SetList(_self, data);
	end

	selectorEx.GetSearchText = function(_self)
		return _self.searchBox:GetText() or "";
	end

	selectorEx.SetSearchTextChangedHandler = function(_self, _func)
		_self.searchTextChangedHandler = _func;
	end

	selectorEx.SetSearchBoxHint = function(_self, _hint)
		if (_hint ~= nil and _hint ~= "") then
			_self.searchBox.hint:Show();
			lib.SetTooltip(_self.searchBox.hint, _hint, "LEFT");
		else
			_self.searchBox.hint:Hide();
		end
	end

	selectorEx.GetButtonByText = function(s, text)
		for _, button in pairs(s.buttons) do
			if (button.Text:GetText() == text) then
				return button;
			end
		end
		return nil;
	end

	local setWidth = selectorEx.SetWidth;
	selectorEx.SetWidth = function(_self, _width)
		setWidth(_self, _width);
		_self.scrollAreaChildFrame:SetWidth(_self.scrollArea:GetWidth());
	end

	selectorEx.SetVerticalScroll = function(_self, _scroll)
		_self.currentPosition = _scroll;
		_self.scrollArea:SetVerticalScroll(_self.currentPosition < 0 and 0 or _self.currentPosition);
	end

	SetList(selectorEx, {});
	selectorEx:Hide();
	selectorEx:HookScript("OnShow", function(self)
		self:SetFrameStrata("TOOLTIP");

		self:Update();

		if (self.autoAdjustHeight and #self.buttons > 0) then
			local _, _, _, _, yOffset = self.buttons[#self.buttons]:GetPoint();
			self:SetHeight(-SCROLL_AREA_Y_OFFSET + -yOffset + self.buttons[#self.buttons]:GetHeight() + 10);
		end

		self.scrollArea:SetVerticalScroll(self.currentPosition == -1 and 0 or self.currentPosition);
		self.scrollAreaChildFrame:SetWidth(self.scrollArea:GetWidth());
		self.scrollAreaChildFrame:SetHeight(self:GetHeight() - 12);
	end);
	selectorEx:HookScript("OnHide", function(self)
		self.searchBox:SetText("");
		self.currentPosition = self.scrollArea:GetVerticalScroll();
	end);

	return selectorEx;
end

function lib.CreateTooltip()
	local frame = CreateFrame("Frame", nil, UIParent, BackdropTemplateMixin and "BackdropTemplate");
	frame:SetFrameStrata("TOOLTIP");
	frame:SetBackdrop({
		bgFile = "Interface\\Tooltips\\UI-Tooltip-Background",
		edgeFile = "Interface\\Tooltips\\UI-Tooltip-Border",
		tile = 1,
		tileSize = 16,
		edgeSize = 16,
		insets = { left = 4, right = 4, top = 4, bottom = 4 }
	});
	frame:SetBackdropColor(0.2, 0.2, 0.2, 1);
	frame:SetBackdropBorderColor(0.9, 0.9, 0.9, 0.4);
	frame:SetPoint("TOPLEFT", UIParent, "TOPLEFT", 0, 0);
	frame:SetWidth(250);
	frame:SetHeight(5);
	frame:SetClampedToScreen(1);
	frame:Hide();

	frame.text = frame:CreateFontString(nil, "ARTWORK", "GameFontNormalMed1");
	frame.text:SetPoint("TOPLEFT", 10, -10);
	frame.text:SetPoint("TOPRIGHT", -10, -10);
	local origSetText = frame.text.SetText;
	frame.text.SetText = function(self, text)
		origSetText(self, text);
		frame.dontResize = true;
		frame:SetHeight(self:GetStringHeight() + 20);
		frame.dontResize = false;
	end

	frame.icon = frame:CreateTexture(nil, "BORDER");
	frame.icon:SetSize(40, 40);
	frame.icon:SetPoint("TOPRIGHT", frame, "TOPLEFT", -5, 0);
	frame.icon:Hide();

	frame:SetScript("OnSizeChanged", function(self)
		if (not self.dontResize) then
			self:SetHeight(self.text:GetStringHeight() + 20);
		end
	end);

	frame.SetText = function(self, text, icon)
		self.text:SetText(text);
		if (icon ~= nil) then
			self.icon:SetTexture(icon);
			self.icon:Show();
		else
			self.icon:Hide();
		end
	end

	frame.GetTextObject = function(self)
		return self.text;
	end

	frame.SetSpellById = function(self, spellID)
		local spell = Spell:CreateFromSpellID(spellID);
		spell:ContinueOnSpellLoad(function()
			local spellName = spell:GetSpellName();
			local spellDesc = spell:GetSpellDescription();
			local spellTexture = C_Spell_GetSpellTexture(spellID);
			self:SetText(string_format("%s\n\n%s\n%s", spellName, spellDesc, ColorizeText("Spell ID: " .. spellID, 91/255, 165/255, 249/255)), spellTexture);
		end);
	end

	return frame;
end

function lib.SetTooltip(frame, text, justify)
	if (frame.LRDTooltip == nil) then
		frame.LRDTooltip = lib.CreateTooltip();
		frame.LRDTooltipText = text;
		frame.LRDTooltipJustify = justify or "CENTER";
		frame:HookScript("OnEnter", function()
			frame.LRDTooltip:ClearAllPoints();
			frame.LRDTooltip:SetPoint("BOTTOM", frame, "TOP", 0, 0);
			frame.LRDTooltip:GetTextObject():SetJustifyH(frame.LRDTooltipJustify);
			frame.LRDTooltip:SetText(frame.LRDTooltipText);
			frame.LRDTooltip:Show();
		end);
		frame:HookScript("OnLeave", function()
			frame.LRDTooltip:Hide();
		end);
	else
		frame.LRDTooltipText = text;
	end
end

function lib.CreateCheckBox()
	local checkBox = CreateFrame("CheckButton");
	checkBox:SetHeight(20);
	checkBox:SetWidth(20);
	checkBox:SetNormalTexture("Interface\\Buttons\\UI-CheckBox-Up");
	checkBox:SetPushedTexture("Interface\\Buttons\\UI-CheckBox-Down");
	checkBox:SetHighlightTexture("Interface\\Buttons\\UI-CheckBox-Highlight");
	checkBox:SetDisabledCheckedTexture("Interface\\Buttons\\UI-CheckBox-Check-Disabled");
	checkBox:SetCheckedTexture("Interface\\Buttons\\UI-CheckBox-Check");
	checkBox.textFrame = CreateFrame("frame", nil, checkBox);
	checkBox.textFrame:SetPoint("LEFT", checkBox, "RIGHT", 0, 0);
	checkBox.textFrame:EnableMouse(true);
	checkBox.textFrame:HookScript("OnEnter", function() checkBox:LockHighlight(); end);
	checkBox.textFrame:HookScript("OnLeave", function() checkBox:UnlockHighlight(); end);
	checkBox.textFrame:Show();
	checkBox.textFrame:HookScript("OnMouseDown", function() checkBox:SetButtonState("PUSHED"); end);
	checkBox.textFrame:HookScript("OnMouseUp", function() checkBox:SetButtonState("NORMAL"); checkBox:Click(); end);
	checkBox.Text = checkBox.textFrame:CreateFontString(nil, "OVERLAY", "GameFontNormal");
	checkBox.Text:SetPoint("LEFT", 0, 0);
	checkBox.SetText = function(self, _text)
		self.Text:SetText(_text);
		self.textFrame:SetWidth(self.Text:GetStringWidth() + self:GetWidth());
		self.textFrame:SetHeight(max(self.Text:GetStringHeight(), self:GetHeight()));
	end;
	checkBox.GetText = function(self)
		return self.Text:GetText();
	end
	checkBox.GetTextObject = function(self)
		return self.Text;
	end
	checkBox.SetOnClickHandler = function(self, func)
		self:SetScript("OnClick", func);
	end
	local handlersToBeCopied = { "OnEnter", "OnLeave" };
	hooksecurefunc(checkBox, "HookScript", function(_, script, proc) if (table_contains_value(handlersToBeCopied, script)) then checkBox.textFrame:HookScript(script, proc); end end);
	hooksecurefunc(checkBox, "SetScript",  function(_, script, proc) if (table_contains_value(handlersToBeCopied, script)) then checkBox.textFrame:SetScript(script, proc); end end);
	checkBox:EnableMouse(true);
	checkBox:Hide();
	return checkBox;
end

function lib.CreateCheckBoxTristate()
	local checkButton = lib.CreateCheckBox();
	checkButton.state = 0;
	checkButton.textEntries = { };
	checkButton.SetTriState = function(self, tristate)
		if (type(tristate) ~= "number" or tristate < 0 or tristate > 2) then error(string_format("%s -> TriStateCheckbox -> SetTriState: tristate must be either 0, 1 or 2", LIB_NAME)); end
		self:SetText(self.textEntries[tristate+1] .. " |TInterface\\common\\help-i:26:26:0:0|t");
		self:SetChecked(tristate == 1 or tristate == 2);
		self.state = tristate;
	end;
	checkButton.SetTextEntries = function(self, textEntries)
		self.textEntries = textEntries;
		self:SetText(self.textEntries[self.state+1] .. " |TInterface\\common\\help-i:26:26:0:0|t");
	end;
	checkButton.GetTriState = function(self)
		return self.state;
	end;
	checkButton.SetOnClickHandler = function(self, _func)
		self:SetScript("OnClick", function(_self)
			local newState = _self:GetTriState() + 1;
			if (newState > 2) then newState = 0; end
			_self:SetTriState(newState);
			_func(_self);
		end);
	end;
	return checkButton;
end

function lib.CreateColorPicker()
	local colorButton = CreateFrame("Button");
	colorButton:SetWidth(20);
	colorButton:SetHeight(20);
	colorButton:Hide();
	colorButton:EnableMouse(true);
	colorButton.colorSwatch = colorButton:CreateTexture(nil, "OVERLAY");
	colorButton.colorSwatch:SetWidth(19);
	colorButton.colorSwatch:SetHeight(19);
	colorButton.colorSwatch:SetTexture("Interface\\ChatFrame\\ChatFrameColorSwatch");
	colorButton.colorSwatch:SetPoint("LEFT");
	colorButton.texture = colorButton:CreateTexture(nil, "BACKGROUND");
	colorButton.texture:SetWidth(16);
	colorButton.texture:SetHeight(16);
	colorButton.texture:SetTexture(1, 1, 1);
	colorButton.texture:SetPoint("CENTER", colorButton.colorSwatch);
	colorButton.texture:Show();
	colorButton.checkers = colorButton:CreateTexture(nil, "BACKGROUND");
	colorButton.checkers:SetWidth(14);
	colorButton.checkers:SetHeight(14);
	colorButton.checkers:SetTexture("Tileset\\Generic\\Checkers");
	colorButton.checkers:SetTexCoord(.25, 0, 0.5, .25);
	colorButton.checkers:SetDesaturated(true);
	colorButton.checkers:SetVertexColor(1, 1, 1, 0.75);
	colorButton.checkers:SetPoint("CENTER", colorButton.colorSwatch);
	colorButton.checkers:Show();
	colorButton.text = colorButton:CreateFontString(nil, "OVERLAY", "GameFontNormal");
	colorButton.text:SetPoint("LEFT", 22, 0);
	colorButton.GetTextObject = function(self)
		return self.text;
	end
	colorButton.SetText = function(self, text)
		self.text:SetText(text);
	end
	colorButton.GetText = function(self)
		return self.text:GetText();
	end
	colorButton.SetColor = function(self, r, g, b, a)
		if (a == nil) then a = 1; end
		self.colorSwatch:SetVertexColor(r, g, b, a);
		lib.SetTooltip(self, string_format("R: %d, G: %d, B: %d, A: %d", r*255, g*255, b*255, a*255));
	end
	colorButton.GetColor = function(self)
		local r, g, b, a = self.colorSwatch:GetVertexColor();
		return r, g, b, a;
	end

	--colorButton.func;

	colorButton:SetScript("OnClick", function(self)
		ColorPickerFrame:Hide();

		if (ColorPickerFrame.SetupColorPickerAndShow ~= nil) then -- wow 10.2.5+
			local colorR, colorG, colorB, colorA = self:GetColor();

			local function changeColorCallback()
				local a, r, g, b = ColorPickerFrame:GetColorAlpha(), ColorPickerFrame:GetColorRGB();

				self:SetColor(r, g, b, a);
				if (self.func ~= nil) then
					self:func(r, g, b, a);
				end
			end

			local function cancelCallback()
				local a, r, g, b = colorA, colorR, colorG, colorB;

				self:SetColor(r, g, b, a);
				if (self.func ~= nil) then
					self:func(r, g, b, a);
				end
			end

			local info = {
				swatchFunc = changeColorCallback,
				opacityFunc = changeColorCallback,
				cancelFunc = cancelCallback,
				hasOpacity = true,
				opacity = colorA,
				r = colorR,
				g = colorG,
				b = colorB
			};

			ColorPickerFrame:SetupColorPickerAndShow(info);
		else
			local function callback(restore)
				local r, g, b, a;
				if (restore) then
					r, g, b, a = unpack(restore);
				else
					a, r, g, b = 1-OpacitySliderFrame:GetValue(), ColorPickerFrame:GetColorRGB();
				end
				self:SetColor(r, g, b, a);
				if (self.func ~= nil) then
					self:func(r, g, b, a);
				end
			end
			ColorPickerFrame.func, ColorPickerFrame.opacityFunc, ColorPickerFrame.cancelFunc = callback, callback, callback;
			local colorR, colorG, colorB, colorA = self:GetColor();
			ColorPickerFrame:SetColorRGB(colorR, colorG, colorB);
			ColorPickerFrame.hasOpacity = true;
			ColorPickerFrame.opacity = 1-colorA;
			ColorPickerFrame.previousValues = { colorR, colorG, colorB, colorA };
			ColorPickerFrame:Show();
		end
	end);

	return colorButton;
end

function lib.CreateCheckBoxWithColorPicker()
	local checkBox = lib.CreateCheckBox();
	checkBox.textFrame:ClearAllPoints();
	checkBox.textFrame:SetPoint("LEFT", checkBox, "RIGHT", 20, 0);
	checkBox.ColorButton = lib.CreateColorPicker();
	checkBox.ColorButton:SetParent(checkBox);
	checkBox.ColorButton:SetPoint("LEFT", 19, 0);
	checkBox.ColorButton:Show();
	checkBox.SetColor = function(self, ...) self.ColorButton:SetColor(...); end;
	checkBox.GetColor = function(self) return self.ColorButton:GetColor(); end;
	return checkBox;
end

function lib.CreateSlider()
	local frame = CreateFrame("Frame");
	frame:SetHeight(100);
	frame.label = frame:CreateFontString(nil, "OVERLAY", "GameFontNormal");
	frame.label:SetPoint("TOPLEFT");
	frame.label:SetPoint("TOPRIGHT");
	frame.label:SetJustifyH("CENTER");
	frame.slider = CreateFrame("Slider", nil, frame, BackdropTemplateMixin and "BackdropTemplate");
	frame.slider:SetOrientation("HORIZONTAL")
	frame.slider:SetHeight(15)
	frame.slider:SetHitRectInsets(0, 0, -10, 0)
	frame.slider:SetBackdrop({
		bgFile = "Interface\\Buttons\\UI-SliderBar-Background",
		edgeFile = "Interface\\Buttons\\UI-SliderBar-Border",
		tile = true, tileSize = 8, edgeSize = 8,
		insets = { left = 3, right = 3, top = 6, bottom = 6 }
	});
	frame.slider:SetThumbTexture("Interface\\Buttons\\UI-SliderBar-Button-Horizontal")
	frame.slider:SetPoint("TOP", frame.label, "BOTTOM")
	frame.slider:SetPoint("LEFT", 3, 0)
	frame.slider:SetPoint("RIGHT", -3, 0)
	frame.lowtext = frame.slider:CreateFontString(nil, "ARTWORK", "GameFontHighlightSmall")
	frame.lowtext:SetPoint("TOPLEFT", frame.slider, "BOTTOMLEFT", 2, 3)
	frame.hightext = frame.slider:CreateFontString(nil, "ARTWORK", "GameFontHighlightSmall")
	frame.hightext:SetPoint("TOPRIGHT", frame.slider, "BOTTOMRIGHT", -2, 3)
	frame.editbox = CreateFrame("EditBox", nil, frame, BackdropTemplateMixin and "BackdropTemplate")
	frame.editbox:SetAutoFocus(false)
	frame.editbox:SetFontObject(GameFontHighlightSmall)
	frame.editbox:SetPoint("TOP", frame.slider, "BOTTOM")
	frame.editbox:SetHeight(14)
	frame.editbox:SetWidth(70)
	frame.editbox:SetJustifyH("CENTER")
	frame.editbox:EnableMouse(true)
	frame.editbox:SetBackdrop({
		bgFile = "Interface\\ChatFrame\\ChatFrameBackground",
		edgeFile = "Interface\\ChatFrame\\ChatFrameBackground",
		tile = true, edgeSize = 1, tileSize = 5,
	});
	frame.editbox:SetBackdropColor(0, 0, 0, 0.5)
	frame.editbox:SetBackdropBorderColor(0.3, 0.3, 0.30, 0.80)
	frame.editbox:SetScript("OnEscapePressed", function() frame.editbox:ClearFocus(); end)
	frame:Hide();

	frame.GetTextObject = function(self) return self.label; end
	frame.GetBaseSliderObject = function(self) return self.slider; end
	frame.GetEditboxObject = function(self) return self.editbox; end
	frame.GetLowTextObject = function(self) return self.lowtext; end
	frame.GetHighTextObject = function(self) return self.hightext; end

	return frame;
end

function lib.CreateButton()
	local button = CreateFrame("Button");
	button.Background = button:CreateTexture(nil, "BORDER");
	button.Background:SetPoint("TOPLEFT", 2, -2);
	button.Background:SetPoint("BOTTOMRIGHT", -2, 2);
	button.Background:SetColorTexture(0, 0, 0, 1);
	button.Border = button:CreateTexture(nil, "BACKGROUND");
	button.Border:SetPoint("TOPLEFT", 0, 0);
	button.Border:SetPoint("BOTTOMRIGHT", 0, 0);
	button.Border:SetColorTexture(unpack({0.73, 0.26, 0.21, 1}));
	button.Normal = button:CreateTexture(nil, "ARTWORK");
	button.Normal:SetPoint("TOPLEFT", 3, -3);
	button.Normal:SetPoint("BOTTOMRIGHT", -3, 3);
	button.Normal:SetColorTexture(unpack(BUTTON_COLOR_NORMAL));
	button:SetNormalTexture(button.Normal);
	button.Disabled = button:CreateTexture(nil, "OVERLAY");
	button.Disabled:SetPoint("TOPLEFT", 3, -3);
	button.Disabled:SetPoint("BOTTOMRIGHT", -3, 3);
	button.Disabled:SetColorTexture(0.6, 0.6, 0.6, 0.2);
	button:SetDisabledTexture(button.Disabled);
	button.Highlight = button:CreateTexture(nil, "OVERLAY");
	button.Highlight:SetPoint("TOPLEFT", 3, -3);
	button.Highlight:SetPoint("BOTTOMRIGHT", -3, 3);
	button.Highlight:SetColorTexture(0.6, 0.6, 0.6, 0.2);
	button:SetHighlightTexture(button.Highlight);
	button.Text = button:CreateFontString(nil, "OVERLAY", "GameFontNormal");
	button.Text:SetPoint("CENTER", 0, 0);
	button.Text:SetJustifyH("CENTER");
	button.Text:SetTextColor(1, 0.82, 0, 1);
	button:SetScript("OnMouseDown", function(self) self.Text:SetPoint("CENTER", 1, -1) end);
	button:SetScript("OnMouseUp", function(self) self.Text:SetPoint("CENTER", 0, 0) end);

	-- adding checkbox
	button.CheckBox = lib.CreateCheckBox();
	button.CheckBox:SetParent(button);
	button.CheckBox:SetText("");
	button.CheckBox:SetPoint("LEFT", button, "LEFT", 5, 0);

	-- basic methods
	button.SetGray = function(self, gray)
		self.Normal:SetColorTexture(unpack(gray and {0, 0, 0, 1} or BUTTON_COLOR_NORMAL));
		self.grayed = gray;
	end

	button.IsGrayed = function(self)
		return self.grayed == true;
	end

	-- text object methods
	button.SetText = function(self, text)
		self.Text:SetText(text);
	end

	button.GetText = function(self)
		return self.Text:GetText();
	end

	button.GetTextObject = function(self)
		return self.Text;
	end

	-- checkbox methods
	button.SetChecked = function(self, checked)
		self.CheckBox:SetChecked(checked);
	end

	button.GetChecked = function(self)
		return self.CheckBox:GetChecked();
	end

	button.SetCheckBoxVisible = function(self, isVisible)
		if (isVisible) then
			self.CheckBox:Show();
		else
			self.CheckBox:Hide();
		end
	end

	button.GetCheckBoxVisible = function(self)
		return self.CheckBox:IsVisible();
	end

	button.SetCheckBoxOnClickHandler = function(self, func)
		self.CheckBox:SetOnClickHandler(func);
	end

	return button;
end

function lib.CreateDebugWindow()
	local popup = CreateFrame("EditBox", nil, UIParent);
	popup:SetFrameStrata("DIALOG");
	popup:SetMultiLine(true);
	popup:SetAutoFocus(true);
	popup:SetFontObject(ChatFontNormal);
	popup:SetSize(450, 300);
	popup:Hide();
	popup.orig_Hide = popup.Hide;
	popup.orig_Show = popup.Show;

	popup.Hide = function(self)
		self:SetText("");
		self.ScrollFrame:Hide();
		self.Background:Hide();
		self:orig_Hide();
	end

	popup.Show = function(self)
		self.ScrollFrame:Show();
		self.Background:Show();
		self:orig_Show();
	end

	popup.AddText = function(self, v)
		if not v then return end
		local m = self:GetText();
		if (m ~= "") then
			m = m.."\n";
		end
		self:SetText(m..v);
	end

	popup:SetScript("OnEscapePressed", function(self)
		self:ClearFocus();
		self:Hide();
		self.ScrollFrame:Hide();
		self.Background:Hide();
	end);

	local s = CreateFrame("ScrollFrame", nil, UIParent, "UIPanelScrollFrameTemplate");
	s:SetFrameStrata("DIALOG");
	s:SetSize(450, 300);
	s:SetPoint("CENTER");
	s:SetScrollChild(popup);
	s:Hide();

	s:SetScript("OnMouseDown",function(self)
		self:GetScrollChild():SetFocus();
	end);

	local bg = CreateFrame("Frame",nil,UIParent, BackdropTemplateMixin and "BackdropTemplate")
	bg:SetFrameStrata("DIALOG")
	bg:SetBackdrop({
		bgFile = "Interface\\ChatFrame\\ChatFrameBackground",
		edgeFile = "Interface\\Tooltips\\UI-Tooltip-border",
		edgeSize = 16,
		insets = { left = 4, right = 4, top = 4, bottom = 4 }
	})
	bg:SetBackdropColor(.05,.05,.05,.8)
	bg:SetBackdropBorderColor(.5,.5,.5)
	bg:SetPoint("TOPLEFT",s,-10,10)
	bg:SetPoint("BOTTOMRIGHT",s,30,-10)
	bg:Hide()

	popup.ScrollFrame = s;
	popup.Background = bg;

	return popup;
end

local function GetLuaEditorTheme()
	local theme = { };
	theme["Table"] = "|c00AFC0E5";
    theme["Arithmetic"] = "|c00E0E2E4";
    theme["Relational"] = "|c00B3B689";
    theme["Logical"] = "|c0093C763";
    theme["Special"] = "|c00AFC0E5";
    theme["Keyword"] = "|c0093C763";
    theme["Comment"] = "|c0066747B";
    theme["Number"] = "|c00FFCD22";
	theme["String"] = "|c00EC7600";

	local color_scheme = { };
	color_scheme[IndentationLib.tokens.TOKEN_SPECIAL] = theme["Special"]
	color_scheme[IndentationLib.tokens.TOKEN_KEYWORD] = theme["Keyword"]
	color_scheme[IndentationLib.tokens.TOKEN_COMMENT_SHORT] = theme["Comment"]
	color_scheme[IndentationLib.tokens.TOKEN_COMMENT_LONG] = theme["Comment"]
	color_scheme[IndentationLib.tokens.TOKEN_NUMBER] = theme["Number"]
	color_scheme[IndentationLib.tokens.TOKEN_STRING] = theme["String"]

	color_scheme["..."] = theme["Table"]
	color_scheme["{"] = theme["Table"]
	color_scheme["}"] = theme["Table"]
	color_scheme["["] = theme["Table"]
	color_scheme["]"] = theme["Table"]

	color_scheme["+"] = theme["Arithmetic"]
	color_scheme["-"] = theme["Arithmetic"]
	color_scheme["/"] = theme["Arithmetic"]
	color_scheme["*"] = theme["Arithmetic"]
	color_scheme[".."] = theme["Arithmetic"]

	color_scheme["=="] = theme["Relational"]
	color_scheme["<"] = theme["Relational"]
	color_scheme["<="] = theme["Relational"]
	color_scheme[">"] = theme["Relational"]
	color_scheme[">="] = theme["Relational"]
	color_scheme["~="] = theme["Relational"]

	color_scheme["and"] = theme["Logical"]
	color_scheme["or"] = theme["Logical"]
	color_scheme["not"] = theme["Logical"]
	return color_scheme;
end

function lib.CreateLuaEditor()
	local frame = CreateFrame("Frame", nil, UIParent, BackdropTemplateMixin and "BackdropTemplate");
	frame:SetSize(700, 500);
	frame:SetPoint("CENTER");
	frame:Hide();

	frame:EnableMouse(true);
	frame:SetMovable(true);
	frame:SetResizable(true);
	frame:SetFrameStrata("FULLSCREEN_DIALOG");
	frame:SetBackdrop({
		bgFile = "Interface\\Tooltips\\UI-Tooltip-Background",
		edgeFile = "Interface\\Tooltips\\UI-Tooltip-Border",
		tile = 1,
		tileSize = 16,
		edgeSize = 16,
		insets = { left = 4, right = 4, top = 4, bottom = 4 }
	});
	frame:SetBackdropColor(0, 0, 0, 1);
	if (wowBuild < 20000) then
		frame:SetResizeBounds(400, 200);
	elseif (wowBuild < 30401) then
		frame:SetMinResize(400, 200);
	else
		frame:SetResizeBounds(400, 200);
	end
	frame:SetToplevel(true);

	-- header
	do
		frame.Header = CreateFrame("Frame", nil, frame, BackdropTemplateMixin and "BackdropTemplate");
		frame.Header:SetSize(200, 30);
		frame.Header:EnableMouse(true);
		frame.Header:SetBackdrop({
			bgFile = "Interface\\Tooltips\\UI-Tooltip-Background",
			edgeFile = "Interface\\Tooltips\\UI-Tooltip-Border",
			tile = 1,
			tileSize = 16,
			edgeSize = 16,
			insets = { left = 4, right = 4, top = 4, bottom = 4 }
		});
		frame.Header:SetBackdropColor(0, 0, 0, 1);
		frame.Header:SetPoint("BOTTOM", frame, "TOP", 0, -3);
		frame.Header:SetScript("OnMouseDown", function() frame:StartMoving(); end);
		frame.Header:SetScript("OnMouseUp", function() frame:StopMovingOrSizing(); end)

		frame.Header.text = frame.Header:CreateFontString(nil, "OVERLAY", "GameFontNormalHuge");
		frame.Header.text:SetPoint("CENTER");
		frame.Header.text:SetText("LuaEditor");
	end

	-- buttons
	do
		frame.CloseButton = CreateFrame("Button", nil, frame, "UIPanelButtonTemplate");
		frame.CloseButton:SetScript("OnClick", function() frame:Hide(); end);
		frame.CloseButton:SetPoint("BOTTOMRIGHT", -27, 17);
		frame.CloseButton:SetHeight(20);
		frame.CloseButton:SetWidth(100);
		frame.CloseButton:SetText(CLOSE);

		frame.ApplyButton = CreateFrame("Button", nil, frame, "UIPanelButtonTemplate");
		frame.ApplyButton:SetScript("OnClick", function(self)
			if (frame.OnAcceptFunc ~= nil) then frame:OnAcceptFunc(); end
			self:Disable();
		end);
		frame.ApplyButton:SetPoint("RIGHT", frame.CloseButton, "LEFT", -5, 0);
		frame.ApplyButton:SetHeight(20);
		frame.ApplyButton:SetWidth(100);
		frame.ApplyButton:SetText(ACCEPT);
		frame.ApplyButton:Disable();

		frame.InfoButton = CreateFrame("Button", nil, frame, "UIPanelButtonTemplate");
		frame.InfoButton:SetScript("OnClick", function(_)
			if (frame.OnInfoButtonClick ~= nil) then frame:OnInfoButtonClick(); end
		end);
		frame.InfoButton:SetPoint("RIGHT", frame.ApplyButton, "LEFT", -5, 0);
		frame.InfoButton:SetHeight(20);
		frame.InfoButton:SetWidth(100);
		frame.InfoButton:SetText(INFO);
		frame.InfoButton:Hide();
	end

	-- status text
	do
		frame.StatusTextFrame = CreateFrame("Button", nil, frame);
		frame.StatusTextFrame:SetPoint("BOTTOMLEFT", 15, 15);
		frame.StatusTextFrame:SetPoint("RIGHT", frame.ApplyButton, "LEFT", -5, 0);
		frame.StatusTextFrame:SetHeight(24);

		local tooltip = lib.CreateTooltip();
		frame.StatusTextFrame:SetScript("OnEnter", function(self)
			local text = frame:GetStatusText();
			if (text ~= nil and text ~= "") then
				tooltip:ClearAllPoints();
				tooltip:SetPoint("TOP", self, "BOTTOM", 0, 0);
				tooltip:SetText(text);
				tooltip:Show();
			end
		end);
		frame.StatusTextFrame:SetScript("OnLeave", function(_)
			tooltip:Hide();
		end);

		frame.StatusText = frame.StatusTextFrame:CreateFontString(nil, "OVERLAY", "GameFontNormal");
		frame.StatusText:SetPoint("TOPLEFT", 7, -2);
		frame.StatusText:SetPoint("BOTTOMRIGHT", -7, 2);
		frame.StatusText:SetHeight(20);
		frame.StatusText:SetJustifyH("LEFT");
		frame.StatusText:SetText("");
	end

	-- resize controls
	do
		local sizer_se = CreateFrame("Frame", nil, frame)
		sizer_se:SetPoint("BOTTOMRIGHT")
		sizer_se:SetWidth(25)
		sizer_se:SetHeight(25)
		sizer_se:EnableMouse()
		sizer_se:SetScript("OnMouseDown", function() frame:StartSizing("BOTTOMRIGHT"); end);
		sizer_se:SetScript("OnMouseUp", function() frame:StopMovingOrSizing(); end)

		local line1 = sizer_se:CreateTexture(nil, "BACKGROUND")
		line1:SetWidth(14)
		line1:SetHeight(14)
		line1:SetPoint("BOTTOMRIGHT", -8, 8)
		line1:SetTexture("Interface\\Tooltips\\UI-Tooltip-Border")
		local x1 = 0.1 * 14/17
		line1:SetTexCoord(0.05 - x1, 0.5, 0.05, 0.5 + x1, 0.05, 0.5 - x1, 0.5 + x1, 0.5)

		local line2 = sizer_se:CreateTexture(nil, "BACKGROUND")
		line2:SetWidth(8)
		line2:SetHeight(8)
		line2:SetPoint("BOTTOMRIGHT", -8, 8)
		line2:SetTexture("Interface\\Tooltips\\UI-Tooltip-Border")
		local x2 = 0.1 * 8/17
		line2:SetTexCoord(0.05 - x2, 0.5, 0.05, 0.5 + x2, 0.05, 0.5 - x2, 0.5 + x2, 0.5)

		local sizer_s = CreateFrame("Frame", nil, frame)
		sizer_s:SetPoint("BOTTOMRIGHT", -25, 0)
		sizer_s:SetPoint("BOTTOMLEFT")
		sizer_s:SetHeight(25)
		sizer_s:EnableMouse(true)
		sizer_s:SetScript("OnMouseDown", function() frame:StartSizing("BOTTOM"); end)
		sizer_s:SetScript("OnMouseUp", function() frame:StopMovingOrSizing(); end)

		local sizer_e = CreateFrame("Frame", nil, frame)
		sizer_e:SetPoint("BOTTOMRIGHT", 0, 25)
		sizer_e:SetPoint("TOPRIGHT")
		sizer_e:SetWidth(25)
		sizer_e:EnableMouse(true)
		sizer_e:SetScript("OnMouseDown", function() frame:StartSizing("RIGHT"); end)
		sizer_e:SetScript("OnMouseUp", function() frame:StopMovingOrSizing(); end)
	end

	-- scroll controls & editbox
	do
		local scrollBG = CreateFrame("Frame", nil, frame, BackdropTemplateMixin and "BackdropTemplate" or nil)
		scrollBG:SetBackdrop({
			bgFile = [[Interface\Tooltips\UI-Tooltip-Background]],
			edgeFile = [[Interface\Tooltips\UI-Tooltip-Border]], edgeSize = 16,
			insets = { left = 4, right = 3, top = 4, bottom = 3 }
		});
		scrollBG:SetBackdropColor(0, 0, 0);
		scrollBG:SetBackdropBorderColor(0.4, 0.4, 0.4);

		local scrollFrame = CreateFrame("ScrollFrame", ("%dScrollFrame"):format(math.random(0, 10000)), frame, "UIPanelScrollFrameTemplate");
		frame.EditBox = CreateFrame("EditBox", ("%dEdit"):format(math.random(0, 10000)), scrollFrame)

		local scrollBar = _G[scrollFrame:GetName() .. "ScrollBar"]
		scrollBar:ClearAllPoints()
		scrollBar:SetPoint("TOP", frame, "TOP", 0, -29)
		scrollBar:SetPoint("BOTTOM", frame.StatusTextFrame, "TOP", 0, 18)
		scrollBar:SetPoint("RIGHT", frame, "RIGHT", -10, 0)

		scrollBG:SetPoint("TOPRIGHT", scrollBar, "TOPLEFT", 0, 19)
		scrollBG:SetPoint("BOTTOMLEFT", frame.StatusTextFrame, "TOPLEFT")

		scrollFrame:SetPoint("TOPLEFT", scrollBG, "TOPLEFT", 5, -6)
		scrollFrame:SetPoint("BOTTOMRIGHT", scrollBG, "BOTTOMRIGHT", -4, 4)

		local function OnMouseUp(_)
			frame.EditBox:SetFocus();
			frame.EditBox:SetCursorPosition(frame.EditBox:GetNumLetters());
		end

		local function OnSizeChanged(_, width, _)
			frame.EditBox:SetWidth(width);
		end

		local function OnVerticalScroll(self, offset)
			frame.EditBox:SetHitRectInsets(0, 0, offset, frame.EditBox:GetHeight() - offset - self:GetHeight())
		end

		local function OnCursorChanged(_, _, y, _, cursorHeight)
			y = -y
			local offset = scrollFrame:GetVerticalScroll()
			if y < offset then
				scrollFrame:SetVerticalScroll(y)
			else
				y = y + cursorHeight - scrollFrame:GetHeight()
				if y > offset then
					scrollFrame:SetVerticalScroll(y)
				end
			end
		end

		local function OnEditFocusLost(self)
			self:HighlightText(0, 0)
		end

		local function OnTextChanged(_, userInput)
			if (userInput) then
				frame.ApplyButton:Enable();
				if (frame.OnTextChangedFunc ~= nil) then frame:OnTextChangedFunc(); end
			end
		end

		local function OnTextSet(self)
			self:HighlightText(0, 0)
			self:SetCursorPosition(self:GetNumLetters())
			self:SetCursorPosition(0)
			frame.ApplyButton:Disable()
		end

		scrollFrame:SetScript("OnMouseUp", OnMouseUp);
		scrollFrame:SetScript("OnSizeChanged", OnSizeChanged);
		scrollFrame:HookScript("OnVerticalScroll", OnVerticalScroll);

		frame.EditBox:SetAllPoints();
		frame.EditBox:SetFontObject(ChatFontNormal);
		frame.EditBox:SetMultiLine(true);
		frame.EditBox:EnableMouse(true);
		frame.EditBox:SetAutoFocus(false);
		frame.EditBox:SetCountInvisibleLetters(false);
		frame.EditBox:SetScript("OnCursorChanged", OnCursorChanged);
		frame.EditBox:SetScript("OnEditFocusLost", OnEditFocusLost);
		frame.EditBox:SetScript("OnEscapePressed", frame.EditBox.ClearFocus);
		frame.EditBox:SetScript("OnTextChanged", OnTextChanged)
		frame.EditBox:SetScript("OnTextSet", OnTextSet)
		-- frame.EditBox:SetScript("OnEditFocusGained", OnEditFocusGained)

		scrollFrame:SetScrollChild(frame.EditBox);
	end

	IndentationLib.enable(frame.EditBox, GetLuaEditorTheme(), 4);

	frame.SetOnAcceptHandler = function(self, func)
		self.OnAcceptFunc = func;
	end

	frame.SetOnTextChangedHandler = function(self, func)
		self.OnTextChangedFunc = func;
	end

	frame.SetStatusText = function(self, text)
		self.StatusText:SetText(text);
	end

	frame.GetStatusText = function(self)
		return self.StatusText:GetText();
	end

	frame.SetText = function(self, text)
		self.EditBox:SetText(text);
	end

	frame.GetText = function(self)
		return self.EditBox:GetText();
	end

	frame.SetHeaderText = function(self, text)
		self.Header.text:SetText(text);
	end

	frame.GetHeaderText = function(self)
		return self.Header.text:GetText();
	end

	frame.SetInfoButton = function(self, enabled, func)
		if (enabled) then
			if (func ~= nil) then
				self.OnInfoButtonClick = func;
				self.InfoButton:Show();
				self.StatusTextFrame:ClearAllPoints();
				self.StatusTextFrame:SetPoint("BOTTOMLEFT", self, "BOTTOMLEFT", 15, 15);
				self.StatusTextFrame:SetPoint("RIGHT", self.InfoButton, "LEFT", -5, 0);
			else
				error("LibRedDropdown.LuaEditor.SetInfoButton: func must not be nil!");
			end
		else
			self.InfoButton:Hide();
			self.StatusTextFrame:ClearAllPoints();
			self.StatusTextFrame:SetPoint("RIGHT", frame.ApplyButton, "LEFT", -5, 0);
		end
	end

	frame.SetAcceptButton = function(self, enabled, func)
		self.OnAcceptFunc = func;
		if (enabled) then
			self.ApplyButton:Show();
		else
			self.ApplyButton:Hide();
		end
	end

	return frame;
end

function lib.CreateDropdown()
	local button = lib.CreateButton();
	button.menu = lib.CreateDropdownMenu();
	button.menu.autoAdjustHeight = true;

	-- value.text, value.font, value.icon, value.func, value.onEnter, value.onLeave, value.disabled, value.dontCloseOnClick, value.checkBoxEnabled, value.onCheckBoxClick, value.checkBoxState, onCloseButtonClick
	button.list = { };
	button.SetList = function(self, list)
		local wasVisible = false;
		if (self.menu:IsVisible()) then
			self.menu:Hide();
			wasVisible = true;
		end
		for _, value in pairs(list) do
			value.disabled = nil;
			value.dontCloseOnClick = nil;
			value.checkBoxEnabled = nil;
			value.onCloseButtonClick = nil;
			local oldFunc = value.func;
			value.func = function(clickedValue, ...)
				if (oldFunc ~= nil) then oldFunc(clickedValue, ...); end
				for _, _value in pairs(button.list) do
					_value.selected = nil;
				end
				clickedValue.selected = true;
				button:SetText(clickedValue.text);
				button:SetList(button.list);
			end;
			if (value.selected) then
				value.buttonColor = {0.38, 0.0, 0.38, 1};
				value.icon = 450908; --134337
				button:SetText(value.text);
			else
				value.buttonColor = nil;
				value.icon = nil;
			end
		end
		self.list = list;
		self.menu:SetList(self.list);
		if (wasVisible) then
			button:Click();
		end
	end

	button:SetScript("OnClick", function(self)
		if (self.menu:IsVisible()) then
			self.menu:Hide();
		else
			self.menu:SetParent(self);
			self.menu:ClearAllPoints();
			self.menu:SetPoint("TOP", self, "BOTTOM", 0, 0);
			self.menu:SetSize(self:GetWidth(), self.menu:GetHeight());
			self.menu:Show();
		end
	end);

	return button;
end
