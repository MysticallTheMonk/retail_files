local addonName, HideButtonGlow = ...

local CreateFrame, GetActionInfo, DEFAULT_CHAT_FRAME, Settings, GetSpellName = CreateFrame, GetActionInfo, DEFAULT_CHAT_FRAME, Settings, C_Spell.GetSpellName
local L = LibStub("AceLocale-3.0"):GetLocale("HideButtonGlow")

local EventFrame = CreateFrame("Frame")
EventFrame:SetScript("OnEvent", function(self, event, ...)
	if self[event] then return self[event](self, event, ...) end
end)
EventFrame:RegisterEvent("PLAYER_LOGIN")
EventFrame:RegisterEvent("ADDON_LOADED")

function EventFrame:PLAYER_LOGIN(event)
	self:UnregisterEvent(event)
	-- set up and validate db
	if not HideButtonGlowDB then
		HideButtonGlowDB = {}
	end
	if type(HideButtonGlowDB.hideAll) ~= "boolean" then
		HideButtonGlowDB.hideAll = false
	end
	if type(HideButtonGlowDB.debugMode) ~= "boolean" then
		HideButtonGlowDB.debugMode = false
	end
	if type(HideButtonGlowDB.filtered) ~= "table" then
		HideButtonGlowDB.filtered = {}
		-- migrate old db if present
		if type(HideButtonGlowDB.spells) == "table" then
			for i = 1, #HideButtonGlowDB.spells do
				HideButtonGlowDB.filtered[HideButtonGlowDB.spells[i]] = GetSpellName(HideButtonGlowDB.spells[i])
			end
			HideButtonGlowDB.spells = nil
		end
	end
	if type(HideButtonGlowDB.allowed) ~= "table" then
		HideButtonGlowDB.allowed = {}
		-- migrate old db if present
		if type(HideButtonGlowDB.allowedSpells) == "table" then
			for i = 1, #HideButtonGlowDB.allowedSpells do
				HideButtonGlowDB.allowed[HideButtonGlowDB.allowedSpells[i]] = GetSpellName(HideButtonGlowDB.allowedSpells[i])
			end
			HideButtonGlowDB.allowedSpells = nil
		end
	end
end

function EventFrame:ADDON_LOADED(event, loadedAddon)
	if loadedAddon ~= addonName then
		return
	end
	self:UnregisterEvent(event)
	SlashCmdList.HideButtonGlow = function()
		Settings.OpenToCategory(HideButtonGlow.categoryId)
	end
	SLASH_HideButtonGlow1 = "/hbg"
	SLASH_HideButtonGlow2 = "/hidebuttonglow"
end

function HideButtonGlow:AddMessage(message)
	DEFAULT_CHAT_FRAME:AddMessage(("|cFF00FF98HideButtonGlow:|r %s"):format(message))
end

do
	local lastPrintBySpell = {}
	function HideButtonGlow:AddDebugMessageWithSpell(message, spellId)
		if HideButtonGlowDB.debugMode then
			local t = GetTime()
			if t - (lastPrintBySpell[spellId] or 0) > 5 then
				lastPrintBySpell[spellId] = t
				self:AddMessage(message:format(GetSpellName(spellId) or "", spellId))
			end
		end
	end
end

function HideButtonGlow:ShouldHideGlow(spellId)
	-- check if the "hide all" option is set
	if HideButtonGlowDB.hideAll then
		if HideButtonGlowDB.allowed[spellId] then
			self:AddDebugMessageWithSpell(L.debug_allowed, spellId)
			return false
		end
		self:AddDebugMessageWithSpell(L.debug_filtered, spellId)
		return true
	end
	-- else check filter list
	if HideButtonGlowDB.filtered[spellId] then
		self:AddDebugMessageWithSpell(L.debug_filtered, spellId)
		return true
	end
	-- else show the glow
	self:AddDebugMessageWithSpell(L.debug_allowed, spellId)
	return false
end

-- LibButtonGlow

do
	local LibButtonGlow = LibStub("LibButtonGlow-1.0", true)
	if LibButtonGlow and LibButtonGlow.ShowOverlayGlow then
		local OriginalShowOverlayGlow = LibButtonGlow.ShowOverlayGlow
		function LibButtonGlow.ShowOverlayGlow(self)
			local spellId = self:GetSpellId()
			if not spellId or not HideButtonGlow:ShouldHideGlow(spellId) then
				return OriginalShowOverlayGlow(self)
			end
		end
	end
end

-- ElvUI

if ElvUI then
	local E = unpack(ElvUI)
	local LibCustomGlow = E and E.Libs and E.Libs.CustomGlow
	-- ElvUI adds a ShowOverlayGlow function to LibCustomGlow where there was not one before
	if LibCustomGlow and LibCustomGlow.ShowOverlayGlow then
		local OriginalShowOverlayGlow = LibCustomGlow.ShowOverlayGlow
		function LibCustomGlow.ShowOverlayGlow(self)
			local spellId = self.GetSpellId and self:GetSpellId()
			if not spellId or not HideButtonGlow:ShouldHideGlow(spellId) then
				return OriginalShowOverlayGlow(self)
			end
		end
	end
end

-- Blizzard Bars

if ActionButtonSpellAlertManager and C_ActionBar.IsAssistedCombatAction then -- Retail (11.1.7+)
	local IsAssistedCombatAction = C_ActionBar.IsAssistedCombatAction
	hooksecurefunc(ActionButtonSpellAlertManager, "ShowAlert", function(_, actionButton)
		local action = actionButton.action
		if not action then
			-- don't hide glows from buttons that don't have actions (PTR issue reporter)
			return
		end
		local spellType, id = GetActionInfo(action)
		-- only check spell and macro glows
		if id and (spellType == "spell" or spellType == "macro") and HideButtonGlow:ShouldHideGlow(id) then
			if IsAssistedCombatAction(action) then
				-- hide matched glows on the Single-Button Assistant button
				if actionButton.AssistedCombatRotationFrame and actionButton.AssistedCombatRotationFrame.SpellActivationAlert then
					actionButton.AssistedCombatRotationFrame.SpellActivationAlert:Hide()
				end
			elseif actionButton.SpellActivationAlert then
				-- hide matched glows on regular action bars
				actionButton.SpellActivationAlert:Hide()
			end
		end
	end)
else -- Classic, Retail (pre 11.1.7)
	hooksecurefunc("ActionButton_ShowOverlayGlow", function(actionButton)
		if actionButton and actionButton.action then
			local spellType, id = GetActionInfo(actionButton.action)
			if spellType == "macro" then
				-- needed on MoP Classic to convert the macro id to a spell id, not needed in 10.2+ as GetActionInfo will change
				-- to just return the spell id in the first place.
				id = GetMacroSpell(id)
			end
			-- only check spell and macro glows
			if id and (spellType == "spell" or spellType == "macro") and HideButtonGlow:ShouldHideGlow(id) then
				if actionButton.overlay then
					-- Cata Classic, Mists Classic, Retail (pre 10.0.2)
					actionButton.overlay:Hide()
				elseif actionButton.SpellActivationAlert then
					-- Retail (10.0.2+)
					actionButton.SpellActivationAlert:Hide()
				end
			end
		end
	end)
end
