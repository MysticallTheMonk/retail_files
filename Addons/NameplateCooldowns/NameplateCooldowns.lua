-- luacheck: no max line length
-- luacheck: globals GetBuildInfo LibStub NAuras_LibButtonGlow UIParent bit GetTime C_Timer C_NamePlate UnitGUID wipe
-- luacheck: globals C_Spell SLASH_NAMEPLATECOOLDOWNS1 SlashCmdList UNKNOWN IsInGroup LE_PARTY_CATEGORY_INSTANCE IsInRaid C_ChatInfo CreateFrame
-- luacheck: globals unpack InCombatLockdown ColorPickerFrame BackdropTemplateMixin UIDropDownMenu_SetWidth UIDropDownMenu_AddButton GameFontNormal
-- luacheck: globals GameFontHighlightSmall hooksecurefunc ALL GameTooltip FillLocalizedClassList
-- luacheck: globals OTHER PlaySound SOUNDKIT COMBATLOG_OBJECT_REACTION_HOSTILE CombatLogGetCurrentEventInfo IsInInstance strsplit UnitName GetRealmName
-- luacheck: globals UnitReaction GetInstanceInfo C_UnitAuras

local _, addonTable = ...;
local Interrupts = addonTable.Interrupts;
local Trinkets = addonTable.Trinkets;
local Reductions = addonTable.Reductions;

--@non-debug@
local buildTimestamp = "110107.0-release";
--@end-non-debug@

-- Libraries
local L, LRD, SML, LBG_ShowOverlayGlow, LBG_HideOverlayGlow, LHT;
do
	L = LibStub("AceLocale-3.0"):GetLocale("NameplateCooldowns");
	LRD = LibStub("LibRedDropdown-1.0");
	LBG_ShowOverlayGlow, LBG_HideOverlayGlow = NAuras_LibButtonGlow.ShowOverlayGlow, NAuras_LibButtonGlow.HideOverlayGlow;

	SML = LibStub("LibSharedMedia-3.0");
	SML:Register("font", "NC_TeenBold", "Interface\\AddOns\\NameplateCooldowns\\media\\teen_bold.ttf", 255);

	LHT = LibStub("LibHealerTracker-1.0");
end

-- Consts
local SPELL_PVPADAPTATION, SPELL_PVPTRINKET, ICON_GROW_DIRECTION_RIGHT, ICON_GROW_DIRECTION_LEFT, ICON_GROW_DIRECTION_UP, SORT_MODE_NONE;
local SORT_MODE_TRINKET_INTERRUPT_OTHER, SORT_MODE_INTERRUPT_TRINKET_OTHER, SORT_MODE_TRINKET_OTHER, SORT_MODE_INTERRUPT_OTHER, GLOW_TIME_INFINITE, INSTANCE_TYPE_UNKNOWN;
local HUNTER_FEIGN_DEATH;
do
	SPELL_PVPADAPTATION, SPELL_PVPTRINKET = addonTable.SPELL_PVPADAPTATION, addonTable.SPELL_PVPTRINKET;
	ICON_GROW_DIRECTION_RIGHT, ICON_GROW_DIRECTION_LEFT, ICON_GROW_DIRECTION_UP =
		addonTable.ICON_GROW_DIRECTION_RIGHT, addonTable.ICON_GROW_DIRECTION_LEFT, addonTable.ICON_GROW_DIRECTION_UP;
	SORT_MODE_NONE, SORT_MODE_TRINKET_INTERRUPT_OTHER, SORT_MODE_INTERRUPT_TRINKET_OTHER, SORT_MODE_TRINKET_OTHER, SORT_MODE_INTERRUPT_OTHER =
		addonTable.SORT_MODE_NONE, addonTable.SORT_MODE_TRINKET_INTERRUPT_OTHER, addonTable.SORT_MODE_INTERRUPT_TRINKET_OTHER, addonTable.SORT_MODE_TRINKET_OTHER, addonTable.SORT_MODE_INTERRUPT_OTHER;
	GLOW_TIME_INFINITE = addonTable.GLOW_TIME_INFINITE;
	INSTANCE_TYPE_UNKNOWN = addonTable.INSTANCE_TYPE_UNKNOWN;
	HUNTER_FEIGN_DEATH = addonTable.HUNTER_FEIGN_DEATH;
end

-- Utilities
local SpellTextureByID, SpellNameByID = addonTable.SpellTextureByID, addonTable.SpellNameByID;

local SpellsPerPlayerGUID = { };

local ElapsedTimer = 0;
local Nameplates = {};
local NameplatesVisible = {};
local InstanceType = addonTable.INSTANCE_TYPE_NONE;
local AllCooldowns = { };
addonTable.AllCooldowns = AllCooldowns;
local EventFrame, TestFrame, db, aceDB, LocalPlayerGUID;
local FeignDeathGUIDs = {};

local pairs, string_gsub, string_find, bit_band, GetTime, math_ceil, table_sort, string_format, C_Timer_NewTimer, math_max, C_NamePlate_GetNamePlateForUnit, UnitGUID =
	  pairs, string.gsub,	string.find, bit.band, GetTime, math.ceil, table.sort, string.format, C_Timer.NewTimer, math.max, C_NamePlate.GetNamePlateForUnit, UnitGUID;
local wipe, IsInGroup, unpack, tinsert, UnitReaction, C_UnitAuras_GetAuraDataByIndex = wipe, IsInGroup, unpack, table.insert, UnitReaction, C_UnitAuras.GetAuraDataByIndex;
local GetInstanceInfo, CTimerAfter, GetSpellLink = GetInstanceInfo, C_Timer.After, C_Spell.GetSpellLink;

