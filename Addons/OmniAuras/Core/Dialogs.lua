local E, L = unpack(select(2, ...))
local OmniCDC = E.Libs.OmniCDC

OmniCDC.StaticPopupDialogs["OMNIAURAS_IMPORT_BLACKLIST"] = {
	text = L["Press Accept to save aura blacklist."],
	button1 = ACCEPT,
	button2 = CANCEL,
	OnAccept = function(_, data)
		E.ProfileSharing:CopyBlacklistAuras(data)
		OmniAuras_ProfileDialogEditBox:SetText(L["Profile imported successfully!"])
		E:ACR_NotifyChange()
		E:Refresh()
	end,
	OnCancel = function()
		OmniAuras_ProfileDialogEditBox:SetText(L["Profile import cancelled!"])
	end,
	timeout = 0,
	whileDead = true,
	hideOnEscape = true,
	preferredIndex = STATICPOPUP_NUMDIALOGS
}

OmniCDC.StaticPopupDialogs["OMNIAURAS_IMPORT_EDITOR"] = {
	text = L["Importing Custom Spells will reload UI. Press Cancel to abort."],
	button1 = ACCEPT,
	button2 = CANCEL,
	OnAccept = function(_, data)
		E.ProfileSharing:CopyCustomSpells(data)
		OmniAuras_ProfileDialogEditBox:SetText(L["Profile imported successfully!"])
		C_UI.Reload()
	end,
	OnCancel = function()
		OmniAuras_ProfileDialogEditBox:SetText(L["Profile import cancelled!"])
	end,
	timeout = 0,
	whileDead = true,
	hideOnEscape = true,
	preferredIndex = STATICPOPUP_NUMDIALOGS
}

OmniCDC.StaticPopupDialogs["OMNIAURAS_IMPORT_PROFILE"] = {
	text = L["Press Accept to save profile %s. Addon will switch to the imported profile."],
	button1 = ACCEPT,
	button2 = CANCEL,
	OnAccept = function(_, data)
		E.ProfileSharing:CopyProfile(data.profileType, data.profileKey, data.profileData)
		if OmniAuras_ProfileDialogEditBox then
			OmniAuras_ProfileDialogEditBox:SetText(L["Profile imported successfully!"])
			E:ACR_NotifyChange()
		end
	end,
	OnCancel = function()
		if OmniAuras_ProfileDialogEditBox then
			OmniAuras_ProfileDialogEditBox:SetText(L["Profile import cancelled!"])
		end
	end,
	timeout = 0,
	whileDead = true,
	hideOnEscape = true,
	preferredIndex = STATICPOPUP_NUMDIALOGS
}
