--
-- Masque Blizzard Bars
-- Enables Masque to skin the built-in WoW action bars
--
-- Copyright 2022 - 2024 SimGuy
--
-- Use of this source code is governed by an MIT-style
-- license that can be found in the LICENSE file or at
-- https://opensource.org/licenses/MIT.
--

local _, Shared = ...

-- From Locales/Locales.lua
-- Not used yet
--local L = Shared.Locale

-- From Metadata.lua
local Metadata = Shared.Metadata
local Groups = Metadata.Groups
-- Not used yet
--local Callbacks = Metadata.OptionCallbacks

-- From Core.lua
local Core = Shared.Core

-- Push us into shared object
local Addon = {}
Shared.Addon = Addon

-- Handle events for buttons that get created dynamically by Blizzard
function Addon:HandleEvent(event)
	-- Handle ExtraActionButton on Extra ActionBar updates
	--
	-- We don't handle the ZAB here because if EAB and ZAB are both
	-- active, the ZAB will get added after the event fires and get
	-- missed.
	if event == "UPDATE_EXTRA_ACTIONBAR" then
		local bar = Groups.ExtraAbilityContainer
		local eab = ExtraActionButton1

		-- Make sure the EAB exists and hasn't already been added
		if not bar.State.ExtraActionButton and eab and
		   eab:GetObjectType() == "CheckButton" then
			-- TODO: Update this to use Core:Skin()
			bar.Group:AddButton(eab, nil, "Action")
			bar.State.ExtraActionButton = true
			-- Move the overlay art behind the Normal frame
			if eab.style then
				eab.style:SetDrawLayer("ARTWORK", -1)
			end
		end

	-- Handle Pet Battle Buttons on Pet Battle start
	elseif event == "PET_BATTLE_OPENING_START" then
		local bar = Groups.PetBattleFrame
		local pbf = _G["PetBattleFrame"]["BottomFrame"]

		-- Find the Pet Battle Frame children that are buttons
		-- but only skin the ones that haven't already been seen
		for i = 1, select("#", pbf:GetChildren()) do
			local pbb = select(i, pbf:GetChildren())
			if type(pbb) == "table" and pbb.GetObjectType then
				local name = pbb:GetDebugName()
				local obj = pbb:GetObjectType()
				if bar.State.PetBattleButton[name] ~= pbb and
				   (obj == "CheckButton" or obj == "Button") then
					-- TODO: Update this to use Core:Skin()
					-- Define the regions for this weird button
					local pbbRegions = {
						Icon = pbb.Icon,
						Count = pbb.Count,
						Cooldown = nil, -- These buttons have no cooldown frame
						Normal = pbb.NormalTexture,
						Highlight = pbb:GetHighlightTexture()
					}
					bar.Group:AddButton(pbb, pbbRegions)
					bar.State.PetBattleButton[name] = pbb
				end
			end
		end
	end
end

-- ReSkin any action bars that are defined if needed
function Addon:ReSkinBars()
	for _, bar in ipairs({ "ActionBar", "MultiBarBottomLeft", "MultiBarBottomRight", "MultiBarLeft",
	                       "MultiBarRight", "MultiBar5", "MultiBar6", "MultiBar7" }) do
		if Groups[bar] and Groups[bar].Group then
			Groups[bar].Group:ReSkin()
		end
	end
end

-- Spell Flyout buttons are created as needed when a flyout is opened, so
-- check for any new buttons any time that happens
function Addon:SpellFlyout_Toggle(_, flyoutID)
	local _, _, numSlots, _ = GetFlyoutInfo(flyoutID)
	local activeSlots = 0
        for slot = 1, numSlots do
		local _, _, isKnown, _, _ = GetFlyoutSlotInfo(flyoutID, slot)
		if (isKnown) then
			activeSlots = activeSlots + 1
		end
	end

	-- Skin any extra buttons found
	local bar = Groups.SpellFlyout
	local numButtons = bar.Buttons.SpellFlyoutPopupButton
        if (numButtons < activeSlots) then
		bar.Buttons.SpellFlyoutPopupButton = activeSlots
		Core:Skin(bar.Buttons, bar.Group)
	end
end

