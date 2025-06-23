local _, RE = ...
local L = LibStub("AceLocale-3.0"):GetLocale("REFlex")
local ST = LibStub("ScrollingTable")
local GUI = LibStub("AceGUI-3.0")
local LDB = LibStub("LibDataBroker-1.1")
local LDBI = LibStub("LibDBIcon-1.0")
local QTIP = LibStub("LibQTip-1.0")
local DUMP = LibStub("LibTextDump-1.0")
REFlex = RE

local tinsert = table.insert
local PanelTemplates_GetSelectedTab, PanelTemplates_SetTab, PanelTemplates_SetNumTabs = PanelTemplates_GetSelectedTab, PanelTemplates_SetTab, PanelTemplates_SetNumTabs
local StaticPopup_Show = StaticPopup_Show
local IsAltKeyDown = IsAltKeyDown
local IsControlKeyDown = IsControlKeyDown
local IsShiftKeyDown = IsShiftKeyDown
local IsInInstance = IsInInstance
local IsInGuild = IsInGuild
local IsActiveBattlefieldArena = IsActiveBattlefieldArena
local IsInBrawl = C_PvP.IsInBrawl
local IsSoloShuffle = C_PvP.IsSoloShuffle
local IsRatedSoloShuffle = C_PvP.IsRatedSoloShuffle
local IsRatedArena = C_PvP.IsRatedArena
local IsRatedBattleground = C_PvP.IsRatedBattleground
local IsSoloRBG = C_PvP.IsSoloRBG
local IsArenaSkirmish = IsArenaSkirmish
local IsPlayerAtEffectiveMaxLevel = IsPlayerAtEffectiveMaxLevel
local SetBattlefieldScoreFaction = SetBattlefieldScoreFaction
local GetAvailableBrawlInfo = C_PvP.GetAvailableBrawlInfo
local GetBrawlRewards = C_PvP.GetBrawlRewards
local GetNumSpecializations = GetNumSpecializations
local GetSpecializationInfo = GetSpecializationInfo
local GetPersonalRatedInfo = GetPersonalRatedInfo
local GetBattlefieldWinner = GetBattlefieldWinner
local GetBattlefieldScore = GetBattlefieldScore
local GetBattlefieldTeamInfo = GetBattlefieldTeamInfo
local GetBattlefieldStatData = GetBattlefieldStatData
local GetBattlefieldArenaFaction = GetBattlefieldArenaFaction
local GetInstanceInfo = GetInstanceInfo
local GetRandomBGInfo = C_PvP.GetRandomBGInfo
local GetRandomEpicBGInfo = C_PvP.GetRandomEpicBGInfo
local GetNumBattlefieldScores = GetNumBattlefieldScores
local GetMatchPVPStatColumns = C_PvP.GetMatchPVPStatColumns
local GetActiveMatchDuration = C_PvP.GetActiveMatchDuration
local GetCurrentArenaSeason = GetCurrentArenaSeason
local GetCVar = GetCVar
local GetMouseFoci = GetMouseFoci
local GetAddOnMetadata = C_AddOns.GetAddOnMetadata
local UnitName = UnitName
local UnitFactionGroup = UnitFactionGroup
local UnitHonor = UnitHonor
local UnitHonorMax = UnitHonorMax
local RequestRatedInfo = RequestRatedInfo
local RequestPVPRewards = RequestPVPRewards
local RequestRandomBattlegroundInstanceInfo = RequestRandomBattlegroundInstanceInfo
local HasArenaSkirmishWinToday = C_PvP.HasArenaSkirmishWinToday
local TimerAfter = C_Timer.After
local AbbreviateNumbers = AbbreviateNumbers
local UIParentLoadAddOn = UIParentLoadAddOn
local RegisterAddonMessagePrefix = C_ChatInfo.RegisterAddonMessagePrefix
local SendAddonMessage = C_ChatInfo.SendAddonMessage
local PlaySound = PlaySound
local ElvUI = ElvUI

RE.Version = 3320
RE.LastSquash = 1602662400
RE.FoundNewVersion = false

RE.DataSaved = false
RE.Match = true
RE.PrepareGUI = true
RE.MatchData = {}
RE.BGData = {}
RE.ArenaData = {}
RE.RatingChange = {0, 0, 0, 0, 0, 0, 0}
RE.CalendarMode = 0
RE.HideID = 0
RE.Season = 0
RE.LDBTime = 0
RE.LDBA = ""
RE.LDBB = ""
RE.LDBUpdate = true
RE.LDBData = {["Won"] = 0, ["Lost"] = 0, ["HK"] = 0, ["Honor"] = 0}

RE.PlayerName = UnitName("PLAYER"):lower()
RE.PlayerFaction = UnitFactionGroup("PLAYER") == "Horde" and 0 or 1
RE.PlayerZone = GetCVar("portal")

RE.BackdropA = {
	edgeFile = "Interface\\DialogFrame\\UI-DialogBox-Border",
	bgFile = "Interface\\DialogFrame\\UI-DialogBox-Background",
	tile = true,
	tileSize = 32,
	edgeSize = 32,
	insets = { left = 5, right = 5, top = 5, bottom = 5 },
}
RE.BackdropB = {
	edgeFile = "Interface\\Tooltips\\UI-Tooltip-Border",
	tile = true,
	edgeSize = 16,
}

SLASH_REFLEX1 = "/reflex"
SLASH_REFLEXGG1 = "/gg"

