local E, L, C = select(2, ...):unpack()

local DB_VERSION = 4

local function OmniCD_OnEvent(self, event, ...)
	if event == "ADDON_LOADED" then
		local addon = ...
		if addon == E.AddOn then
			if E.isClassic then
				local seasonID = C_Seasons.GetActiveSeason()

				if seasonID == 1 or seasonID == 2 then
					E.write("Seasonal Classic WoW isn't supported.")
				end
			end
			self:OnInitialize()
			self:UnregisterEvent("ADDON_LOADED")
			self:RegisterEvent("PLAYER_LOGIN")
			if E.postMoP then
				E:RegisterEvent("PET_BATTLE_OPENING_START")
			end
		end
	elseif event == "PLAYER_LOGIN" then
		self:OnEnable()
		self:UnregisterEvent("PLAYER_LOGIN")
		if not self.postMoP then
			self:SetScript("OnEvent", nil)
		end
	elseif event == "PET_BATTLE_CLOSE" then
		self.isInPetBattle = nil
		for moduleName in pairs(E.moduleOptions) do
			local module = E[moduleName]
			local func = module.Refresh
			if type(func) == "function" then
				func(module)
			end
		end
		self:UnregisterEvent("PET_BATTLE_CLOSE")
	elseif event == "PET_BATTLE_OPENING_START" then
		for moduleName in pairs(E.moduleOptions) do
			local module = E[moduleName]
			local func = module.Test
			if type(func) == "function" and module.isInTestMode then
				func(module)
			end
			func = module.HideAll
			if type(func) == "function" then
				func(module)
			end
			E.Party:CancelTimers()
		end
		self.isInPetBattle = true
		self:RegisterEvent("PET_BATTLE_CLOSE")
	end
end

E:RegisterEvent("ADDON_LOADED")
E:SetScript("OnEvent", OmniCD_OnEvent)

function E.FixOldProfile(profile)
	if type(profile) ~= "table" or type(profile.Party) ~= "table" then
		return
	end

	for _, db in pairs(profile.Party) do
		if type(db) == "table" and type(db.extraBars) == "table" then
			for k in pairs(db.extraBars) do
				if not C.Party.arena.extraBars[k] then
					db.extraBars[k] = nil
				end
			end
		end
	end
end

function E:OnInitialize()
	if not OmniCDDB or not OmniCDDB.version or OmniCDDB.version < 2.51 then
		OmniCDDB = { version = DB_VERSION }
	elseif OmniCDDB.version < DB_VERSION then
		if OmniCDDB.cooldowns then
			for k, v in pairs(OmniCDDB.cooldowns) do
				if not v.custom then
					OmniCDDB.cooldowns[k] = nil
				end
			end
			OmniCDDB.cooldowns[6262] = nil
		end
		if OmniCDDB.profiles then
			for _, profile in pairs(OmniCDDB.profiles) do
				if profile.Party then
					profile.Party.customPriority = nil
					for _, zone in pairs(profile.Party) do
						if type(zone) == "table" then
							zone.extraBars = nil
						end
					end
				end
			end
		end
		OmniCDDB.version = DB_VERSION
	else
		if OmniCDDB.profiles then
			for _, profile in pairs(OmniCDDB.profiles) do
				self.FixOldProfile(profile)
			end
		end
	end
	OmniCDDB.cooldowns = OmniCDDB.cooldowns or {}

	self.DB = LibStub("AceDB-3.0"):New("OmniCDDB", self.defaults, true)
	self.DB.RegisterCallback(self, "OnProfileChanged", "Refresh")
	self.DB.RegisterCallback(self, "OnProfileCopied", "Refresh")
	self.DB.RegisterCallback(self, "OnProfileReset", "Refresh")

	self.global = self.DB.global
	self.profile = self.DB.profile

	self.db = E:GetCurrentZoneSettings(select(2, IsInInstance()))

	self:CreateFontObjects()
	self:UpdateSpellList(true)
	self:SetupBlizzardOptions()
	self:SetupOptions()

end

function E:GetCurrentZoneSettings(instanceType)
	if instanceType == "none" then
		instanceType = self.profile.Party.noneZoneSetting
	elseif instanceType == "scenario" then
		instanceType = self.profile.Party.scenarioZoneSetting
	end
	return self.profile.Party[instanceType]
end

function E:CreateFontObjects()
	self.IconFont = CreateFont("IconFont-OmniCDC")
	self.IconFont:CopyFontObject("GameFontHighlightSmallOutline")
	self.AnchorFont = CreateFont("AnchorFont-OmniCDC")
	self.AnchorFont:CopyFontObject("GameFontNormal")
	self.StatusBarFont = CreateFont("StatusBarFont-OmniCDC")
	self.StatusBarFont:CopyFontObject("GameFontHighlightHuge")
end

