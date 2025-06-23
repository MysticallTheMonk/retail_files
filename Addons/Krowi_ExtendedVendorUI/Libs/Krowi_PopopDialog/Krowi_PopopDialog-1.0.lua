--[[
	Krowi's Popup Dialog License
		Copyright ©2020 The contents of this library, excluding third-party resources, are
		copyrighted to their authors with all rights reserved.

		This library is free to use and the authors hereby grants you the following rights:

		1. 	You may make modifications to this library for private use only, you
			may not publicize any portion of this library. The only exception being you may
			upload to the github website.

		2. 	Do not modify the name of this library, including the library folders.

		3. 	This copyright notice shall be included in all copies or substantial
			portions of the Software.

		All rights not explicitly addressed in this license are reserved by
		the copyright holders.
]]

local lib = LibStub:NewLibrary("Krowi_PopopDialog-1.0", 1);

if not lib then
	return;
end

-- [[ External Link Popup Dialog ]] --
local externalLink = "";
local externalLinkDialog = "KROWI_EXTERNAL_LINK";
StaticPopupDialogs[externalLinkDialog] = { -- Needs to be added to the Blizzard list
	text = "Press CTRL+X to copy the website and close this window.",
	button1 = "Close",
	hasEditBox = true,
	editBoxWidth = 500,
	timeout = 0,
	whileDead = true,
	hideOnEscape = true,
	preferredIndex = 3,
	OnShow = function(self)
		self.editBox:SetText(externalLink);
		self.editBox:HighlightText();
	end,
	EditBoxOnEscapePressed = function(self) self:GetParent().button1:Click(); end,
	EditBoxOnTextChanged = function(self)
		if self:GetText():len() < 1 then
			self:GetParent().button1:Click();
		else
			self:SetText(externalLink);
			self:HighlightText();
		end
	end,
}

function lib.ShowExternalLink(link)
    externalLink = link;
    StaticPopup_Show(externalLinkDialog);
end