function RE:OnLoad(self)
	RE.SessionStart, RE.PlayerTimezone = RE:GetUTCTimestamp(true)
	self:RegisterEvent("ADDON_LOADED")
	self:RegisterEvent("PLAYER_LOGIN")
	self:RegisterEvent("ZONE_CHANGED_NEW_AREA")
	self:RegisterEvent("PVP_MATCH_COMPLETE")
	self:RegisterEvent("CHAT_MSG_ADDON")
	self:RegisterEvent("PVP_RATED_STATS_UPDATE")
	self:RegisterEvent("CURRENCY_DISPLAY_UPDATE")
	self:RegisterForDrag("LeftButton")
	tinsert(UISpecialFrames,"REFlexFrame")

	REFlexFrameTab1:SetText(ALL)
	REFlexFrameTab2:SetText(GUILD_PLAYSTYLE_CASUAL)
	REFlexFrameTab3:SetText(PVP_TAB_CONQUEST)
	REFlexFrameTab4:SetText(ALL)
	REFlexFrameTab5:SetText(GUILD_PLAYSTYLE_CASUAL)
	REFlexFrameTab6:SetText(PVP_TAB_CONQUEST)

	REFlexFrame_Title:SetText("REFlex "..GetAddOnMetadata("REFlex", "version"))
	REFlexFrame_HKBar_I:SetStatusBarTexture("Interface\\TargetingFrame\\UI-StatusBar")
	REFlexFrame_HKBar_I:SetStatusBarColor(0, 0.9, 0)

	RE.TableBG = ST:CreateST(RE.BGStructure, 30, nil, nil, REFlexFrame)
	RE.TableBG.head:SetHeight(25)
	for _, i in pairs({1,3,5,7,9}) do
		local _, parent = RE.TableBG.frame["col"..i.."bg"]:GetPoint(1)
		RE.TableBG.frame["col"..i.."bg"]:SetPoint("TOPLEFT", parent, "BOTTOMLEFT", 0, -9)
		RE.TableBG.frame["col"..i.."bg"]:SetPoint("TOPRIGHT", parent, "BOTTOMRIGHT", 0, -9)
	end
	RE.TableBG.frame:ClearAllPoints()
	RE.TableBG.frame:SetPoint("TOP", REFlexFrame_ScoreHolder, "BOTTOM", 0, -15)
	RE.TableBG.frame:Hide()
	RE.TableBG:RegisterEvents({
		["OnClick"] = function (_, _, data, _, _, realRow, _, _, button, _)
			if realRow ~= nil and IsAltKeyDown() and IsControlKeyDown() and IsShiftKeyDown() and button == "LeftButton" then
				RE.HideID = data[realRow][11]
				StaticPopup_Show("REFLEX_CONFIRMDELETE")
			end
		end,
		["OnEnter"] = function (_, cellFrame, data, _, _, realRow, _)
			if realRow ~= nil and IsShiftKeyDown() then
				RE:OnEnterTooltip(cellFrame, data[realRow][11])
			end
		end,
		["OnLeave"] = function (_, _, _, _, _, realRow, _)
			if realRow ~= nil then
				RE:OnLeaveTooltip()
			end
		end,
	})
	RE.TableArena = ST:CreateST(RE.ArenaStructure, 18, 25, nil, REFlexFrame)
	RE.TableArena.frame:ClearAllPoints()
	RE.TableArena.frame:SetPoint("TOP", REFlexFrame_ScoreHolder, "BOTTOM", 0, -15)
	RE.TableArena.frame:Hide()
	RE.TableArena:RegisterEvents({
		["OnClick"] = function (_, _, data, _, _, realRow, _, _, button, _)
			if realRow ~= nil and IsAltKeyDown() and IsControlKeyDown() and IsShiftKeyDown() and button == "LeftButton" then
				RE.HideID = data[realRow][11]
				StaticPopup_Show("REFLEX_CONFIRMDELETE")
			end
		end,
		["OnEnter"] = function (_, cellFrame, data, _, _, realRow, _)
			if realRow ~= nil and IsShiftKeyDown() then
				RE:OnEnterTooltip(cellFrame, data[realRow][11])
			end
		end,
		["OnLeave"] = function (_, _, _, _, _, realRow, _)
			if realRow ~= nil then
				RE:OnLeaveTooltip()
			end
		end,
	})

	RE.SpecDropDown = GUI:Create("Dropdown")
	RE.SpecDropDown.frame:SetParent(REFlexFrame)
	RE.SpecDropDown.frame:SetPoint("BOTTOMLEFT", REFlexFrame, "BOTTOMLEFT", 15, 18)
	RE.SpecDropDown:SetWidth(150)
	RE.SpecDropDown:SetList({[ALL] = ALL})
	RE.SpecDropDown:SetCallback("OnValueChanged", RE.OnSpecChange)
	RE.BracketDropDown = GUI:Create("Dropdown")
	RE.BracketDropDown.frame:SetParent(REFlexFrame)
	RE.BracketDropDown.frame:SetPoint("LEFT", RE.SpecDropDown.frame, "RIGHT", 5, 0)
	RE.BracketDropDown:SetWidth(100)
	RE.BracketDropDown:SetCallback("OnValueChanged", RE.OnBracketChange)
	RE.BracketDropDown:SetList({[1] = ALL, [2] = SOLO, [4] = "2v2", [6] = "3v3"})
	RE.MapDropDown = GUI:Create("Dropdown")
	RE.MapDropDown.frame:SetParent(REFlexFrame)
	RE.MapDropDown.frame:SetPoint("BOTTOMRIGHT", REFlexFrame, "BOTTOMRIGHT", -19, 18)
	RE.MapDropDown:SetWidth(150)
	RE.MapDropDown:SetCallback("OnValueChanged", RE.OnMapChange)
	RE.DateDropDown = GUI:Create("Dropdown")
	RE.DateDropDown.frame:SetParent(REFlexFrame)
	RE.DateDropDown.frame:SetPoint("RIGHT", RE.MapDropDown.frame, "LEFT", -5, 0)
	RE.DateDropDown:SetWidth(100)
	RE.DateDropDown:SetCallback("OnValueChanged", RE.OnDateChange)
	RE.DateDropDown:SetList({[1] = ALL, [2] = L["Session"], [3] = HONOR_TODAY, [4] = HONOR_YESTERDAY, [5] = GUILD_CHALLENGES_THIS_WEEK, [6] = L["This month"], [7] = L["This season"], [8] = L["Prev. season"], [9] = CUSTOM})
end

function RE:OnHide(_)
	if RE.Tooltip and RE.Tooltip:IsVisible() then
		QTIP:Release(RE.Tooltip)
	end
	PlaySound(SOUNDKIT.IG_CHARACTER_INFO_CLOSE)
end