local OnStartup, InitializeDB;
local AllocateIcon, ReallocateAllIcons, UpdateOnlyOneNameplate, HideCDIcon, ShowCDIcon;
local OnUpdate;

-------------------------------------------------------------------------------------------------
----- Initialize
-------------------------------------------------------------------------------------------------
do

	function addonTable.GetDefaultDBEntryForSpell()
		return {
			["enabled"] = true,
			["glow"] = nil,
		};
	end

	local function AddToBlizzOptions()
		LibStub("AceConfig-3.0"):RegisterOptionsTable("NameplateCooldowns", {
			name = "NameplateCooldowns",
			type = "group",
			args = {
				openGUI = {
					type = 'execute',
					order = 1,
					name = 'Open config dialog',
					desc = nil,
					func = addonTable.ShowGUI,
				},
			},
		});
		LibStub("AceConfigDialog-3.0"):AddToBlizOptions("NameplateCooldowns", "NameplateCooldowns");
		local profilesConfig = LibStub("AceDBOptions-3.0"):GetOptionsTable(aceDB);
		LibStub("AceConfig-3.0"):RegisterOptionsTable("NameplateCooldowns.profiles", profilesConfig);
		LibStub("AceConfigDialog-3.0"):AddToBlizOptions("NameplateCooldowns.profiles", "Profiles", "NameplateCooldowns");
	end

	local function ReloadDB()
		db = aceDB.profile;
		addonTable.db = db;
		if (db.AddonEnabled) then
			EventFrame:UnregisterEvent("COMBAT_LOG_EVENT_UNFILTERED");
			wipe(SpellsPerPlayerGUID);
		else
			EventFrame:RegisterEvent("COMBAT_LOG_EVENT_UNFILTERED");
		end
		if (TestFrame and TestFrame:GetScript("OnUpdate") ~= nil) then
			addonTable.DisableTestMode();
		end
		OnUpdate();
		addonTable.GuiOnDbReload();
	end

	function InitializeDB()
		-- // set defaults
		local iconSize = 26;
		local aceDBDefaults = {
			profile = {
				SpellCDs = { },
				DBVersion = 0,
				MigrationVersion = 0,
				IconSpacing = 0,
				IconSize = iconSize,
				IconXOffset = 0,
				IconYOffset = 30,
				FullOpacityAlways = false,
				ShowBorderTrinkets = true,
				ShowBorderInterrupts = true,
				BorderInterruptsColor = {1, 0.35, 0},
				BorderTrinketsColor = {1, 0.843, 0},
				Font = "NC_TeenBold",
				IconSortMode = SORT_MODE_NONE,
				AddonEnabled = true,
				ShowCooldownsOnCurrentTargetOnly = false,
				EnabledZoneTypes = {
					["none"] =					true,
					[INSTANCE_TYPE_UNKNOWN] = 	true,
					["pvp"] = 					true,
					["arena"] = 				true,
					["party"] = 				true,
					["raid"] = 					true,
					["scenario"] = 				true,
				},
				ShowOldBlizzardBorderAroundIcons = false,
				FontScale = 1,
				TimerTextSize = math_ceil(iconSize - iconSize/2),
				TimerTextUseRelativeScale = true,
				TimerTextAnchor = "CENTER",
				TimerTextAnchorIcon = "CENTER",
				TimerTextXOffset = 0,
				TimerTextYOffset = 0,
				TimerTextColor = { 0.7, 1, 0 },
				IconGrowDirection = "right",
				CDFrameAnchor = "TOPLEFT",
				CDFrameAnchorToParent = "TOPLEFT",
				ShowCDOnAllies = false,
				ShowInactiveCD = false,
				IgnoreNameplateScale = false,
				ShowCooldownTooltip = false,
				InverseLogic = false,
				ShowCooldownAnimation = false,
				MinCdDuration = 0;
				MaxCdDuration = 10*3600
			},
		};
		aceDB = LibStub("AceDB-3.0"):New("NameplateCooldownsAceDB", aceDBDefaults);
		db = aceDB.profile;
		addonTable.db = aceDB.profile;
		addonTable.MigrateDB();
		AddToBlizzOptions();
		aceDB.RegisterCallback("NameplateCooldowns", "OnProfileChanged", ReloadDB);
		aceDB.RegisterCallback("NameplateCooldowns", "OnProfileCopied", ReloadDB);
		aceDB.RegisterCallback("NameplateCooldowns", "OnProfileReset", ReloadDB);
	end

	function addonTable.BuildCooldownValues()
		wipe(AllCooldowns);
		for class, cds in pairs(addonTable.CDs) do
			for spellId, cd in pairs(cds) do
				if (SpellNameByID[spellId] ~= nil) then
					AllCooldowns[spellId] = cd;
					if (db.SpellCDs[spellId] == nil) then
						db.SpellCDs[spellId] = addonTable.GetDefaultDBEntryForSpell();
						addonTable.Print(string_format(L["New spell has been added: %s"].." (%s)", GetSpellLink(spellId) or SpellNameByID[spellId], class));
					end
				end
			end
		end
		for spellID in pairs(AllCooldowns) do
			if (db.SpellCDs[spellID] ~= nil and db.SpellCDs[spellID].customCD ~= nil) then
				AllCooldowns[spellID] = db.SpellCDs[spellID].customCD;
			end
		end

		-- delete invalid spells
		for spellId in pairs(db.SpellCDs) do
			if (SpellNameByID[spellId] == nil) then
				db.SpellCDs[spellId] = nil;
				print("Spell with id:" .. tostring(spellId) .. " seems to be invalid, removing from db...");
			end
		end
	end

	function OnStartup()
		LocalPlayerGUID = UnitGUID("player");
		InitializeDB();
		addonTable.BuildCooldownValues();
		-- // starting OnUpdate()
		EventFrame:SetScript("OnUpdate", function(_, elapsed)
			ElapsedTimer = ElapsedTimer + elapsed;
			if (ElapsedTimer >= 1) then
				OnUpdate();
				ElapsedTimer = 0;
			end
		end);
		-- // starting listening for events
		if (db.AddonEnabled) then
			EventFrame:RegisterEvent("COMBAT_LOG_EVENT_UNFILTERED");
		else
			addonTable.Print(L["chat:addon-is-disabled-note"]);
		end
		if (db.ShowCooldownsOnCurrentTargetOnly) then
			EventFrame:RegisterEvent("PLAYER_TARGET_CHANGED");
			--addonTable.Print(L["chat:enable-only-for-target-nameplate"]);
		end
		EventFrame:RegisterEvent("NAME_PLATE_UNIT_ADDED");
		EventFrame:RegisterEvent("NAME_PLATE_UNIT_REMOVED");
		EventFrame:RegisterEvent("UNIT_AURA");
		SLASH_NAMEPLATECOOLDOWNS1 = '/nc';
		SlashCmdList["NAMEPLATECOOLDOWNS"] = function(msg)
			if (msg == "t" or msg == "ver") then
				local c;
				if (IsInGroup(LE_PARTY_CATEGORY_INSTANCE)) then
					c = "INSTANCE_CHAT";
				elseif (IsInRaid()) then
					c = "RAID";
				else
					c = "GUILD";
				end
				addonTable.Print("Waiting for replies from " .. c);
				C_ChatInfo.SendAddonMessage("NC_prefix", "requesting", c);
			elseif (msg == "test") then
				if (not addonTable.TestModeActive) then
					addonTable.EnableTestMode();
				else
					addonTable.DisableTestMode();
				end
			else
				addonTable.ShowGUI();
			end
		end
		OnStartup = nil;
	end

	function addonTable.OnDbChanged()
		if (db.ShowCooldownsOnCurrentTargetOnly) then
			EventFrame:RegisterEvent("PLAYER_TARGET_CHANGED");
		else
			EventFrame:UnregisterEvent("PLAYER_TARGET_CHANGED");
		end
		ReallocateAllIcons(true);
	end

