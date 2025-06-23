local E, L, C = select(2, ...):unpack()

local addOnCommands = {}

local spellTypeStr
E.SlashHandler = function(msg)
	if msg then
		msg = strlower(msg)
	end
	local P = E.Party
	local command, value, subvalue = msg:match("^(%S*)%s*(%S*)%s*(.-)$")
	if command == "help" or command == "?" then
		E.write("v" .. E.Version)
		E.write(L["Usage:"])
		E.write("/oc <command> or /omnicd <command>")
		E.write(L["Commands:"])
		E.write("test or t: " .. L["Toggle test frames for current zone."])
		E.write("reload or rl: " .. L["Reload addon."])
		E.write("reset or rt: " .. L["Reset all cooldown timers."])
	elseif command == "rl" or command == "reload" then
		E:Refresh()
	elseif command == "t" or command == "test" then
		if E:GetModuleEnabled("Party") then
			local key = not P.isInTestMode and select(2, IsInInstance())
			P:Test(key)
		else
			E.write("Module not enabled!")
		end
		E:ACR_NotifyChange()
	elseif command == "rt" or command == "reset" then
		if value == "" then
			P:ResetAllIcons()
			E.write("Timers reset.")
		elseif value == "db" or value == "database" then

			E.Libs.OmniCDC.StaticPopup_Show("OMNICD_WIPE_DB")
		elseif value == "pf" or value == "profile" then
			E.DB:ResetProfile()
			E.write("Profile reset.")
			E:ACR_NotifyChange()
		elseif E.L_ALL_ZONE[value] then
			P:ResetOption(value)
			E.write(value, "-settings reset.")
			E:ACR_NotifyChange()
		else
			E.write("Invalid <value>.", value)
		end
	elseif command == "m" or command =="manual" then
		local key = E.L_CFG_ZONE[value] and value or "arena"
		E.profile.Party[key].position.detached = not E.profile.Party[key].position.detached
		local state = E.profile.Party[key].position.detached and VIDEO_OPTIONS_ENABLED or VIDEO_OPTIONS_DISABLED
		E.write(key, L["Manual Mode"], state)
		P:Refresh()
		E:ACR_NotifyChange()
	elseif command == "s" or command == "spell" or E.L_CFG_ZONE[command] then
		local zone = E.L_CFG_ZONE[command] and command or "arena"
		if value == "?" then
			if not spellTypeStr then
				for k in pairs(E.L_PRIORITY) do
					k = strlower(k)
					if not spellTypeStr then
						spellTypeStr = k
					else
						spellTypeStr = strjoin(", ", spellTypeStr, k)
					end
				end
				spellTypeStr = "Spell Types:\n" .. spellTypeStr
			end
			E.write("/oc <s[zone]> <spelltype|all|default|clear>")
			E.write("/oc <f[zone]> <spelltype|all|default> <1~8>")
			E.write(spellTypeStr)
		elseif value == "clear" then
			P:ResetOption(zone, "spells")
			for sId in pairs(E.profile.Party[zone].spells) do
				E.profile.Party[zone].spells[sId] = false
			end
		elseif value == "default" then
			P:ResetOption(zone, "spells")
		elseif value ~= "" then
			local removeType = gsub(value, "-", "")
			for id, v in pairs(E.hash_spelldb) do
				local sId = tostring(id)
				local type = strlower(v.type)
				if not v.hide and (value == "all" or value == type) then
					E.profile.Party[zone].spells[sId] = true
				elseif removeType == type then
					E.profile.Party[zone].spells[sId] = false
				end
			end
		end
		P:Refresh()
		E:ACR_NotifyChange()
	elseif command == "f" or command == "frame" or command == "spellframe" or E.L_CFG_ZONE[gsub(command, "^f", "")] then
		subvalue = tonumber(subvalue)
		subvalue = subvalue and min(max(subvalue, 0), 8) or 0
		local zone = gsub(command, "^f", "")
		zone = E.L_CFG_ZONE[zone] and zone or "arena"

		if value == "default" then
			P:ResetOption(zone, "Frame")
		elseif subvalue then
			for type in pairs(C.Party.arena.priority) do
				if value == "all" or value == type then
					E.profile.Party[zone].frame[type] = subvalue
				end

				for id, v in pairs(E.profile.Party[zone].spellFrame) do
					if E.hash_spelldb[id].type == type and v == subvalue then
						E.profile.Party[zone].spellFrame[id] = nil
					end
				end
			end
		end
		--[[ on spellFrame
		if value == "default" then
			P:ResetOption(zone, "spellFrame")
		elseif subvalue then
			for id, v in pairs(E.hash_spelldb) do
				local type = strlower(v.type)
				if not v.hide and (value == "all" or value == type) then
					E.profile.Party[zone].spellFrame[id] = subvalue
				end
			end
		end
		]]
		P:Refresh()
		E:ACR_NotifyChange()
	elseif command == "g" or command == "spellglow" or E.L_CFG_ZONE[gsub(command, "^g", "")] then
		local zone = gsub(command, "^g", "")
		zone = E.L_CFG_ZONE[zone] and zone or "arena"
		if value == "default" then
			P:ResetOption(zone, "spellGlow")
		elseif value ~= "" then
			for id, v in pairs(E.hash_spelldb) do
				local type = strlower(v.type)
				if not v.hide and (value == "all" or value == type) then
					E.profile.Party[zone].spellGlow[id] = true
				end
			end
		end
		P:UpdateAllBars()
		E:ACR_NotifyChange()
	elseif command == "tt" then
		E.TooltipID:Enable()
	elseif command == "nosync" then
		wipe(E.Comm.syncedGroupMembers)
		E.Comm.CopySendComm = E.Comm.SendComm
		E.Comm.COPY_CHAT_MSG_ADDON = E.Comm.CHAT_MSG_ADDON
		E.Comm.SendComm = E.Noop
		E.Comm.CHAT_MSG_ADDON = E.Noop
	elseif command == "sync" then
		if not E.Comm.CopySendComm then
			return
		end
		E.Comm.SendComm = E.Comm.CopySendComm
		E.Comm.CHAT_MSG_ADDON = E.Comm.COPY_CHAT_MSG_ADDON
	elseif addOnCommands[command] then
		addOnCommands[command](value, subvalue)
	else
		E:OpenOptionPanel()
	end