function RE:OnEvent(_, event, ...)
	if event == "ADDON_LOADED" and ... == "REFlex" then
		if not REFlexSettings then
			REFlexSettings = RE.DefaultConfig
		end
		if not REFlexDatabase then
			REFlexDatabase = {}
		end
		if not REFlexHonorDatabase then
			REFlexHonorDatabase = {}
			RE:UpdateHDatabase()
		end
		RE.Settings = REFlexSettings
		RE.Database = REFlexDatabase
		RE.HDatabase = REFlexHonorDatabase
		RE:UpdateSettings()
		RE:UpdateDatabase()
		RE:HiddenPurge()

		PanelTemplates_SetNumTabs(REFlexFrame, 6)
		PanelTemplates_SetTab(REFlexFrame, RE.Settings.CurrentTab)

		LibStub("AceConfigRegistry-3.0"):RegisterOptionsTable("REFlex", RE.AceConfig)
		RE.OptionsMenu = LibStub("AceConfigDialog-3.0"):AddToBlizOptions("REFlex", "REFlex")
		RegisterAddonMessagePrefix("REFlex")
		BINDING_NAME_REFLEXOPEN = L["Show main window"]
		SlashCmdList["REFLEX"] = function()
			if not REFlexFrame:IsVisible() then
				REFlexFrame:Show()
			else
				REFlexFrame:Hide()
			end
		end
		SlashCmdList["REFLEXGG"] = function()
			RE:SurrenderMatch()
		end

		RE.LDB = LDB:NewDataObject("REFlex", {
			type = "data source",
			text = "|cFF74D06CRE|rFlex",
			icon = "Interface\\PvPRankBadges\\PvPRank09"
		})
		function RE.LDB:OnEnter(frame)
			local brawlInfo = GetAvailableBrawlInfo()
			local mod = 0
			RE.Tooltip = QTIP:Acquire("REFlexTooltipLDB", 2, "LEFT", "LEFT")
			RE.Tooltip:SmartAnchorTo(frame or self)
			if ElvUI then
				local red, green, blue = unpack(ElvUI[1].media.backdropfadecolor)
				RE.Tooltip:SetBackdropColor(red, green, blue, ElvUI[1].Tooltip and ElvUI[1].Tooltip.db.colorAlpha or 1)
			end
			RE.Tooltip:AddHeader("", "")
			RE.Tooltip:SetCell(1, 1, "|cFFFFD100"..DAILY.."|r", RE.Tooltip:GetHeaderFont(), "CENTER", 2)
			RE.Tooltip:AddLine(BATTLEGROUND , GetRandomBGInfo().hasRandomWinToday and "|TInterface\\RaidFrame\\ReadyCheck-Ready:0|t" or "|TInterface\\RaidFrame\\ReadyCheck-NotReady:0|t")
			RE.Tooltip:AddLine(ITEM_QUALITY4_DESC.." "..BATTLEGROUND, GetRandomEpicBGInfo().hasRandomWinToday and "|TInterface\\RaidFrame\\ReadyCheck-Ready:0|t" or "|TInterface\\RaidFrame\\ReadyCheck-NotReady:0|t")
			RE.Tooltip:AddLine(ARENA_CASUAL, HasArenaSkirmishWinToday() and "|TInterface\\RaidFrame\\ReadyCheck-Ready:0|t" or "|TInterface\\RaidFrame\\ReadyCheck-NotReady:0|t")
			if IsPlayerAtEffectiveMaxLevel() and brawlInfo and brawlInfo.canQueue then
				RE.Tooltip:AddLine(LFG_CATEGORY_BATTLEFIELD, select(5, GetBrawlRewards(brawlInfo.brawlType)) and "|TInterface\\RaidFrame\\ReadyCheck-Ready:0|t" or "|TInterface\\RaidFrame\\ReadyCheck-NotReady:0|t")
			else
				mod = 1
			end
			RE.Tooltip:AddLine(PVP_RATED_SOLO_SHUFFLE, select(5, GetBrawlRewards(4)) and "|TInterface\\RaidFrame\\ReadyCheck-Ready:0|t" or "|TInterface\\RaidFrame\\ReadyCheck-NotReady:0|t")
			RE.Tooltip:AddSeparator()
			for _, i in pairs({7, 1, 2, 4}) do
				RE.Tooltip:AddLine(RE.BracketNames[i], select(9, GetPersonalRatedInfo(i)) and "|TInterface\\RaidFrame\\ReadyCheck-Ready:0|t" or "|TInterface\\RaidFrame\\ReadyCheck-NotReady:0|t")
			end
			RE.Tooltip:AddLine("", "")
			RE.Tooltip:AddHeader("", "")
			RE.Tooltip:SetCell(13 - mod, 1, "|cFFFFD100"..HONOR.."|r", RE.Tooltip:GetHeaderFont(), "CENTER", 2)
			RE.Tooltip:AddLine("", "")
			RE.Tooltip:SetCell(14 - mod, 1, UnitHonor("player").." / "..UnitHonorMax("player"), "CENTER", 2)
			if IsPlayerAtEffectiveMaxLevel() and GetCurrentArenaSeason() > 0 then
				local current, cap = RE:GetConquestPoints()
				local weeklyCurrent, weeklycap, weeklyProgress = RE:GetWeeklyChest()
				RE.Tooltip:AddHeader("", "")
				RE.Tooltip:SetCell(15 - mod, 1, "|cFFFFD100"..PVP_CONQUEST.."|r", RE.Tooltip:GetHeaderFont(), "CENTER", 2)
				RE.Tooltip:AddLine("", "")
				RE.Tooltip:SetCell(16 - mod, 1, current.." / "..cap, "CENTER", 2)
				RE.Tooltip:AddHeader("", "")
				RE.Tooltip:SetCell(17 - mod, 1, "|cFFFFD100"..RATED_PVP_WEEKLY_CHEST.."|r", RE.Tooltip:GetHeaderFont(), "CENTER", 2)
				RE.Tooltip:AddLine("", "")
				RE.Tooltip:SetCell(18 - mod, 1, weeklyCurrent.." / "..weeklycap, "CENTER", 2)
				RE.Tooltip:AddLine("", "")
				RE.Tooltip:SetCell(19 - mod, 1, weeklyProgress, "CENTER", 2)
			end
			RE.Tooltip:Show()
		end
		function RE.LDB:OnLeave()
			QTIP:Release(RE.Tooltip)
		end
		function RE.LDB:OnClick(button)
			local isMouseOverMinimapButton = false
			local mouseFoci = GetMouseFoci()

			for _, region in ipairs(mouseFoci) do
				if region:IsMouseMotionFocus() and region == LDBI:GetMinimapButton("REFlex") then
					isMouseOverMinimapButton = true
					break
				end
			end

			if REFlex_CompartmentClick or isMouseOverMinimapButton then
				if button == "LeftButton" then
					if not REFlexFrame:IsVisible() then
						REFlexFrame:Show()
					else
						REFlexFrame:Hide()
					end
				elseif button == "MiddleButton" then
					RE:SurrenderMatch()
				elseif button == "RightButton" then
					Settings.OpenToCategory("REFlex")
				end
			else
				if button == "LeftButton" then
					if RE.Settings.LDBSide == "A" then
						RE.Settings.LDBSide = "B"
					else
						RE.Settings.LDBSide = "A"
					end
					RE.LDB.text = RE["LDB"..RE.Settings.LDBSide]
				elseif button == "MiddleButton" then
					RE:SurrenderMatch()
				elseif button == "RightButton" then
					if not REFlexFrame:IsVisible() then
						REFlexFrame:Show()
					else
						REFlexFrame:Hide()
					end
				end
			end
			REFlex_CompartmentClick = false
		end
		LDBI:Register("REFlex", RE.LDB, RE.Settings.MiniMapButtonSettings)

		StaticPopupDialogs["REFLEX_FIRSTTIME"] = {
			text = L["Hold SHIFT to display tooltips."].."|n|n"..L["Hold SHIFT and ALT to display extended tooltips."].."|n"..L["They are available only for rated BGs."].."|n|n"..L["SHIFT + ALT + CTRL + CLICK will hide the match."],
			button1 = OKAY,
			OnAccept = function() RE.Settings.FirstTime = false end,
			timeout = 0,
			whileDead = true,
			hideOnEscape = false
		}
		StaticPopupDialogs["REFLEX_CUSTOMDATE"] = {
			text = L["Select start and end date by clicking it."],
			timeout = 0,
			whileDead = true,
			hideOnEscape = false
		}
		StaticPopupDialogs["REFLEX_CONFIRMDELETE"] = {
			text = L["Are you sure you want to hide this entry?"],
			button1 = YES,
			button2 = NO,
			OnAccept = function() RE:HideEntry(RE.HideID) end,
			timeout = 0,
			whileDead = true,
			hideOnEscape = true,
		}

		RE.DumpFrame = DUMP:New("REFlex - CSV")

		RE.IsSkinned = AddOnSkins and AddOnSkins[1]:CheckOption("REFlex") or false

		if RE.Settings.LDBMode == 1 then
			RE:GetSessionHonor()
		end

		RE:UpdateBGData(true)
		RE:UpdateArenaData(true)
	elseif event == "PLAYER_LOGIN" then
		RequestRatedInfo()
		RequestPVPRewards()
		RequestRandomBattlegroundInstanceInfo()
		GetAvailableBrawlInfo()
	elseif event == "ADDON_LOADED" and ... == "Blizzard_Calendar" then
		hooksecurefunc("CalendarDayButton_Click", RE.CalendarParser)
		CalendarFrame:HookScript("OnHide", RE.CalendarCleanup)
	elseif event == "CHAT_MSG_ADDON" and ... == "REFlex" then
		local _, message, _ = ...
		local messageEx = {strsplit(";", message)}
		if messageEx[1] == "Version" then
			if not RE.FoundNewVersion and tonumber(messageEx[2]) > RE.Version then
				print("\124cFF74D06C[REFlex]\124r "..L["New version released!"])
				RE.FoundNewVersion = true
			end
		end
	elseif event == "ZONE_CHANGED_NEW_AREA" then
		local _, instanceType = IsInInstance()
		RE.DataSaved = false
		if RE.Match then
			RE.Match = false
			RequestRatedInfo()
			RequestPVPRewards()
			RequestRandomBattlegroundInstanceInfo()
			GetAvailableBrawlInfo()
		end
		if instanceType == "pvp" or instanceType == "arena" then
			RE.Match = true
			SendAddonMessage("REFlex", "Version;"..RE.Version, "INSTANCE_CHAT")
			if IsInGuild() then
				SendAddonMessage("REFlex", "Version;"..RE.Version, "GUILD")
			end
			REFlexBGFrameText:SetText("")
		end
	elseif event == "PVP_MATCH_COMPLETE" and not RE.DataSaved then
		RE.DataSaved = true
		PVPMatchResults.buttonContainer.leaveButton:Disable()
		TimerAfter(1, RE.PVPEnd)
	elseif event == "PVP_RATED_STATS_UPDATE" then
		RE.Season = GetCurrentArenaSeason()
		for _, i in pairs({1, 2, 4, 7}) do
			local currentRating, _, _, _, _, _, _, bestRating = GetPersonalRatedInfo(i)
			RE.RatingChange[i] = currentRating - bestRating
		end
		if RE.LDBTime == 0 then
			RE:UpdateLDBTime()
		end
		RE.LDBUpdate = true
		RE:UpdateLDB()
	elseif event == "CURRENCY_DISPLAY_UPDATE" then
		local currency, _, quantity = ...
		if currency and quantity and currency == 1792 and quantity > 0 then
			RE:ParseHonor(quantity)
		end
	end
