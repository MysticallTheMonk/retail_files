local E, L = select(2, ...):unpack()

local OmniCDC = E.Libs.OmniCDC

OmniCDC.StaticPopupDialogs["OMNICD_CUSTOM_UF_MSG"] = {
	text = format("%s%s:|r %s", E.userClassHexColor, E.AddOn,
	L["Changing party display options in your UF addon while OmniCD is active will break the anchors. Type (/oc rl) to fix the anchors"]),
	button1 = OKAY,
	button2 = L["Don't show again"],
	OnCancel = function()
		E.global.disableElvMsg = true
	end,
	timeout = 0,
	whileDead = true,
	hideOnEscape = true,
	preferredIndex = STATICPOPUP_NUMDIALOGS
}

OmniCDC.StaticPopupDialogs["OMNICD_RELOADUI"] = {
	text = "%s",
	button1 = ACCEPT,
	button2 = CANCEL,
	OnAccept = function()
		C_AddOns.EnableAddOn("Blizzard_CompactRaidFrames")
		C_AddOns.EnableAddOn("Blizzard_CUFProfiles")
		C_UI.Reload()
	end,
	OnCancel = function()
		if E.Party.isInTestMode then
			E.Party:Test()
		end
	end,
	timeout = 0,
	whileDead = true,
	hideOnEscape = true,
	preferredIndex = STATICPOPUP_NUMDIALOGS
}

OmniCDC.StaticPopupDialogs["OMNICD_IMPORT_EDITOR"] = {
	text = L["Importing Custom Spells will reload UI. Press Cancel to abort."],
	button1 = ACCEPT,
	button2 = CANCEL,
	OnAccept = function(_, data)
		E.ProfileSharing:CopyCustomSpells(data)
		OmniCD_ProfileDialogEditBox:SetText(L["Profile imported successfully!"])
		C_UI.Reload()
	end,
	OnCancel = function()
		OmniCD_ProfileDialogEditBox:SetText(L["Profile import cancelled!"])
	end,
	timeout = 0,
	whileDead = true,
	hideOnEscape = true,
	preferredIndex = STATICPOPUP_NUMDIALOGS
}

OmniCDC.StaticPopupDialogs["OMNICD_IMPORT_PROFILE"] = {
	text = L["Press Accept to save profile %s. Addon will switch to the imported profile."],
	button1 = ACCEPT,
	button2 = CANCEL,
	OnAccept = function(_, data)
		E.ProfileSharing:CopyProfile(data.profileType, data.profileKey, data.profileData)
		OmniCD_ProfileDialogEditBox:SetText(L["Profile imported successfully!"])
		E:ACR_NotifyChange()
	end,
	OnCancel = function()
		OmniCD_ProfileDialogEditBox:SetText(L["Profile import cancelled!"])
	end,
	timeout = 0,
	whileDead = true,
	hideOnEscape = true,
	preferredIndex = STATICPOPUP_NUMDIALOGS
}

OmniCDC.StaticPopupDialogs["OMNICD_DF_TEST_MSG"] = {
	text = "|cffff2020%s",
	button1 = OKAY,
	button2 = CLOSE,
	timeout = 0,
	whileDead = true,
	hideOnEscape = true,
	preferredIndex = STATICPOPUP_NUMDIALOGS
}

OmniCDC.StaticPopupDialogs["OMNICD_WIPE_DB"] = {
	text = "|cffff2020Wipe DB?",
	button1 = OKAY,
	button2 = CLOSE,
	OnAccept = function(_, data)
		OmniCDDB = {}
		C_UI.Reload()
	end,
	timeout = 0,
	whileDead = true,
	hideOnEscape = true,
	preferredIndex = STATICPOPUP_NUMDIALOGS
}