function E:UpdateFontObjects()
	self:SetFontProperties(self.AnchorFont, self.profile.General.fonts.anchor)
	self:SetFontProperties(self.IconFont, self.profile.General.fonts.icon)
	self:SetFontProperties(self.StatusBarFont, self.profile.General.fonts.statusBar)
end

function E:OnEnable()
	self.isEnabled = true
	self:LoadAddOns()
	self:SetPixelMult()
	self:Refresh()

	if self.global.loginMessage then
		print(self.LoginMessage)
	end
end

function E:SetPixelMult()
	local pixelMult, uiUnitFactor = E.Libs.OmniCDC:GetPixelMult()
	self.PixelMult = pixelMult
	self.uiUnitFactor = uiUnitFactor
end

function E:Refresh(arg)
	if not self.isEnabled then
		return
	end

	self.profile = self.DB.profile

	self:UpdateFontObjects()

	for moduleName in pairs(self.moduleOptions) do
		local module = self[moduleName]

		local init = module.Initialize
		if init and type(init) == "function" then
			init(module)
			module.Initialize = nil
		end

		local enabled = self:GetModuleEnabled(moduleName)
		if enabled then
			if module.enabled then
				module:Refresh()
			else
				module:Enable()
			end
		else
			module:Disable()
		end
	end

	if arg == "OnProfileReset" then
		self.global.disableElvMsg = nil
	end
end

function E:GetModuleEnabled(moduleName)
	return self.profile.modules[moduleName]
end

function E:SetModuleEnabled(moduleName, isEnabled)
	self.profile.modules[moduleName] = isEnabled

	local module = self[moduleName]
	if isEnabled then
		module:Enable()
	else
		module:Disable()
	end
end

do
	local currentVersion = tonumber(E.Version:gsub("[^%d]", ""))
	local today = tonumber(date("%y%m%d"))
	local groupSize = 0
	local checkEnabled
	local checkTimer

	local function SendVersion()
		if checkEnabled then
			if IsInRaid() then
				C_ChatInfo.SendAddonMessage("OMNICD_VERSION", currentVersion, (not IsInRaid(LE_PARTY_CATEGORY_HOME) and IsInRaid(LE_PARTY_CATEGORY_INSTANCE)) and "INSTANCE_CHAT" or "RAID")
			elseif IsInGroup() then
				C_ChatInfo.SendAddonMessage("OMNICD_VERSION", currentVersion, (not IsInGroup(LE_PARTY_CATEGORY_HOME) and IsInGroup(LE_PARTY_CATEGORY_INSTANCE)) and "INSTANCE_CHAT" or "PARTY")
			elseif IsInGuild() then
				C_ChatInfo.SendAddonMessage("OMNICD_VERSION", currentVersion, "GUILD")
			end
		end
		checkTimer = nil
	end

	local function VersionCheck_OnEvent(self, event, prefix, version, _, sender)
		if event == "CHAT_MSG_ADDON" then
			if prefix ~= "OMNICD_VERSION" or sender == E.userNameWithRealm then
				return
			end

			version = tonumber(version)
			if version and version > currentVersion then
				local diff = version - currentVersion
				local text = diff > 10 and L["Major update"] or (diff > 1 and L["Minor update"]) or L["Hotfix"]
				text = format(L["A new update is available. |cff99cdff(%s)"], text)
				if E.global.notifyNew then
					E.write(text)
				end
				E.global.updateVersion = version
				E.global.updateType = text
				E.global.updateCheckDate = today

				self:UnregisterAllEvents()
				self:SetScript("OnEvent", nil)
				checkEnabled = nil
			end
		elseif event == "GROUP_ROSTER_UPDATE" then
			local num = GetNumGroupMembers()
			if num and num > groupSize then
				if not checkTimer then
					checkTimer = C_Timer.NewTimer(10, SendVersion)
				end
			end
			groupSize = num
		elseif event == "PLAYER_ENTERING_WORLD" then
			if not checkTimer then
				checkTimer = C_Timer.NewTimer(10, SendVersion)
			end
		end
	end

	function E:EnableVersionCheck()
		local updateVersion = self.global.updateVersion
		if updateVersion then
			if currentVersion >= updateVersion then
				self.global.updateType = nil
			end

			if today == self.global.updateCheckDate then
				return
			end

			if currentVersion < updateVersion then
				if self.global.notifyNew then
					self.write(self.global.updateType)
				end
				return
			end
		end

		checkEnabled = C_ChatInfo.RegisterAddonMessagePrefix("OMNICD_VERSION")
		local f = CreateFrame("Frame")
		f:RegisterEvent("CHAT_MSG_ADDON")
		f:RegisterEvent("GROUP_ROSTER_UPDATE")
		f:RegisterEvent("PLAYER_ENTERING_WORLD")
		f:SetScript("OnEvent", VersionCheck_OnEvent)
		self.useVersionCheck = true
	end
end