end

function RE:OnEnterTooltip(cellFrame, databaseID)
	if RE.Database[databaseID].isArena then
		if RE.Database[databaseID].isSoloShuffle then
			local team, damageSum, healingSum = RE:GetArenaTeamDetails(databaseID, true)
			RE.Tooltip = QTIP:Acquire("REFlexTooltip", 3, "CENTER", "CENTER", "CENTER")
			RE.Tooltip:AddLine()
			for i=1, 3 do
				RE.Tooltip:SetCell(1, i, "", nil, nil, nil, nil, nil, nil, nil, 80)
			end
			for i=1, 6 do
				if team[i][2] ~= "" then
					RE.Tooltip:AddLine(team[i][1], team[i][7].." "..team[i][2], team[i][3])
				end
			end
			RE.Tooltip:AddSeparator(3)
			RE.Tooltip:AddLine(nil, "|cFF74D06C"..DAMAGE.."|r", "|cFF74D06C"..SHOW_COMBAT_HEALING.."|r")
			for i=1, 6 do
				if team[i][2] ~= "" then
					RE.Tooltip:AddLine(team[i][2]..team[i][6], team[i][4], team[i][5])
				end
			end
			RE.Tooltip:AddSeparator(3)
			RE.Tooltip:AddLine(nil, "|cFFFF141D"..damageSum.."|r", "|cFF00ff00"..healingSum.."|r")
		else
			local team, damageSum, healingSum = RE:GetArenaTeamDetails(databaseID, true)
			local teamEnemy, damageSumEnemy, healingSumEnemy = RE:GetArenaTeamDetails(databaseID, false)
			RE.Tooltip = QTIP:Acquire("REFlexTooltip", 7, "CENTER", "CENTER", "CENTER", "CENTER", "CENTER", "CENTER", "CENTER")
			RE.Tooltip:AddLine()
			for i=1, 7 do
				if i == 4 then
					RE.Tooltip:SetCell(1, 4, "", nil, nil, nil, nil, nil, nil, nil, 50)
				else
					RE.Tooltip:SetCell(1, i, "", nil, nil, nil, nil, nil, nil, nil, 80)
				end
			end
			for i=1, 3 do
				if team[i][2] ~= "" or teamEnemy[i][2] ~= "" then
					RE.Tooltip:AddLine(team[i][1], team[i][7].." "..team[i][2], team[i][3], nil, teamEnemy[i][1], teamEnemy[i][7].." "..teamEnemy[i][2], teamEnemy[i][3])
				end
			end
			RE.Tooltip:AddSeparator(3)
			RE.Tooltip:AddLine(nil, "|cFF74D06C"..DAMAGE.."|r", "|cFF74D06C"..SHOW_COMBAT_HEALING.."|r", nil, nil, "|cFF74D06C"..DAMAGE.."|r", "|cFF74D06C"..SHOW_COMBAT_HEALING.."|r")
			for i=1, 3 do
				if team[i][2] ~= "" or teamEnemy[i][2] ~= "" then
					RE.Tooltip:AddLine(team[i][2]..team[i][6], team[i][4], team[i][5], nil, teamEnemy[i][2]..teamEnemy[i][6], teamEnemy[i][4], teamEnemy[i][5])
				end
			end
			RE.Tooltip:AddSeparator(3)
			RE.Tooltip:AddLine(nil, "|cFFFF141D"..damageSum.."|r", "|cFF00ff00"..healingSum.."|r", nil, nil, "|cFFFF141D"..damageSumEnemy.."|r", "|cFF00ff00"..healingSumEnemy.."|r")
		end
	else
		local playerData = RE:GetPlayerData(databaseID)
		local placeKB, placeHK, placeHonor, placeDamage, placeHealing = unpack(RE.Database[databaseID].BGPlace[2])
		local placeFKB, placeFHK, placeFHonor, placeFDamage, placeFHealing = unpack(RE.Database[databaseID].BGPlace[1])
		local mmrLine = nil
		RE.Tooltip = QTIP:Acquire("REFlexTooltip", 3, "CENTER", "CENTER", "CENTER")
		if RE.Database[databaseID].isRated then
			if RE.PlayerFaction == 0 then
				mmrLine = "|cFF74D06CMMR|r|n|cFFFF141D"..RE:GetMMR(databaseID, true).."|r|n|cFF00A9FF"..RE:GetMMR(databaseID, false).."|r"
			else
				mmrLine = "|cFF74D06CMMR|r|n|cFF00A9FF"..RE:GetMMR(databaseID, true).."|r|n|cFFFF141D"..RE:GetMMR(databaseID, false).."|r"
			end
		end
		RE.Tooltip:AddLine()
		RE.Tooltip:SetCell(1, 1, "|cFF74D06CHK/D|r|n"..RE:GetPlayerKD(databaseID), nil, nil, nil, nil, nil, nil, nil, 50)
		RE.Tooltip:SetCell(1, 2, mmrLine, nil, nil, nil, nil, nil, nil, nil, 50)
		RE.Tooltip:SetCell(1, 3, "|cFF74D06C"..DEATHS.."|r|n"..playerData[4], nil, nil, nil, nil, nil, nil, nil, 50)
		RE.Tooltip:AddSeparator(3)
		RE.Tooltip:AddLine(nil, "|cFF74D06C"..L["Place"].."|r", nil)
		RE.Tooltip:SetColumnLayout(3, "LEFT", "CENTER", "CENTER")
		RE.Tooltip:AddLine(nil, FACTION, ALL)
		RE.Tooltip:AddLine("KB", placeFKB, placeKB)
		RE.Tooltip:AddLine("HK", placeFHK, placeHK)
		RE.Tooltip:AddLine(HONOR, placeFHonor, placeHonor)
		RE.Tooltip:AddLine(DAMAGE, placeFDamage, placeDamage)
		RE.Tooltip:AddLine(SHOW_COMBAT_HEALING, placeFHealing, placeHealing)
		RE.Tooltip:SetLineColor(5, 1, 1, 1, 0.5)
		RE.Tooltip:SetLineColor(7, 1, 1, 1, 0.5)
		RE.Tooltip:SetLineColor(9, 1, 1, 1, 0.5)
		RE.Tooltip:SetColumnLayout(3, "CENTER", "CENTER", "CENTER")
		RE.Tooltip:AddSeparator(3)
		local tank, healer, dps = unpack(RE.Database[databaseID].BGComposition[1])
		local tankE, healerE, dpsE = unpack(RE.Database[databaseID].BGComposition[2])
		RE.Tooltip:AddLine("|TInterface\\LFGFrame\\UI-LFG-ICON-PORTRAITROLES:16:16:0:0:64:64:0:19:22:41|t", "|TInterface\\LFGFrame\\UI-LFG-ICON-PORTRAITROLES:16:16:0:0:64:64:20:39:1:20|t", "|TInterface\\LFGFrame\\UI-LFG-ICON-PORTRAITROLES:16:16:0:0:64:64:20:39:22:41|t")
		if RE.PlayerFaction == 0 then
			RE.Tooltip:AddLine("|cFFFF141D"..tank.."|r - |cFF00A9FF"..tankE.."|r", "|cFFFF141D"..healer.."|r - |cFF00A9FF"..healerE.."|r", "|cFFFF141D"..dps.."|r - |cFF00A9FF"..dpsE.."|r")
		else
			RE.Tooltip:AddLine("|cFF00A9FF"..tank.."|r - |cFFFF141D"..tankE.."|r", "|cFF00A9FF"..healer.."|r - |cFFFF141D"..healerE.."|r", "|cFF00A9FF"..dps.."|r - |cFFFF141D"..dpsE.."|r")
		end
		if RE.Database[databaseID].PlayerStats then
			local statsNum = #RE.Database[databaseID].PlayerStats
			if statsNum > 0 then
				RE.Tooltip:AddSeparator(3)
				local faction = ""
				local playerStatsData = RE.Database[databaseID].PlayerStats
				if RE.MapListStat[RE.Database[databaseID].Map][1] or statsNum == 3 then
					faction = tostring(RE.PlayerFaction)
				end
				if statsNum == 1 then
					RE.Tooltip:AddLine(nil, "|T"..RE.MapListStat[RE.Database[databaseID].Map][2]..faction..":16:16:0:0|t: "..playerStatsData[1], nil)
				elseif statsNum == 3 then
					RE.Tooltip:AddLine("|T"..RE.MapListStat[567][2]..faction..":16:16:0:0|t: "..playerStatsData[1], "|T"..RE.MapListStat[567][3]..faction..":16:16:0:0|t: "..playerStatsData[2], "|T"..RE.MapListStat[567][4]..":16:16:0:0|t: "..playerStatsData[3])
				else
					RE.Tooltip:AddLine("|T"..RE.MapListStat[RE.Database[databaseID].Map][2]..faction..":16:16:0:0|t: "..playerStatsData[1], nil, "|T"..RE.MapListStat[RE.Database[databaseID].Map][3]..faction..":16:16:0:0|t: "..playerStatsData[2])
					if statsNum > 2 then
						RE.Tooltip:AddLine("|T"..RE.MapListStat[RE.Database[databaseID].Map][4]..faction..":16:16:0:0|t: "..playerStatsData[3], nil, "|T"..RE.MapListStat[RE.Database[databaseID].Map][5]..faction..":16:16:0:0|t: "..playerStatsData[4])
					end
				end
			end
		end
		if IsAltKeyDown() and RE.Database[databaseID].isRated then
			local team, damageSum, healingSum, kbSum = RE:GetRGBTeamDetails(databaseID, true)
			RE.TooltipRGB1 = QTIP:Acquire("REFlexTooltipRGB1", 7, "CENTER", "CENTER", "CENTER", "CENTER", "CENTER", "CENTER", "CENTER")
			RE.TooltipRGB1:AddLine()
			for i=1, 7 do
				if i == 2 then
					RE.TooltipRGB1:SetCell(1, 2, "", nil, nil, nil, nil, nil, nil, nil, 10)
				elseif i == 5 then
					RE.TooltipRGB1:SetCell(1, 5, "", nil, nil, nil, nil, nil, nil, nil, 40)
				else
					RE.TooltipRGB1:SetCell(1, i, "", nil, nil, nil, nil, nil, nil, nil, 80)
				end
			end
			RE.TooltipRGB1:AddLine(nil, nil, nil, nil, "|cFF74D06CKB|r", "|cFF74D06C"..DAMAGE.."|r", "|cFF74D06C"..SHOW_COMBAT_HEALING.."|r")
			for i=1, #team do
				RE.TooltipRGB1:AddLine(team[i][1], team[i][4], team[i][2]..team[i][8], team[i][3], team[i][5], team[i][6], team[i][7])
			end
			RE.TooltipRGB1:AddSeparator(3)
			RE.TooltipRGB1:AddLine(nil, nil, nil, nil, "|cff00ccff"..kbSum.."|r", "|cFFFF141D"..damageSum.."|r", "|cFF00ff00"..healingSum.."|r")
			RE.TooltipRGB1:ClearAllPoints()
			RE.TooltipRGB1:SetClampedToScreen(true)
			RE.TooltipRGB1:SetPoint("RIGHT", RE.Tooltip, "LEFT", -5, 0)
			if ElvUI then
				local red, green, blue = unpack(ElvUI[1].media.backdropfadecolor)
				RE.TooltipRGB1:SetBackdropColor(red, green, blue, ElvUI[1].Tooltip and ElvUI[1].Tooltip.db.colorAlpha or 1)
			end
			RE.TooltipRGB1:Show()
			team, damageSum, healingSum, kbSum = RE:GetRGBTeamDetails(databaseID, false)
			RE.TooltipRGB2 = QTIP:Acquire("REFlexTooltipRGB2", 7, "CENTER", "CENTER", "CENTER", "CENTER", "CENTER", "CENTER", "CENTER")
			RE.TooltipRGB2:AddLine()
			for i=1, 7 do
				if i == 2 then
					RE.TooltipRGB2:SetCell(1, 2, "", nil, nil, nil, nil, nil, nil, nil, 10)
				elseif i == 5 then
					RE.TooltipRGB2:SetCell(1, 5, "", nil, nil, nil, nil, nil, nil, nil, 40)
				else
					RE.TooltipRGB2:SetCell(1, i, "", nil, nil, nil, nil, nil, nil, nil, 80)
				end
			end
			RE.TooltipRGB2:AddLine(nil, nil, nil, nil, "|cFF74D06CKB|r", "|cFF74D06C"..DAMAGE.."|r", "|cFF74D06C"..SHOW_COMBAT_HEALING.."|r")
			for i=1, #team do
				RE.TooltipRGB2:AddLine(team[i][1], team[i][4], team[i][2]..team[i][8], team[i][3], team[i][5], team[i][6], team[i][7])
			end
			RE.TooltipRGB2:AddSeparator(3)
			RE.TooltipRGB2:AddLine(nil, nil, nil, nil, "|cff00ccff"..kbSum.."|r", "|cFFFF141D"..damageSum.."|r", "|cFF00ff00"..healingSum.."|r")
			RE.TooltipRGB2:ClearAllPoints()
			RE.TooltipRGB2:SetClampedToScreen(true)
			RE.TooltipRGB2:SetPoint("LEFT", RE.Tooltip, "RIGHT", 5, 0)
			if ElvUI then
				local red, green, blue = unpack(ElvUI[1].media.backdropfadecolor)
				RE.TooltipRGB2:SetBackdropColor(red, green, blue, ElvUI[1].Tooltip and ElvUI[1].Tooltip.db.colorAlpha or 1)
			end
			RE.TooltipRGB2:Show()
		end
	end
	if ElvUI then
		local red, green, blue = unpack(ElvUI[1].media.backdropfadecolor)
		RE.Tooltip:SetBackdropColor(red, green, blue, ElvUI[1].Tooltip and ElvUI[1].Tooltip.db.colorAlpha or 1)
	end
	RE.Tooltip:SmartAnchorTo(cellFrame)
	RE.Tooltip:Show()
