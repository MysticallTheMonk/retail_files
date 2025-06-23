local E = unpack(select(2,...))

local module = E.Aura
local DB_VERSION = 1

local function OmniAuras_OnEvent(self, event, ...)
	if event == "ADDON_LOADED" then
		local addon = ...
		if addon == E.AddOn then
			self:OnInitialize()
			self:UnregisterEvent("ADDON_LOADED")
		end
	elseif event == "PLAYER_LOGIN" then
		self:OnEnable()
		self:UnregisterEvent("PLAYER_LOGIN")
		self:SetScript("OnEvent", nil)
	end
end

E:RegisterEvent("ADDON_LOADED")
E:RegisterEvent("PLAYER_LOGIN")
E:SetScript("OnEvent", OmniAuras_OnEvent)

function E:CreateFontObjects()
	self.RFCounter = CreateFont("RFCounter-OmniAuras")
	self.RFCounter:CopyFontObject("GameFontHighlight")
	self.UFCounter = CreateFont("UFCounter-OmniAuras")
	self.UFCounter:CopyFontObject("GameFontHighlight")
	self.NpCounter = CreateFont("NpCounter-OmniAuras")
	self.NpCounter:CopyFontObject("GameFontHighlight")
end

function E:UpdateFontObjects()
	self:SetFontProperties(self.RFCounter, self.profile.General.fonts.rfCounter)
	self:SetFontProperties(self.UFCounter, self.profile.General.fonts.ufCounter)
	self:SetFontProperties(self.NpCounter, self.profile.General.fonts.npCounter)
end

function E:SetPixelMult()
	local pixelMult, uiUnitFactor = E.Libs.OmniCDC:GetPixelMult()
	self.PixelMult = pixelMult
	self.uiUnitFactor = uiUnitFactor
end

function E:OnInitialize()
	if not OmniAurasDB or not OmniAurasDB.version then
		OmniAurasDB = { version = DB_VERSION }
	elseif OmniAurasDB.version < DB_VERSION then
		OmniAurasDB.version = DB_VERSION
	end
	OmniAurasDB.cooldowns = OmniAurasDB.cooldowns or {}

	self.DB = LibStub("AceDB-3.0"):New("OmniAurasDB", self.defaults, true)
	self.DB.RegisterCallback(self, "OnProfileChanged", "Refresh")
	self.DB.RegisterCallback(self, "OnProfileCopied", "Refresh")
	self.DB.RegisterCallback(self, "OnProfileReset", "Refresh")
	self.global = self.DB.global
	self.profile = self.DB.profile

	self:CreateFontObjects()
	self:UpdateSpellList(true)
	self:SetupOptions()
end

function E:OnEnable()
	self.enabled = true
	self:SetPixelMult()

	module:RegisterEvent("UI_SCALE_CHANGED")
	module:RegisterEvent("PLAYER_ENTERING_WORLD")
	module:RegisterEvent("ZONE_CHANGED_NEW_AREA") -- Delve's are walk-in (no loading screen)
	module:RegisterEvent("PLAYER_REGEN_ENABLED")
	module:RegisterEvent("PLAYER_REGEN_DISABLED")
	module:RegisterEvent("PLAYER_SPECIALIZATION_CHANGED")
	module:SetScript("OnEvent", function(module, event, ...)
		module[event](module, ...)
	end)

	--[[ if using ACD tooltip for the addon icons
	local ACD_Tooltip = E.Libs.ACD.tooltip
	self.BackdropTemplate(ACD_Tooltip)
	ACD_Tooltip:SetBackdropColor(0, 0, 0)
	ACD_Tooltip:SetBackdropBorderColor(0.3, 0.3, 0.3) ]]--

	module:SetHooks()
	module.CreateUnitFrameOverlays_OnLoad()
	self:Refresh()

	if self.global.loginMessage then
		print(self.LoginMessage)
	end

	module.enabled = true
end

function E:Refresh(arg)
	if not self.enabled then -- dualspec fix
		return
	end

	self.profile = self.DB.profile
	self.global = self.DB.global

	module:Refresh(arg)

	for modname in pairs(self.moduleOptions) do
		local module = self[modname]

		local init = module.Initialize
		if init and type(init) == "function" then
			init()
			module.Initialize = nil
		end

		local enabled = self:GetModuleEnabled(modname)
		if enabled then
			if module.enabled then
				module:Refresh(true)
			else
				module:Enable()
			end
		else
			module:Disable()
		end
	end
end

function E:GetModuleEnabled(modname)
	return self.profile.modules[modname]
end

function E:SetModuleEnabled(modname, isEnabled)
	self.profile.modules[modname] = isEnabled

	local module = self[modname]
	if isEnabled then
		module:Enable()
	else
		module:Disable()
	end
end

function E.ResetAllCVars()
	local editbox = ChatEdit_ChooseBoxForSend(DEFAULT_CHAT_FRAME)
	ChatEdit_ActivateChat(editbox)
	editbox:SetText("/console cvar_default")
	ChatEdit_OnEnterPressed(editbox)
end

E.SlashHandler = function(msg)
	local command, value = msg:match("^(%S*)%s*(.-)$");
	if command == "t" or command == "test" then
		module:ToggleTestMode()
	elseif command == "rt" or command == "reset" then
		if value == "db" or value == "database" then
--			E.DB:ResetDB("Default")
			OmniAurasDB = {}
			C_UI.Reload()
		elseif value == "profile" then
			E.DB:ResetProfile()
			E.write("Profile reset.")
			E:ACR_NotifyChange()
		elseif value == "cvar" then
			E.ResetAllCVars()
			C_UI.Reload()
		end
	elseif command == "rl" or command == "reload" then
		E:Refresh()
	else
		E:OpenOptionPanel()
	end
end

function E:OpenOptionPanel()
	self.Libs.ACD:SetDefaultSize(self.AddOn, 940, 627, self.global.optionPanelScale)
	self.Libs.ACD:Open(self.AddOn)
	self.Libs.ACD:SelectGroup(self.AddOn, "unitFrame")
	self.Libs.ACD:SelectGroup(self.AddOn, "Home")
end

local interfaceOptionPanel = CreateFrame("Frame", nil, UIParent)
interfaceOptionPanel.name = E.AddOn
interfaceOptionPanel:Hide()

interfaceOptionPanel:SetScript("OnShow", function(self)
	local title = self:CreateFontString(nil, "ARTWORK", "GameFontNormalLarge")
	title:SetPoint("TOPLEFT", 16, -16)
	title:SetText(E.AddOn)

	local context = self:CreateFontString(nil, "ARTWORK", "GameFontHighlightSmall")
	context:SetPoint("TOPLEFT", title, "BOTTOMLEFT", 0, -8)
	context:SetText("Type /oa or /omniauras to open the option panel.")

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
	local category = Settings.RegisterCanvasLayoutCategory(interfaceOptionPanel, E.AddOn)
	Settings.RegisterAddOnCategory(category)
else
	InterfaceOptions_AddCategory(interfaceOptionPanel)
end

SLASH_OmniAuras1 = "/oa"
SLASH_OmniAuras2 = "/omniauras"
SlashCmdList.OmniAuras = E.SlashHandler
