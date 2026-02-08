--[[
    Copyright (c) 2023 Krowi
    Licensed under the terms of the LICENSE file in this repository.
]]

---@diagnostic disable: undefined-global

local lib = KROWI_LIBMAN:NewLibrary('Krowi_PopupDialog_2', 0, {
    SetCurrent = true,
    InitLocalization = true,
})
if not lib then	return end

-- [[ External Link Popup Dialog ]] --
local externalLink
local externalLinkDialog = 'KROWI_EXTERNAL_LINK'
StaticPopupDialogs[externalLinkDialog] = { -- Needs to be added to the Blizzard list
	text = '',
	button1 = '',
	hasEditBox = true,
	editBoxWidth = 500,
	timeout = 0,
	whileDead = true,
	hideOnEscape = true,
	OnShow = function(dialog)
		local editBox = dialog.editBox or dialog.EditBox
		editBox:SetMaxLetters(string.len(externalLink))
		editBox:SetText(externalLink)
		editBox:HighlightText()
	end,
	EditBoxOnTextChanged = function(editBox)
		local parent = editBox:GetParent()
		local button = parent.button1 or parent.ButtonContainer and parent.ButtonContainer.Button1
		if editBox:GetText():len() < 1 then
			if button then
				button:Click()
			end
		else
			editBox:SetMaxLetters(string.len(externalLink))
			editBox:SetText(externalLink)
			editBox:HighlightText()
		end
	end,
	EditBoxOnEscapePressed = function(editBox)
		local dialog = editBox:GetParent()
		local button = dialog.button1 or dialog.ButtonContainer and dialog.ButtonContainer.Button1
		if button then
			button:Click()
		end
	end,
}

function lib.ShowExternalLink(options, text, closeText)
	if type(options) ~= 'table' then
		options = {
			Link = options,
			Text = text,
			CloseText = closeText
		}
	end
	local dialog = StaticPopupDialogs[externalLinkDialog]
	dialog.text = options.Text or lib.L['Copy and close']
	dialog.button1 = options.CloseText or lib.L['Close']
	externalLink = options.Link or ''
	StaticPopup_Show(externalLinkDialog)
end

-- [[ Numeric Input Dialog ]] --
local numericInputCallback
local numericInputMin, numericInputMax
local numericInputDefault
local numericInputDialog = 'KROWI_NUMERIC_INPUT'
StaticPopupDialogs[numericInputDialog] = {
	text = '',
	button1 = '',
	button2 = '',
	hasEditBox = true,
	timeout = 0,
	whileDead = true,
	hideOnEscape = true,
	OnShow = function(dialog)
		local editBox = dialog.editBox or dialog.EditBox
		editBox:SetNumeric(true)
		editBox:SetMaxLetters(string.len(tostring(numericInputMax)))
		editBox:SetText(tostring(numericInputDefault))
		editBox:HighlightText()
	end,
	OnAccept = function(dialog)
		local editBox = dialog.editBox or dialog.EditBox
		local value = tonumber(editBox:GetText())
		if value and value >= numericInputMin and value <= numericInputMax and numericInputCallback then
			numericInputCallback(value)
		end
	end,
	EditBoxOnEnterPressed = function(editBox)
		editBox:SetNumeric(false)
		local dialog = editBox:GetParent()
		local button = dialog.button1 or dialog.ButtonContainer and dialog.ButtonContainer.Button1
		if button then
			button:Click()
		end
	end,
	EditBoxOnEscapePressed = function(editBox)
		editBox:SetNumeric(false)
		local dialog = editBox:GetParent()
		local button = dialog.button2 or dialog.ButtonContainer and dialog.ButtonContainer.Button2
		if button then
			button:Click()
		end
	end,
}

function lib.ShowNumericInput(options, min, max, default, callback, acceptText, cancelText)
	if type(options) ~= 'table' then
		options = {
			Text = options,
			AcceptText = acceptText,
			CancelText = cancelText,
			Min = min,
			Max = max,
			Default = default,
			Callback = callback
		}
	end
	local dialog = StaticPopupDialogs[numericInputDialog]
	dialog.text = options.Text or lib.L['Enter a number']
	dialog.button1 = options.AcceptText or lib.L['Accept']
	dialog.button2 = options.CancelText or lib.L['Cancel']
	numericInputMin = options.Min or 1
	numericInputMax = options.Max or 999
	numericInputDefault = options.Default or numericInputMin
	numericInputCallback = options.Callback
	StaticPopup_Show(numericInputDialog)
end