end

function RE:OnLeaveTooltip()
	QTIP:Release(RE.Tooltip)
	QTIP:Release(RE.TooltipRGB1)
	QTIP:Release(RE.TooltipRGB2)
end

function RE:OnSpecChange(_, spec)
	RE.Settings.Filters.Spec = spec
	RE:UpdateGUI()
end

function RE:OnMapChange(_, map)
	RE.Settings.Filters.Map = map
	RE:UpdateGUI()
end

function RE:OnBracketChange(_, bracket)
	RE.Settings.Filters.Bracket = bracket
	RE:UpdateGUI()
end

function RE:OnArenaStatsClick(self)
	if RE.Tooltip and RE.Tooltip:IsVisible() then
		QTIP:Release(RE.Tooltip)
	else
		CloseDropDownMenus()
	end
end

function RE:OnDateChange(_, mode, internal)
	RE.Settings.Filters.DateMode = mode
	RE.Settings.Filters.Season = 0
	if mode == 1 then
		RE.Settings.Filters.Date = {0, 0}
	elseif mode == 2 then
		RE.Settings.Filters.Date = {RE.SessionStart, 0}
	elseif mode == 3 then
		RE.Settings.Filters.Date = {RE:ParseUTCTimestamp(), 0}
	elseif mode == 4 then
		RE.Settings.Filters.Date = {RE:ParseUTCTimestamp() - 86400, RE:ParseUTCTimestamp()}
	elseif mode == 5 then
		RE.Settings.Filters.Date = {RE:GetUTCTimestamp() - RE:GetPreviousWeeklyReset() + (RE.PlayerTimezone * 3600), 0}
	elseif mode == 6 then
		RE.Settings.Filters.Date = {RE:ParseUTCTimestamp(true), 0}
	elseif mode == 7 then
		RE.Settings.Filters.Date = {0, 0}
		RE.Settings.Filters.Season = RE.Season
	elseif mode == 8 then
		RE.Settings.Filters.Date = {0, 0}
		RE.Settings.Filters.Season = RE.Season - 1
	else
		RE.CalendarMode = 1
		StaticPopup_Show("REFLEX_CUSTOMDATE")
		UIParentLoadAddOn("Blizzard_Calendar")
		CalendarFrame:Show()
		return
	end
	if internal == nil then
		RE:UpdateGUI()
	end