end

-------------------------------------------------------------------------------------------------
----- Nameplates
-------------------------------------------------------------------------------------------------
do

	local glowInfo = { };

	local iconTooltip = LRD.CreateTooltip();
	local function SetCooldownTooltip(icon, spellID)
		if (db.ShowCooldownTooltip and spellID ~= nil) then
			icon:SetScript("OnEnter", function(self)
				iconTooltip:ClearAllPoints();
				iconTooltip:SetPoint("BOTTOM", self, "TOP", 0, 0);
				iconTooltip:SetSpellById(spellID);
				iconTooltip:Show();
			end);
			icon:SetScript("OnLeave", function()
				iconTooltip:Hide();
			end);
		else
			icon:SetScript("OnEnter", nil);
			icon:SetScript("OnLeave", nil);
		end
	end
	addonTable.SetCooldownTooltip = SetCooldownTooltip;

	local function AllocateIcon_SetIconPlace(frame, icon, iconIndex)
		icon:ClearAllPoints();
		local index = iconIndex == nil and frame.NCIconsCount or (iconIndex-1)
		if (index == 0) then
			if (db.IconGrowDirection == ICON_GROW_DIRECTION_RIGHT) then
				icon:SetPoint("LEFT", frame.NCFrame, "LEFT", 0, 0);
			elseif (db.IconGrowDirection == ICON_GROW_DIRECTION_LEFT) then
				icon:SetPoint("RIGHT", frame.NCFrame, "RIGHT", 0, 0);
			elseif (db.IconGrowDirection == ICON_GROW_DIRECTION_UP) then
				icon:SetPoint("BOTTOM", frame.NCFrame, "BOTTOM", 0, 0);
			else -- // down
				icon:SetPoint("TOP", frame.NCFrame, "TOP", 0, 0);
			end
		else
			if (db.IconGrowDirection == ICON_GROW_DIRECTION_RIGHT) then
				icon:SetPoint("LEFT", frame.NCIcons[index], "RIGHT", db.IconSpacing, 0);
			elseif (db.IconGrowDirection == ICON_GROW_DIRECTION_LEFT) then
				icon:SetPoint("RIGHT", frame.NCIcons[index], "LEFT", -db.IconSpacing, 0);
			elseif (db.IconGrowDirection == ICON_GROW_DIRECTION_UP) then
				icon:SetPoint("BOTTOM", frame.NCIcons[index], "TOP", 0, db.IconSpacing);
			else -- // down
				icon:SetPoint("TOP", frame.NCIcons[index], "BOTTOM", 0, -db.IconSpacing);
			end
		end
	end

	local function SetFrameSize(frame)
		local maxWidth, maxHeight = 0, 0;
		local vertical = db.IconGrowDirection == ICON_GROW_DIRECTION_RIGHT or db.IconGrowDirection == ICON_GROW_DIRECTION_LEFT;
		if (frame.NCFrame) then
			for _, icon in pairs(frame.NCIcons) do
				if (icon.shown) then
					if (vertical) then -- right -- left
						maxHeight = math_max(maxHeight, icon:GetHeight());
						maxWidth = maxWidth + icon:GetWidth() + db.IconSpacing;
					else -- up -- down
						maxHeight = maxHeight + icon:GetHeight() + db.IconSpacing;
						maxWidth = math_max(maxWidth, icon:GetWidth());
					end
				end
			end
		end
		maxWidth = maxWidth - db.IconSpacing;
		maxHeight = maxHeight - db.IconSpacing;
		frame.NCFrame:SetWidth(math_max(maxWidth, 1));
		frame.NCFrame:SetHeight(math_max(maxHeight, 1));
	end

	local function GetNameplateAddonFrame(_nameplate)
		-- local frame = _nameplate.TPFrame;
		-- if (frame ~= nil) then
		-- 	return frame;
		-- end

		return _nameplate;
	end

	function AllocateIcon(frame)
		if (not frame.NCFrame) then
			frame.NCFrame = CreateFrame("frame", nil, frame);
			frame.NCFrame:SetIgnoreParentAlpha(db.FullOpacityAlways);
			frame.NCFrame:SetIgnoreParentScale(db.IgnoreNameplateScale);
			frame.NCFrame:SetWidth(db.IconSize);
			frame.NCFrame:SetHeight(db.IconSize);
			local anchorFrame = GetNameplateAddonFrame(frame);
			frame.NCFrame:SetPoint(db.CDFrameAnchor, anchorFrame, db.CDFrameAnchorToParent, db.IconXOffset, db.IconYOffset);
			frame.NCFrame:Show();
		end
		local icon = CreateFrame("frame", nil, frame.NCFrame);
		icon:SetWidth(db.IconSize);
		icon:SetHeight(db.IconSize);
		AllocateIcon_SetIconPlace(frame, icon);
		icon:Hide();

		icon.cooldownFrame = CreateFrame("Cooldown", nil, icon, "CooldownFrameTemplate");
		icon.cooldownFrame:SetAllPoints(icon);
		icon.cooldownFrame:SetReverse(true);
		icon.cooldownFrame:SetHideCountdownNumbers(true);
		icon.cooldownFrame.noCooldownCount = true; -- refuse OmniCC

		icon.texture = icon:CreateTexture(nil, "BORDER");
		icon.texture:SetAllPoints(icon);
		if (not db.ShowOldBlizzardBorderAroundIcons) then
			icon.texture:SetTexCoord(0.07, 0.93, 0.07, 0.93);
		end
		icon.cooldownText = icon:CreateFontString(nil, "OVERLAY");
		icon.cooldownText:SetTextColor(unpack(db.TimerTextColor));
		icon.cooldownText:SetPoint(db.TimerTextAnchor, icon, db.TimerTextAnchorIcon, db.TimerTextXOffset, db.TimerTextYOffset);
		if (db.TimerTextUseRelativeScale) then
			icon.cooldownText:SetFont(SML:Fetch("font", db.Font), math_ceil((db.IconSize - db.IconSize / 2) * db.FontScale), "OUTLINE");
		else
			icon.cooldownText:SetFont(SML:Fetch("font", db.Font), db.TimerTextSize, "OUTLINE");
		end
		icon.border = icon:CreateTexture(nil, "OVERLAY");
		icon.border:SetTexture("Interface\\AddOns\\NameplateCooldowns\\media\\CooldownFrameBorder.tga");
		icon.border:SetVertexColor(1, 0.35, 0);
		icon.border:SetAllPoints(icon);
		icon.border:Hide();
		frame.NCIconsCount = frame.NCIconsCount + 1;
		tinsert(frame.NCIcons, icon);
	end

	function ReallocateAllIcons(clearSpells)
		for frame in pairs(Nameplates) do
			if (frame.NCFrame) then
				frame.NCFrame:SetIgnoreParentAlpha(db.FullOpacityAlways);
				frame.NCFrame:SetIgnoreParentScale(db.IgnoreNameplateScale);
				frame.NCFrame:ClearAllPoints();
				local anchorFrame = GetNameplateAddonFrame(frame);
				frame.NCFrame:SetPoint(db.CDFrameAnchor, anchorFrame, db.CDFrameAnchorToParent, db.IconXOffset, db.IconYOffset);
				local counter = 0;
				for iconIndex, icon in pairs(frame.NCIcons) do
					icon:SetWidth(db.IconSize);
					icon:SetHeight(db.IconSize);
					AllocateIcon_SetIconPlace(frame, icon, iconIndex);
					if (not db.ShowOldBlizzardBorderAroundIcons) then
						icon.texture:SetTexCoord(0.07, 0.93, 0.07, 0.93);
					else
						icon.texture:SetTexCoord(0, 1, 0, 1);
					end
					icon.cooldownText:SetTextColor(unpack(db.TimerTextColor));
					icon.cooldownText:ClearAllPoints();
					icon.cooldownText:SetPoint(db.TimerTextAnchor, icon, db.TimerTextAnchorIcon, db.TimerTextXOffset, db.TimerTextYOffset);
					if (db.TimerTextUseRelativeScale) then
						icon.cooldownText:SetFont(SML:Fetch("font", db.Font), math_ceil((db.IconSize - db.IconSize / 2) * db.FontScale), "OUTLINE");
					else
						icon.cooldownText:SetFont(SML:Fetch("font", db.Font), db.TimerTextSize, "OUTLINE");
					end

					if (clearSpells) then
						HideCDIcon(icon, frame);
					end
					counter = counter + 1;
				end
				SetFrameSize(frame);
			end
		end
		if (clearSpells) then
			OnUpdate();
		end
	end

	local function GlobalFilterNameplate(unitGUID)
		if (not db.ShowCooldownsOnCurrentTargetOnly or UnitGUID("target") == unitGUID) then
			if (db.EnabledZoneTypes[InstanceType]) then
				return true;
			end
		end
		return false;
	end

	local CDSortFunctions = {
		[SORT_MODE_NONE] = function() end,
		[SORT_MODE_TRINKET_INTERRUPT_OTHER] = function(item1, item2)
			if (Trinkets[item1.spellID]) then
				if (Trinkets[item2.spellID]) then
					return item1.expires < item2.expires;
				else
					return true;
				end
			elseif (Trinkets[item2.spellID]) then
				return false;
			elseif (Interrupts[item1.spellID]) then
				if (Interrupts[item2.spellID]) then
					return item1.expires < item2.expires;
				else
					return true;
				end
			elseif (Interrupts[item2.spellID]) then
				return false;
			else
				return item1.expires < item2.expires;
			end
		end,
		[SORT_MODE_INTERRUPT_TRINKET_OTHER] = function(item1, item2)
			if (Interrupts[item1.spellID]) then
				if (Interrupts[item2.spellID]) then
					return item1.expires < item2.expires;
				else
					return true;
				end
			elseif (Interrupts[item2.spellID]) then
				return false;
			elseif (Trinkets[item1.spellID]) then
				if (Trinkets[item2.spellID]) then
					return item1.expires < item2.expires;
				else
					return true;
				end
			elseif (Trinkets[item2.spellID]) then
				return false;
			else
				return item1.expires < item2.expires;
			end
		end,
		[SORT_MODE_TRINKET_OTHER] = function(item1, item2)
			if (Trinkets[item1.spellID]) then
				if (Trinkets[item2.spellID]) then
					return item1.expires < item2.expires;
				else
					return true;
				end
			elseif (Trinkets[item2.spellID]) then
				return false;
			else
				return item1.expires < item2.expires;
			end
		end,
		[SORT_MODE_INTERRUPT_OTHER] = function(item1, item2)
			if (Interrupts[item1.spellID]) then
				if (Interrupts[item2.spellID]) then
					return item1.expires < item2.expires;
				else
					return true;
				end
			elseif (Interrupts[item2.spellID]) then
				return false;
			else
				return item1.expires < item2.expires;
			end
		end,
	};

	local function Nameplate_SortAuras(cds)
		local t = { };
		for _, spellInfo in pairs(cds) do
			if (spellInfo ~= nil) then
				t[#t+1] = spellInfo;
			end
		end
		table_sort(t, CDSortFunctions[db.IconSortMode]);
		return t;
	end

	local function UpdateNameplate_SetGlow(icon, spellNeedGlow, remain, isActive)
		if (glowInfo[icon]) then
			glowInfo[icon]:Cancel(); -- // cancel delayed glow
			glowInfo[icon] = nil;
		end
		if (not isActive) then
			if (icon.glow ~= false) then
				LBG_HideOverlayGlow(icon);
				icon.glow = false;
			end
		else
			if (spellNeedGlow ~= nil) then
				if (remain < spellNeedGlow or remain > GLOW_TIME_INFINITE) then
					if (icon.glow ~= true) then
						LBG_ShowOverlayGlow(icon, true, true); -- // show glow immediately
						icon.glow = true;
					end
				else
					LBG_HideOverlayGlow(icon); -- // hide glow
					icon.glow = false;
					glowInfo[icon] = C_Timer_NewTimer(remain - spellNeedGlow, function() LBG_ShowOverlayGlow(icon, true, true); icon.glow = true; end); -- // queue delayed glow
				end
			elseif (icon.glow ~= false) then
				LBG_HideOverlayGlow(icon); -- // this aura doesn't require glow
				icon.glow = false;
			end
		end
	end

	local function Nameplate_SetBorder(icon, spellID, isActive)
		if (isActive and db.ShowBorderInterrupts and Interrupts[spellID]) then
			if (icon.borderState ~= 1) then
				icon.border:SetVertexColor(unpack(db.BorderInterruptsColor));
				icon.border:Show();
				icon.borderState = 1;
			end
		elseif (isActive and db.ShowBorderTrinkets and Trinkets[spellID]) then
			if (icon.borderState ~= 2) then
				icon.border:SetVertexColor(unpack(db.BorderTrinketsColor));
				icon.border:Show();
				icon.borderState = 2;
			end
		elseif (icon.borderState ~= nil) then
			icon.border:Hide();
			icon.borderState = nil;
		end
	end

	local function Nameplate_SetCooldown(icon, remain, started, cooldownLength, isActive)
		if (remain > 0 and (isActive or db.InverseLogic)) then
			local text = (remain >= 60) and (math_ceil(remain/60).."m") or math_ceil(remain);
			if (icon.text ~= text) then
				icon.cooldownText:SetText(text);
				icon.text = text;
				if (not db.ShowCooldownAnimation or not isActive or db.InverseLogic) then
					icon.cooldownText:SetParent(icon);
				else
					icon.cooldownText:SetParent(icon.cooldownFrame);
				end
			end
		elseif (icon.text ~= "") then
			icon.cooldownText:SetText("");
			icon.text = "";
		end

		-- cooldown animation
		if (db.ShowCooldownAnimation and isActive and not db.InverseLogic) then
			if (started ~= icon.cooldownStarted or cooldownLength ~= icon.cooldownLength) then
				icon.cooldownFrame:SetCooldown(started, cooldownLength);
				icon.cooldownFrame:Show();
				icon.cooldownStarted = started;
				icon.cooldownLength = cooldownLength;
			end
		else
			icon.cooldownFrame:Hide();
		end
	end

	local function UpdateOnlyOneNameplate_SetTexture(icon, texture, isActive)
		if (icon.textureID ~= texture) then
			icon.texture:SetTexture(texture);
			icon.textureID = texture;
		end
		if (icon.desaturation ~= not isActive) then
			icon.texture:SetDesaturated(not isActive);
			icon.desaturation = not isActive;
		end
	end

	local function UpdateOnlyOneNameplate_FilterSpell(_dbInfo, _remain, _isActiveCD)
		if (not _dbInfo or not _dbInfo.enabled) then
			return false;
		end

		if (not db.ShowInactiveCD and not _isActiveCD) then
			return false;
		end

		if (_remain > 0 and (_remain < db.MinCdDuration or _remain > db.MaxCdDuration)) then
			return false;
		end

		return true;
	end

	function UpdateOnlyOneNameplate(frame, unitGUID)
		if (unitGUID == LocalPlayerGUID) then return; end
		local counter = 1;
		if (GlobalFilterNameplate(unitGUID)) then
			if (SpellsPerPlayerGUID[unitGUID]) then
				local currentTime = GetTime();
				local sortedCDs = Nameplate_SortAuras(SpellsPerPlayerGUID[unitGUID]);
				for _, spellInfo in pairs(sortedCDs) do
					local spellID = spellInfo.spellID;
					local isActiveCD = spellInfo.expires > currentTime;
					if (db.InverseLogic) then
						isActiveCD = not isActiveCD;
					end
					local dbInfo = db.SpellCDs[spellID];
					local remain = spellInfo.expires - currentTime;
					if (UpdateOnlyOneNameplate_FilterSpell(dbInfo, remain, isActiveCD)) then
						if (counter > frame.NCIconsCount) then
							AllocateIcon(frame);
						end
						local icon = frame.NCIcons[counter];
						UpdateOnlyOneNameplate_SetTexture(icon, spellInfo.texture, isActiveCD);
						UpdateNameplate_SetGlow(icon, dbInfo.glow, remain, isActiveCD);
						local cooldown = AllCooldowns[spellID];
						Nameplate_SetCooldown(icon, remain, spellInfo.started, cooldown, isActiveCD);
						Nameplate_SetBorder(icon, spellID, isActiveCD);
						SetCooldownTooltip(icon, spellID);
						if (not icon.shown) then
							ShowCDIcon(icon, frame);
						end
						counter = counter + 1;
					end
				end
			end
		end
		for k = counter, frame.NCIconsCount do
			local icon = frame.NCIcons[k];
			if (icon.shown) then
				HideCDIcon(icon, frame);
			end
		end
	end

	function HideCDIcon(icon, frame)
		icon.border:Hide();
		icon.borderState = nil;
		icon.cooldownText:Hide();
		icon:Hide();
		icon.shown = false;
		icon.textureID = 0;
		LBG_HideOverlayGlow(icon);
		SetFrameSize(frame);
	end

	function ShowCDIcon(icon, frame)
		icon.cooldownText:Show();
		icon:Show();
		icon.shown = true;
		SetFrameSize(frame);
	end

end

-------------------------------------------------------------------------------------------------
----- OnUpdates
-------------------------------------------------------------------------------------------------
do
	function OnUpdate()
		for frame, unitGUID in pairs(NameplatesVisible) do
			UpdateOnlyOneNameplate(frame, unitGUID);
		end
	end
end

-------------------------------------------------------------------------------------------------
----- Test mode
-------------------------------------------------------------------------------------------------
do

	local _t = 0;
	local _charactersDB;
	local _spellCDs;
	local _spellIDs = {
		[2139] 		= 24,
		[108194] 	= 45,
		[100] 		= -17,
	};

	local function refreshCDs()
		local cTime = GetTime();
		for _, unitGUID in pairs(NameplatesVisible) do
			if (not SpellsPerPlayerGUID[unitGUID]) then SpellsPerPlayerGUID[unitGUID] = { }; end
			SpellsPerPlayerGUID[unitGUID][SPELL_PVPTRINKET] = { ["spellID"] = SPELL_PVPTRINKET, ["expires"] = cTime + 120, ["texture"] = SpellTextureByID[SPELL_PVPTRINKET], ["started"] = cTime }; -- // 2m test
			for spellID, cd in pairs(_spellIDs) do
				if (not SpellsPerPlayerGUID[unitGUID][spellID]) then
					SpellsPerPlayerGUID[unitGUID][spellID] = { ["spellID"] = spellID, ["expires"] = cTime + cd, ["texture"] = SpellTextureByID[spellID], ["started"] = cTime };
				else
					if (cTime - SpellsPerPlayerGUID[unitGUID][spellID]["expires"] > 0) then
						SpellsPerPlayerGUID[unitGUID][spellID] = { ["spellID"] = spellID, ["expires"] = cTime + cd, ["texture"] = SpellTextureByID[spellID], ["started"] = cTime };
					end
				end
			end
		end
	end

	function addonTable.EnableTestMode()
		_charactersDB = addonTable.deepcopy(SpellsPerPlayerGUID);
		_spellCDs = addonTable.deepcopy(db.SpellCDs);
		for spellID in pairs(_spellIDs) do
			db.SpellCDs[spellID] = addonTable.GetDefaultDBEntryForSpell();
			db.SpellCDs[spellID].enabled = true;
		end
		db.SpellCDs[SPELL_PVPTRINKET] = addonTable.GetDefaultDBEntryForSpell();
		db.SpellCDs[SPELL_PVPTRINKET].enabled = true;
		db.SpellCDs[SPELL_PVPTRINKET].glow = GLOW_TIME_INFINITE;
		if (not TestFrame) then
			TestFrame = CreateFrame("frame");
			TestFrame:SetScript("OnEvent", function() addonTable.DisableTestMode(); end);
		end
		TestFrame:SetScript("OnUpdate", function(_, elapsed)
			_t = _t + elapsed;
			if (_t >= 2) then
				refreshCDs();
				_t = 0;
			end
		end);
		TestFrame:RegisterEvent("PLAYER_LOGOUT");
		refreshCDs(); 	-- // for instant start
		OnUpdate();		-- // for instant start
		addonTable.TestModeActive = true;
	end

	function addonTable.DisableTestMode()
		TestFrame:SetScript("OnUpdate", nil);
		TestFrame:UnregisterEvent("PLAYER_LOGOUT");
		SpellsPerPlayerGUID = addonTable.deepcopy(_charactersDB);
		db.SpellCDs = addonTable.deepcopy(_spellCDs);
		OnUpdate();		-- // for instant start
		addonTable.TestModeActive = false;
	end

end

-------------------------------------------------------------------------------------------------
----- Frame for events
-------------------------------------------------------------------------------------------------
do

	local COMBATLOG_OBJECT_REACTION_HOSTILE = COMBATLOG_OBJECT_REACTION_HOSTILE;
	local CombatLogGetCurrentEventInfo = CombatLogGetCurrentEventInfo;

	EventFrame = CreateFrame("Frame");
	EventFrame:RegisterEvent("PLAYER_ENTERING_WORLD");
	EventFrame:RegisterEvent("PVP_MATCH_ACTIVE");
	EventFrame:RegisterEvent("CHAT_MSG_ADDON");
	EventFrame:SetScript("OnEvent", function(self, event, ...) self[event](...); end);
	C_ChatInfo.RegisterAddonMessagePrefix("NC_prefix");

	EventFrame.COMBAT_LOG_EVENT_UNFILTERED = function()
		local cTime = GetTime();
		local _, eventType, _, srcGUID, _, srcFlags, _, _, _, _, _, spellID = CombatLogGetCurrentEventInfo();
		if (bit_band(srcFlags, COMBATLOG_OBJECT_REACTION_HOSTILE) ~= 0 or (db.ShowCDOnAllies == true and srcGUID ~= LocalPlayerGUID)) then
			local entry = db.SpellCDs[spellID];
			local cooldown = AllCooldowns[spellID];
			if (cooldown ~= nil and entry and entry.enabled) then
				if (eventType == "SPELL_CAST_SUCCESS" or eventType == "SPELL_AURA_APPLIED" or eventType == "SPELL_MISSED" or eventType == "SPELL_SUMMON") then
					if (not SpellsPerPlayerGUID[srcGUID]) then SpellsPerPlayerGUID[srcGUID] = { }; end
					local expires = cTime + cooldown;
					SpellsPerPlayerGUID[srcGUID][spellID] = { ["spellID"] = spellID, ["expires"] = expires, ["texture"] = SpellTextureByID[spellID], ["started"] = cTime };
					for frame, unitGUID in pairs(NameplatesVisible) do
						if (unitGUID == srcGUID) then
							UpdateOnlyOneNameplate(frame, unitGUID);
							break;
						end
					end
				end
			end
			-- reductions
			if (eventType == "SPELL_CAST_SUCCESS" and Reductions[spellID] ~= nil) then
				if (SpellsPerPlayerGUID[srcGUID]) then
					for _, sp in pairs(Reductions[spellID].spells) do
						if (SpellsPerPlayerGUID[srcGUID][sp] ~= nil) then
							SpellsPerPlayerGUID[srcGUID][sp].expires = SpellsPerPlayerGUID[srcGUID][sp].expires - Reductions[spellID].reduction;
						end
					end
					for frame, unitGUID in pairs(NameplatesVisible) do
						if (unitGUID == srcGUID) then
							UpdateOnlyOneNameplate(frame, unitGUID);
							break;
						end
					end
				end
			-- // pvptier 1/2 used, correcting cd of PvP trinket
			elseif (eventType == "SPELL_AURA_APPLIED" and spellID == SPELL_PVPADAPTATION and db.SpellCDs[SPELL_PVPTRINKET] ~= nil and db.SpellCDs[SPELL_PVPTRINKET].enabled) then
				if (SpellsPerPlayerGUID[srcGUID]) then
					SpellsPerPlayerGUID[srcGUID][SPELL_PVPTRINKET] = { ["spellID"] = SPELL_PVPTRINKET, ["expires"] = cTime + 60, ["texture"] = SpellTextureByID[SPELL_PVPTRINKET], ["started"] = cTime };
					for frame, unitGUID in pairs(NameplatesVisible) do
						if (unitGUID == srcGUID) then
							UpdateOnlyOneNameplate(frame, unitGUID);
							break;
						end
					end
				end
			-- caster is a healer, reducing cd of pvp trinket
			elseif (eventType == "SPELL_CAST_SUCCESS" and spellID == SPELL_PVPTRINKET and db.SpellCDs[SPELL_PVPTRINKET] ~= nil and db.SpellCDs[SPELL_PVPTRINKET].enabled and LHT.IsPlayerHealer(srcGUID)) then
				if (SpellsPerPlayerGUID[srcGUID]) then
					local existingEntry = SpellsPerPlayerGUID[srcGUID][SPELL_PVPTRINKET];
					if (existingEntry) then
						existingEntry.expires = existingEntry.expires - 30;
						for frame, unitGUID in pairs(NameplatesVisible) do
							if (unitGUID == srcGUID) then
								UpdateOnlyOneNameplate(frame, unitGUID);
								break;
							end
						end
					end
				end
			end
		end
	end

	EventFrame.UNIT_AURA = function(_unitID)
		local feignDeath = db.SpellCDs[HUNTER_FEIGN_DEATH];
		local cooldown = AllCooldowns[HUNTER_FEIGN_DEATH];
		if (cooldown ~= nil and feignDeath and feignDeath.enabled) then
			local unitIsFriend = (UnitReaction("player", _unitID) or 0) > 4; -- 4 = neutral
			local unitGUID = UnitGUID(_unitID);
			if (not unitIsFriend or (db.ShowCDOnAllies == true and unitGUID ~= LocalPlayerGUID)) then
				local feignDeathFound = false;
				for auraIndex = 1, 40 do
					local aura = C_UnitAuras_GetAuraDataByIndex(_unitID, auraIndex);
					if (aura == nil) then
						break;
					end
					local spellId = aura.spellId;
					if (spellId == HUNTER_FEIGN_DEATH) then
						feignDeathFound = true;
						break;
					end
				end
				if (FeignDeathGUIDs[unitGUID] and not feignDeathFound) then
					local cTime = GetTime();
					if (not SpellsPerPlayerGUID[unitGUID]) then SpellsPerPlayerGUID[unitGUID] = { }; end
					local expires = cTime + cooldown;
					SpellsPerPlayerGUID[unitGUID][HUNTER_FEIGN_DEATH] = { ["spellID"] = HUNTER_FEIGN_DEATH, ["expires"] = expires, ["texture"] = SpellTextureByID[HUNTER_FEIGN_DEATH], ["started"] = cTime };
					for frame, plateUnitGUID in pairs(NameplatesVisible) do
						if (unitGUID == plateUnitGUID) then
							UpdateOnlyOneNameplate(frame, unitGUID);
							break;
						end
					end
					FeignDeathGUIDs[unitGUID] = nil;
				elseif (not FeignDeathGUIDs[unitGUID] and feignDeathFound) then
					FeignDeathGUIDs[unitGUID] = true;
				end
			end
		end
	end

	EventFrame.PLAYER_ENTERING_WORLD = function()
		if (OnStartup) then
			OnStartup();
		end
		wipe(SpellsPerPlayerGUID);
	end

	EventFrame.NAME_PLATE_UNIT_ADDED = function(unitID)
		local nameplate = C_NamePlate_GetNamePlateForUnit(unitID);
		local unitGUID = UnitGUID(unitID);
		NameplatesVisible[nameplate] = unitGUID;
		if (not Nameplates[nameplate]) then
			nameplate.NCIcons = {};
			nameplate.NCIconsCount = 0;	-- // it's faster than #nameplate.NCIcons
			Nameplates[nameplate] = true;
		end
		if (nameplate.NCFrame ~= nil and unitGUID ~= LocalPlayerGUID) then
			nameplate.NCFrame:Show();
		end
		UpdateOnlyOneNameplate(nameplate, unitGUID);
	end

	EventFrame.NAME_PLATE_UNIT_REMOVED = function(unitID)
		local nameplate = C_NamePlate_GetNamePlateForUnit(unitID);
		NameplatesVisible[nameplate] = nil;
		if (nameplate.NCFrame ~= nil) then
			nameplate.NCFrame:Hide();
		end
	end

	EventFrame.PLAYER_TARGET_CHANGED = function()
		ReallocateAllIcons(true);
	end

	EventFrame.CHAT_MSG_ADDON = function(prefix, message, channel, sender)
		if (prefix == "NC_prefix") then
			if (string_find(message, "reporting")) then
				local _, toWhom = strsplit(":", message, 2);
				local myName = UnitName("player").."-"..string_gsub(GetRealmName(), " ", "");
				if (toWhom == myName and sender ~= myName) then
					addonTable.Print(sender.." is using NC");
				end
			elseif (string_find(message, "requesting")) then
				C_ChatInfo.SendAddonMessage("NC_prefix", "reporting:"..sender, channel);
			end
		end
	end

	EventFrame.PVP_MATCH_ACTIVE = function()
		wipe(SpellsPerPlayerGUID);
	end

	-- we do polling because 'GetInstanceInfo' works unstable
	local function UpdateZoneType()
		local newInstanceType;
		local _, instanceType, _, _, _, _, _, instanceID = GetInstanceInfo();
		if (instanceType == nil or instanceType == addonTable.INSTANCE_TYPE_NONE) then
			newInstanceType = instanceType;
		elseif (instanceType == "pvp") then
			if (addonTable.EPIC_BG_ZONE_IDS[instanceID]) then
				newInstanceType = addonTable.INSTANCE_TYPE_PVP_BG_40PPL;
			else
				newInstanceType = instanceType;
			end
		else
			newInstanceType = instanceType;
		end
		if (newInstanceType ~= InstanceType) then
			InstanceType = newInstanceType;
			ReallocateAllIcons(false);
		end
		CTimerAfter(2, UpdateZoneType);
	end
	CTimerAfter(2, UpdateZoneType);

	LHT.Subscribe(function(_guid, _)
		if (SpellsPerPlayerGUID[_guid]) then
			local existingEntry = SpellsPerPlayerGUID[_guid][SPELL_PVPTRINKET];
			if (existingEntry) then
				existingEntry.expires = existingEntry.expires - 30;
				for frame, unitGUID in pairs(NameplatesVisible) do
					if (unitGUID == _guid) then
						UpdateOnlyOneNameplate(frame, unitGUID);
						break;
					end
				end
			end
		end
	end);

end