function Addon:CooldownViewer_RefreshLayout()
	local frameName = self:GetName()
	if frameName and Groups.CooldownViewer.Buttons[frameName] then
		-- Map the Mask to a key and hide the overlay
		for _, frame in ipairs(self:GetItemFrames()) do
			if not frame.Mask then
				frame.Mask = frame.Icon:GetMaskTexture(1)
			end
			if not frame.IconOverlay then
				-- There should be one region left that isn't mapped
				for i = 1, select("#", frame:GetRegions()) do
					local texture = select(i, frame:GetRegions())
					if texture.GetAtlas and texture:GetAtlas() == "UI-HUD-CoolDownManager-IconOverlay" then
						frame.IconOverlay = texture
					end
				end
			end
			frame.IconOverlay:Hide()
		end
		Core:Skin(Groups.CooldownViewer.Buttons[frameName], Groups.CooldownViewer.Group, nil, nil, self, frameName)
	end
end

-- Attempt to adopt the ZoneAbilityButton, which has no name, when Blizzard
-- tries to update the displayed buttons. We do this here because when
-- UPDATE_EXTRA_ACTIONBAR is fired and both EAB and ZAB are active, it will
-- fire too early, the ZAB won't exist, and we'll miss it completely.
function Addon:ZoneAbilityFrame_UpdateDisplayedZoneAbilities()
	local zac = ZoneAbilityFrame.SpellButtonContainer
	local bar = Groups.ExtraAbilityContainer

	for i = 1, select("#", zac:GetChildren()) do
		local zab = select(i, zac:GetChildren())

		-- Try not to add buttons that are already added
		--
		-- I'm not sure if the Frame created for the ZAB is used for
		-- the whole life of the UI so if the frame changes, we'll
		-- skin whatever replaced it.
		if zab and zab:GetObjectType() == "Button" then
			local name = zab:GetDebugName()
			if bar.State.ZoneAbilityButton[name] ~= zab then

				-- TODO: Update this to use Core:Skin()
				-- Define the regions for this weird button
				local zabRegions = {
					Icon = zab.Icon,
					Count = zab.Count,
					Cooldown = zab.Cooldown,
					Normal = zab.NormalTexture,
					Highlight = zab:GetHighlightTexture()
				}

				bar.Group:AddButton(zab, zabRegions, "Action")
				bar.State.ZoneAbilityButton[name] = zab
			end
		end
	end
end

-- These are init steps specific to this addon
-- This should be run before Core:Init()
function Addon:Init()
	-- Spell Flyout
	if Core:CheckVersion({ 70003, nil }) then
		hooksecurefunc(SpellFlyout, "Toggle",
		               Addon.SpellFlyout_Toggle)
	end

	-- Cooldown Viewer
	if Core:CheckVersion({ 110105, nil }) then
		hooksecurefunc(BuffIconCooldownViewer, "RefreshLayout",
		               Addon.CooldownViewer_RefreshLayout)
		hooksecurefunc(EssentialCooldownViewer, "RefreshLayout",
		               Addon.CooldownViewer_RefreshLayout)
		hooksecurefunc(UtilityCooldownViewer, "RefreshLayout",
		               Addon.CooldownViewer_RefreshLayout)
	end

        -- Check if MoveAny is installed and handle the bar modifications it makes
	if UpdateActionBarBackground then
		hooksecurefunc("UpdateActionBarBackground", Addon.ReSkinBars)
	end

	-- Zone Ability Buttons
	-- This may be DraenorZoneAbilityFrame_Update if Classic reaches WoD
	-- This may be ZoneAbilityFrame_Update if Classic reaches Legion
	if Core:CheckVersion({ 90001, nil }) then
		hooksecurefunc(ZoneAbilityFrame, "UpdateDisplayedZoneAbilities",
		               Addon.ZoneAbilityFrame_UpdateDisplayedZoneAbilities)
	end

	Addon.Events = CreateFrame("Frame")

	-- Extra Action Button
	if Core:CheckVersion({ 40402, nil }) then
		Addon.Events:RegisterEvent("UPDATE_EXTRA_ACTIONBAR")
	end

	-- Pet Battles
	if Core:CheckVersion({ 50004, nil }) then
		Addon.Events:RegisterEvent("PET_BATTLE_OPENING_START")
	end

	Addon.Events:SetScript("OnEvent", Addon.HandleEvent)

	if Core:CheckVersion({ 100000, nil }) then
		-- Empty the whole options table because we have no options yet
		Metadata.Options = nil
	else
		-- Empty the whole options table because we don't support it on Classic
		Metadata.Options = nil
	end
end

Addon:Init()
Core:Init()