end

function RE:UpdateGUI()
	if RE.Settings.FirstTime then
		StaticPopup_Show("REFLEX_FIRSTTIME")
	end
	if RE.PrepareGUI then
		RequestRatedInfo()
		RequestPVPRewards()
		RequestRandomBattlegroundInstanceInfo()
		GetAvailableBrawlInfo()
		for i=1, GetNumSpecializations() do
			local Spec = select(2, GetSpecializationInfo(i))
			RE.SpecDropDown:AddItem(Spec, Spec)
		end
		RE.SpecDropDown:SetValue(RE.Settings.Filters.Spec)
		RE.BracketDropDown:SetValue(RE.Settings.Filters.Bracket)
		RE.DateDropDown:SetValue(RE.Settings.Filters.DateMode)
		if RE.Settings.Filters.DateMode < 9 then
			RE:OnDateChange(_, RE.Settings.Filters.DateMode, true)
		end

		REFlexFrameTab6:ClearAllPoints()
		REFlexFrameTab5:ClearAllPoints()
		REFlexFrameTab4:ClearAllPoints()
		REFlexFrameTab6:SetPoint("CENTER", REFlexFrame, "BOTTOMRIGHT", -40, -10)
		REFlexFrameTab5:SetPoint("RIGHT", REFlexFrameTab6, "LEFT", -3, 0)
		REFlexFrameTab4:SetPoint("RIGHT", REFlexFrameTab5, "LEFT", -3, 0)

		MenuUtil.CreateButtonMenu(REFlexFrame_StatsButton,
			{L["Most common teams"], function() RE:GetArenaStatsTooltip(1) end, 1},
			{L["Easiest teams"], function() RE:GetArenaStatsTooltip(2) end, 2},
			{L["Hardest teams"], function() RE:GetArenaStatsTooltip(3) end, 3}
		)
	end
	if PanelTemplates_GetSelectedTab(REFlexFrame) < 4 then
		RE.TableBG:Show()
		RE.TableArena:Hide()
		RE.BracketDropDown:SetDisabled(true)
		REFlexFrame_StatsButton:Hide()
		if RE.Settings.CurrentTab > 3 or RE.PrepareGUI then
			RE.MapDropDown:SetList(RE.MapListLongBG, RE.MapListLongOrderBG)
			if RE.PrepareGUI then
				RE.PrepareGUI = false
				RE.MapDropDown:SetValue(RE.Settings.Filters.Map)
			else
				RE.MapDropDown:SetValue(1)
				RE.Settings.Filters.Map = 1
			end
		end
		if #RE.TableBG.data == 0 then
			RE.TableBG.cols[1].sort = ST.SORT_ASC
		end
		RE.TableBG:SetData(RE.BGData, true)
		if PanelTemplates_GetSelectedTab(REFlexFrame) == 1 then
			RE.TableBG:SetFilter(RE.FilterDefault)
			REFlexFrame_ScoreHolder_RBG:SetText("|cFFFFD100"..RATING..":|r "..select(1, GetPersonalRatedInfo(4)))
		elseif PanelTemplates_GetSelectedTab(REFlexFrame) == 2 then
			RE.TableBG:SetFilter(RE.FilterCasual)
			REFlexFrame_ScoreHolder_RBG:SetText("")
		elseif PanelTemplates_GetSelectedTab(REFlexFrame) == 3 then
			RE.TableBG:SetFilter(RE.FilterRated)
			REFlexFrame_ScoreHolder_RBG:SetText("|cFFFFD100"..RATING..":|r "..select(1, GetPersonalRatedInfo(4)))
		end
		local won, lost = RE:GetWinNumber(PanelTemplates_GetSelectedTab(REFlexFrame), false)
		local kb, topKB, hk, topHK, _, _, damage, topDamage, healing, topHealing = RE:GetStats(PanelTemplates_GetSelectedTab(REFlexFrame), false, false)
		REFlexFrame_ScoreHolder_HK1:SetText("|cFFFFD100HK|r")
		REFlexFrame_ScoreHolder_KB1:SetText("|cFFFFD100KB|r")
		REFlexFrame_ScoreHolder_Damage1:SetText("|cFFFFD100"..DAMAGE.."|r")
		REFlexFrame_ScoreHolder_Healing1:SetText("|cFFFFD100"..SHOW_COMBAT_HEALING.."|r")
		REFlexFrame_ScoreHolder_Wins:SetText(won)
		REFlexFrame_ScoreHolder_Lose:SetText(lost)
		REFlexFrame_ScoreHolder_HK2:SetText(BEST..": "..topHK)
		REFlexFrame_ScoreHolder_HK3:SetText(TOTAL..": "..hk)
		REFlexFrame_ScoreHolder_KB2:SetText(BEST..": "..topKB)
		REFlexFrame_ScoreHolder_KB3:SetText(TOTAL..": "..kb)
		REFlexFrame_ScoreHolder_Damage2:SetText(BEST..": "..RE:AbbreviateNumbers(topDamage))
		REFlexFrame_ScoreHolder_Damage3:SetText(TOTAL..": "..RE:AbbreviateNumbers(damage))
		REFlexFrame_ScoreHolder_Healing2:SetText(BEST..": "..RE:AbbreviateNumbers(topHealing))
		REFlexFrame_ScoreHolder_Healing3:SetText(TOTAL..": "..RE:AbbreviateNumbers(healing))
		RE.TableBG:Hide()
		RE.TableBG:Show()
	elseif PanelTemplates_GetSelectedTab(REFlexFrame) > 3 then
		RE.TableArena:Show()
		RE.TableBG:Hide()
		RE.BracketDropDown:SetDisabled(false)
		REFlexFrame_StatsButton:Show()
		if RE.Settings.CurrentTab < 4 or RE.PrepareGUI then
			RE.MapDropDown:SetList(RE.MapListLongArena, RE.MapListLongOrderArena)
			if RE.PrepareGUI then
				RE.PrepareGUI = false
				RE.MapDropDown:SetValue(RE.Settings.Filters.Map)
			else
				RE.MapDropDown:SetValue(1)
				RE.Settings.Filters.Map = 1
			end
		end
		if #RE.TableArena.data == 0 then
			RE.TableArena.cols[1].sort = ST.SORT_ASC
		end
		RE.TableArena:SetData(RE.ArenaData, true)
		if PanelTemplates_GetSelectedTab(REFlexFrame) == 4 then
			RE.TableArena:SetFilter(RE.FilterDefault)
			REFlexFrame_ScoreHolder_RBG:SetText("|cFFFFD100"..RATING..":|r "..select(1, GetPersonalRatedInfo(7)).." |cFFFFD100/|r "..select(1, GetPersonalRatedInfo(1)).." |cFFFFD100/|r "..select(1, GetPersonalRatedInfo(2)))
		elseif PanelTemplates_GetSelectedTab(REFlexFrame) == 5 then
			RE.TableArena:SetFilter(RE.FilterCasual)
			REFlexFrame_ScoreHolder_RBG:SetText("")
		elseif PanelTemplates_GetSelectedTab(REFlexFrame) == 6 then
			RE.TableArena:SetFilter(RE.FilterRated)
			REFlexFrame_ScoreHolder_RBG:SetText("|cFFFFD100"..RATING..":|r "..select(1, GetPersonalRatedInfo(7)).." |cFFFFD100/|r "..select(1, GetPersonalRatedInfo(1)).." |cFFFFD100/|r "..select(1, GetPersonalRatedInfo(2)))
		end
		local won, lost = RE:GetWinNumber(PanelTemplates_GetSelectedTab(REFlexFrame) - 3, true)
		local _, _, _, _, _, _, damage, topDamage, healing, topHealing = RE:GetStats(PanelTemplates_GetSelectedTab(REFlexFrame) - 3, true, false)
		REFlexFrame_ScoreHolder_HK1:SetText("|cFFFFD100"..SHOW_COMBAT_HEALING.."|r")
		REFlexFrame_ScoreHolder_KB1:SetText("|cFFFFD100"..DAMAGE.."|r")
		REFlexFrame_ScoreHolder_Damage1:SetText("")
		REFlexFrame_ScoreHolder_Healing1:SetText("")
		REFlexFrame_ScoreHolder_Wins:SetText(won)
		REFlexFrame_ScoreHolder_Lose:SetText(lost)
		REFlexFrame_ScoreHolder_HK2:SetText(BEST..": "..RE:AbbreviateNumbers(topHealing))
		REFlexFrame_ScoreHolder_HK3:SetText(TOTAL..": "..RE:AbbreviateNumbers(healing))
		REFlexFrame_ScoreHolder_KB2:SetText(BEST..": "..RE:AbbreviateNumbers(topDamage))
		REFlexFrame_ScoreHolder_KB3:SetText(TOTAL..": "..RE:AbbreviateNumbers(damage))
		REFlexFrame_ScoreHolder_Damage2:SetText("")
		REFlexFrame_ScoreHolder_Damage3:SetText("")
		REFlexFrame_ScoreHolder_Healing2:SetText("")
		REFlexFrame_ScoreHolder_Healing3:SetText("")
		RE.TableArena:Hide()
		RE.TableArena:Show()
	end
	RE:HKBarUpdate()
	RE.Settings.CurrentTab = PanelTemplates_GetSelectedTab(REFlexFrame)