end

function E:OpenOptionPanel()
	self.Libs.ACD:SetDefaultSize(self.AddOn, 940, 627, self.global.optionPanelScale)
	self.Libs.ACD:Open(self.AddOn)

	for moduleName in pairs(E.moduleOptions) do
		self.Libs.ACD:SelectGroup(self.AddOn, moduleName)
	end
	self.Libs.ACD:SelectGroup(self.AddOn, "Home")
end

function E:SetupBlizzardOptions()
	local interfaceOptionPanel = CreateFrame("Frame", nil, UIParent)
	interfaceOptionPanel.name = E.AddOn
	interfaceOptionPanel:Hide()

	interfaceOptionPanel:SetScript("OnShow", function(self)
		local title = self:CreateFontString(nil, "ARTWORK", "GameFontNormalLarge")
		title:SetPoint("TOPLEFT", 16, -16)
		title:SetText(E.AddOn)

		local context = self:CreateFontString(nil, "ARTWORK", "GameFontHighlightSmall")
		context:SetPoint("TOPLEFT", title, "BOTTOMLEFT", 0, -8)
		context:SetText("Type /oc or /omnicd to open the option panel.")

		local open = CreateFrame("Button", nil, self, "UIPanelButtonTemplate")
		open:SetText("Open Option Panel")
		open:SetWidth(177)
		open:SetHeight(24)
		open:SetPoint("TOPLEFT", context, "BOTTOMLEFT", 0, -30)
		open.tooltipText = ""
		open:SetScript("OnClick", function()
			E:OpenOptionPanel()
		end)

		self:SetScript("OnShow", nil)
	end)

	if Settings and Settings.RegisterCanvasLayoutCategory then
		local category, layout = Settings.RegisterCanvasLayoutCategory(interfaceOptionPanel, E.AddOn)
		Settings.RegisterAddOnCategory(category)



	else
		InterfaceOptions_AddCategory(interfaceOptionPanel)
	end

	SLASH_OmniCD1 = "/oc"
	SLASH_OmniCD2 = "/omnicd"
	SlashCmdList[E.AddOn] = E.SlashHandler
end

E["addOnCommands"] = addOnCommands
