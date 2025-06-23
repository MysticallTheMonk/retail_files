local E, L = select(2, ...):unpack()
local P = E.Party

local TM = CreateFrame("Frame")

local AddOnTestMode = {}
local config = {}

AddOnTestMode.VuhDo = function(isTestEnabled)
	if not VUHDO_CONFIG then
		return
	end
	if isTestEnabled then
		config.VuhDo = VUHDO_CONFIG["HIDE_PANELS_SOLO"]
		VUHDO_CONFIG["HIDE_PANELS_SOLO"] = false
	else
		VUHDO_CONFIG["HIDE_PANELS_SOLO"] = config.VuhDo
	end
	VUHDO_getAutoProfile()
end

AddOnTestMode.ElvUI = function(isTestEnabled)
	ElvUI[1]:GetModule("UnitFrames"):HeaderConfig(ElvUF_Party, isTestEnabled)
end

function TM:Test(zone)
	P.isInTestMode = not P.isInTestMode

	if P.isInTestMode then
		if P.inLockdown then
			P.isInTestMode = false
			return E.write(ERR_NOT_IN_COMBAT)
		end

		if self:ShouldShowBlizzardFrames() then
			self:ShowBlizzardFrames()
		end
		self:ToggleAddOnTestFrames(P.isInTestMode)

		P:UpdateDelayedZoneData()
		P:Refresh()

		self:UpdateIndicator(zone)
		self:UselessBling()
		self:RegisterEvent("PLAYER_LEAVING_WORLD")
	else
		if self:ShouldShowBlizzardFrames() then
			self:HideBlizzardFrames()
		end
		self:ToggleAddOnTestFrames(P.isInTestMode)

		wipe(config)
		self.indicator:Hide()
		self:UnregisterEvent("PLAYER_LEAVING_WORLD")

		P:Refresh()
	end
end

function TM:ShouldShowBlizzardFrames()
	for _, db in pairs(E.db.extraBars) do
		if db.enabled and db.unitBar and (db.uf == "blizz" or db.uf == "auto")then
			return true
		end
	end
	return not E.db.position.detached and (E.db.position.uf == "blizz" or E.db.position.uf == "auto")
end

function TM:ShowBlizzardFrames()
	if E.postDF then
		if (GetNumGroupMembers() == 0 or not P:CompactFrameIsActive()) and not P.isInEditMode then
			ShowUIPanel(EditModeManagerFrame)
		end
		if P.isInEditMode
			and not EditModeManagerFrame:AreRaidFramesForcedShown()
			and not EditModeManagerFrame:ArePartyFramesForcedShown() then
			E.Libs.OmniCDC.StaticPopup_Show("OMNICD_DF_TEST_MSG", E.STR.ENABLE_HUDEDITMODE_FRAME)
		end
	else
		if E:IsBlizzardCUFLoaded() then
			CompactRaidFrameManager:Show()
			CompactRaidFrameContainer:Show()
		else
			E.Libs.OmniCDC.StaticPopup_Show("OMNICD_RELOADUI", E.STR.ENABLE_BLIZZARD_CRF)
		end
	end
end

function TM:HideBlizzardFrames()
	if E.postDF then

		if P.isInEditMode then
			if P.inLockdown then
				self:EndTestOOC()
			else
				HideUIPanel(EditModeManagerFrame)
			end
		end
	else
		if CompactRaidFrameContainer
			and CompactRaidFrameContainer:IsVisible()
			and (GetNumGroupMembers() == 0 or not P:CompactFrameIsActive()) then
			if P.inLockdown then
				self:EndTestOOC()
			else
				CompactRaidFrameManager:Hide()
				CompactRaidFrameContainer:Hide()
			end
		end
	end
end

function TM:ToggleAddOnTestFrames(isInTestMode)
	if not E.customUF.enabledList then
		return
	end
	for _, data in pairs(E.customUF.enabledList) do
		local addonName = data.addonName
		if AddOnTestMode[addonName] then
			AddOnTestMode[addonName](isInTestMode)
		end
	end
end

local function GetIndicator()
	local indicator = CreateFrame("Frame", nil, UIParent, "OmniCDTemplate")
	indicator.anchor.background:SetColorTexture(0,0,0,1)
	indicator.anchor.background:SetGradient("HORIZONTAL", CreateColor(1,1,1,1), CreateColor(1,1,1,0))
	indicator.anchor:SetHeight(15)
	indicator.anchor:EnableMouse(false)
	indicator:SetScript("OnHide", nil)
	indicator:SetScript("OnShow", nil)
	indicator.anchor.text:SetFontObject(E.AnchorFont)
	TM:SetScript("OnEvent", function(self, event, ...)
		self[event](self, ...)
	end)
	TM.indicator = indicator
	return indicator
end

function TM:UpdateIndicator(zone)
	local indicator = self.indicator or GetIndicator()
	indicator.anchor:ClearAllPoints()
	indicator.anchor:SetPoint("BOTTOMLEFT", P.userInfo.bar.anchor, "BOTTOMRIGHT")
	indicator.anchor:SetPoint("TOPLEFT", P.userInfo.bar.anchor, "TOPRIGHT")
	indicator.anchor.text:SetFormattedText("%s - %s", L["Test"], E.L_ALL_ZONE[zone])
	indicator.anchor:SetWidth(indicator.anchor.text:GetWidth() + 20)
	indicator:Show()
end

function TM:UselessBling()
	local bar = P.userInfo.bar
	for i = 1, bar.numIcons do
		local icon = bar.icons[i]
		if not icon.AnimFrame:IsVisible() then
			icon.AnimFrame:Show()
			icon.AnimFrame.animIn:Play()
		end
	end
end

function TM:EndTestOOC()
	if not E.postDF then
		E.write(L["Test frames will be hidden once player is out of combat"])
	end
	self:RegisterEvent("PLAYER_REGEN_ENABLED")
end

function TM:PLAYER_REGEN_ENABLED()
	if E.postDF then
		if P.isInEditMode then
			HideUIPanel(EditModeManagerFrame)
		end
	else
		if E:IsBlizzardCUFLoaded() and (P:GetEffectiveNumGroupMembers() == 0 or not P:CompactFrameIsActive()) then
			CompactRaidFrameManager:Hide()
			CompactRaidFrameContainer:Hide()
		end
	end
	self:UnregisterEvent("PLAYER_REGEN_ENABLED")
end




function TM:PLAYER_LEAVING_WORLD()

	if P.isInTestMode then
		self:ToggleAddOnTestFrames(P.isInTestMode)
	end
end

function P:Test(zone)
	E.db = E:GetCurrentZoneSettings(zone or self.testZone)
	self.testZone = zone
	TM:Test(zone)
end

P.TestMode = TM
E.AddOnTestMode = AddOnTestMode