end

function RE:UpdateBGData(all)
	local ili
	if all then
		ili = 1
	else
		ili = #RE.Database
	end
	for i=ili, #RE.Database do
		if not RE.Database[i].isArena and not RE.Database[i].Hidden then
			local playeData = RE:GetPlayerData(i)
			local tempData = {RE:DateClean(RE.Database[i].Time),
			RE:GetMapName(RE.Database[i].Map),
			RE:TimeClean(RE.Database[i].Duration, RE.Database[i].isSoloShuffle),
			RE:GetPlayerWin(i, true),
			playeData[2],
			playeData[3],
			RE:AbbreviateNumbers(playeData[10]),
			RE:AbbreviateNumbers(playeData[11]),
			playeData[5],
			RE:RatingChangeClean(playeData[13], i),
			i,
			playeData[10],
			playeData[11],
			playeData[16],
			playeData[13]}
			tinsert(RE.BGData, tempData)
		end
	end
end

function RE:UpdateArenaData(all)
	local ili
	if all then
		ili = 1
	else
		ili = #RE.Database
	end
	for i=ili, #RE.Database do
		if RE.Database[i].isArena and not RE.Database[i].Hidden then
			local playeData = RE:GetPlayerData(i)
			local tempData = {RE:DateClean(RE.Database[i].Time),
			RE:GetMapName(RE.Database[i].Map),
			RE:GetArenaTeamIcons(i, true),
			RE:GetMMR(i, true),
			RE:GetArenaTeamIcons(i, false),
			RE:GetMMR(i, false),
			RE:TimeClean(RE.Database[i].Duration, RE.Database[i].isSoloShuffle),
			RE:AbbreviateNumbers(playeData[10]),
			RE:AbbreviateNumbers(playeData[11]),
			RE:RatingChangeClean(playeData[13], i),
			i,
			playeData[10],
			playeData[11],
			playeData[16],
			playeData[13]}
			tinsert(RE.ArenaData, tempData)
		end
	end
end

function RE:UpdateConfig()
	if RE.Settings.MiniMapButtonSettings.hide then
		LDBI:Hide("REFlex")
	else
		LDBI:Show("REFlex")
	end
end

function RE:UpdateLDBTime()
	RE.LDBTime = RE.SessionStart
	if RE.Settings.LDBMode == 1 and not RE.SessionHonor then
		RE:GetSessionHonor()
	elseif RE.Settings.LDBMode == 2 then
		RE.LDBTime = RE:ParseUTCTimestamp()
	elseif RE.Settings.LDBMode == 3 then
		RE.LDBTime = RE:GetUTCTimestamp() - RE:GetPreviousWeeklyReset() + (RE.PlayerTimezone * 3600)
	end
end

function RE:UpdateLDB()
	local savedFilters = RE.Settings.Filters
	RE.Settings.Filters = {["Spec"] = ALL, ["Map"] = 1, ["Bracket"] = 1, ["Date"] = {RE.LDBTime, 0}, ["Season"] = 0}
	if RE.LDBUpdate then
		RE.LDBUpdate = false
		RE.LDBData.HK = select(3, RE:GetStats(1, nil, false))
		RE.LDBData.Won, RE.LDBData.Lost = RE:GetWinNumber(1, nil)
	end
	RE.LDBData.Honor = RE:GetHonor()
	if RE.Settings.LDBMode == 1 then
		RE.LDBData.Honor = RE.LDBData.Honor - RE.SessionHonor
	end
	RE.Settings.Filters = savedFilters

	RE.LDBA = "|cFF00FF00"..RE.LDBData.Won.."|r|cFF9D9D9D-|r|cFFFF141C"..RE.LDBData.Lost.."|r |cFF9D9D9D|||r |cFFCC9900"..AbbreviateNumbers(RE.LDBData.Honor).."|r |cFF9D9D9D|||r "..AbbreviateNumbers(RE.LDBData.HK)
	RE.LDBB = RE:RatingChangeClean(RE.RatingChange[7], false).." |cFF9D9D9D|||r "..RE:RatingChangeClean(RE.RatingChange[1], false).." |cFF9D9D9D|||r "..RE:RatingChangeClean(RE.RatingChange[2], false).." |cFF9D9D9D|||r "..RE:RatingChangeClean(RE.RatingChange[4], false)

	RE.LDB.text = RE["LDB"..RE.Settings.LDBSide]
end

function RE:PVPEnd()
	RE.MatchData = {}
	SetBattlefieldScoreFaction(-1)

	local StatsNum = #GetMatchPVPStatColumns()
	RE.MatchData.Map = select(8, GetInstanceInfo())
	RE.MatchData.Winner = GetBattlefieldWinner()
	RE.MatchData.PlayerSide = GetBattlefieldArenaFaction()
	RE.MatchData.isArena = IsActiveBattlefieldArena()
	RE.MatchData.Season = GetCurrentArenaSeason()
	RE.MatchData.PlayersNum = GetNumBattlefieldScores()
	RE.MatchData.Duration = GetActiveMatchDuration()
	RE.MatchData.Time = RE:GetUTCTimestamp()
	RE.MatchData.isBrawl = IsInBrawl()
	RE.MatchData.isSoloShuffle = IsSoloShuffle()
	RE.MatchData.Version = RE.Version

	if RE.MapIDRemap[RE.MatchData.Map] then
		RE.MatchData.Map = RE.MapIDRemap[RE.MatchData.Map]
	end

	if IsRatedBattleground() or IsSoloRBG() or (IsRatedArena() and not IsArenaSkirmish() and not RE.MatchData.isSoloShuffle) or IsRatedSoloShuffle() then
		RE.MatchData.isRated = true
	else
		RE.MatchData.isRated = false
	end

	RE.MatchData.Players = {}
	for i=1, RE.MatchData.PlayersNum do
		local data = {GetBattlefieldScore(i)}
		if data[1]:lower() == RE.PlayerName then
			RE.MatchData.PlayerNum = i
		end
		tinsert(RE.MatchData.Players, data)
	end

	if RE.MatchData.isRated then
		RE.MatchData.TeamData = {}
		RE.MatchData.TeamData[1] = {GetBattlefieldTeamInfo(0)}
		RE.MatchData.TeamData[2] = {GetBattlefieldTeamInfo(1)}
	end

	if StatsNum > 0 then
		RE.MatchData.PlayerStats = {}
		for j=1, StatsNum do
			tinsert(RE.MatchData.PlayerStats, GetBattlefieldStatData(RE.MatchData.PlayerNum, j))
		end
	end

	if not RE.MatchData.isArena then
		RE.MatchData.BGPlace = {}
		tinsert(RE.MatchData.BGPlace, {RE:GetBGPlace(RE.MatchData, true)})
		tinsert(RE.MatchData.BGPlace, {RE:GetBGPlace(RE.MatchData, false)})
		RE.MatchData.BGComposition = {}
		tinsert(RE.MatchData.BGComposition, {RE:GetBGComposition(RE.MatchData, true)})
		tinsert(RE.MatchData.BGComposition, {RE:GetBGComposition(RE.MatchData, false)})

		if not RE.MatchData.isRated and RE.MatchData.PlayerNum then
			RE.MatchData.Players = {RE.MatchData.Players[RE.MatchData.PlayerNum]}
			RE.MatchData.PlayerNum = 1
		end
	end

	-- Hide corrupted records
	if not RE.MatchData.PlayerNum or RE.MatchData.Map == 1170 or RE.MatchData.Map == 2177 or (RE.MatchData.isArena and RE.MatchData.isBrawl and not RE.MatchData.isSoloShuffle) then
		RE.MatchData.Hidden = true
	else
		RE.MatchData.Hidden = false
	end

	tinsert(RE.Database, RE.MatchData)
	if not RE.MatchData.Hidden then
		if RE.MatchData.isArena then
			RE:UpdateArenaData(false)
			REFlexBGFrameText:SetText("")
		else
			RE:UpdateBGData(false)
			REFlexBGFrameText:SetText(RE:GetBGScoreText(#RE.Database))
		end
	else
		print("\124cFF74D06C[REFlex]\124r "..L["API returned corrupted data. Match will not be recorded."])
	end
	PVPMatchResults.buttonContainer.leaveButton:Enable()
end
