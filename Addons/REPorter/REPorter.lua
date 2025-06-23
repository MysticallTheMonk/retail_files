local _, RE = ...
local L = LibStub("AceLocale-3.0"):GetLocale("REPorter")
local LBS = LibStub("LibBabble-SubZone-3.0"):GetReverseLookupTable()
local TIMER = LibStub("AceTimer-3.0")
REPorter = RE

local CreateFrame = CreateFrame
local CreateFramePool = CreateFramePool
local IsInInstance = IsInInstance
local IsInGuild = IsInGuild
local IsShiftKeyDown = IsShiftKeyDown
local IsAltKeyDown = IsAltKeyDown
local IsControlKeyDown = IsControlKeyDown
local IsInBrawl = C_PvP.IsInBrawl
local IsBrawlSoloRBG = C_PvP.IsBrawlSoloRBG
local IsRatedBattleground = C_PvP.IsRatedBattleground
local GetTime = GetTime
local GetBattlefieldInstanceRunTime = GetBattlefieldInstanceRunTime
local GetMapInfo = C_Map.GetMapInfo
local GetMapArtLayerTextures = C_Map.GetMapArtLayerTextures
local GetBestMapForUnit = C_Map.GetBestMapForUnit
local GetAreaPOIForMap = C_AreaPoiInfo.GetAreaPOIForMap
local GetAreaPOIInfo = C_AreaPoiInfo.GetAreaPOIInfo
local GetPOITextureCoords = C_Minimap.GetPOITextureCoords
local GetVignettes = C_VignetteInfo.GetVignettes
local GetVignetteInfo = C_VignetteInfo.GetVignetteInfo
local GetVignettePosition = C_VignetteInfo.GetVignettePosition
local GetNumBattlefieldFlagPositions = GetNumBattlefieldFlagPositions
local GetBattlefieldFlagPosition = C_PvP.GetBattlefieldFlagPosition
local GetNumBattlefieldVehicles = GetNumBattlefieldVehicles
local GetBattlefieldVehicleInfo = C_PvP.GetBattlefieldVehicleInfo
local GetSubZoneText = GetSubZoneText
local GetClassColor = GetClassColor
local GetRaidTargetIndex = GetRaidTargetIndex
local GetDoubleStatusBarWidgetVisualizationInfo = C_UIWidgetManager.GetDoubleStatusBarWidgetVisualizationInfo
local UnitName = UnitName
local UnitClass = UnitClass
local UnitExists = UnitExists
local UnitIsUnit = UnitIsUnit
local UnitAffectingCombat = UnitAffectingCombat
local UnitHealth = UnitHealth
local UnitHealthMax = UnitHealthMax
local UnitIsDeadOrGhost = UnitIsDeadOrGhost
local UnitGroupRolesAssigned = UnitGroupRolesAssigned
local SendChatMessage = SendChatMessage
local SendAddonMessage = C_ChatInfo.SendAddonMessage
local CombatLogGetCurrentEventInfo = CombatLogGetCurrentEventInfo
local RegisterAddonMessagePrefix = C_ChatInfo.RegisterAddonMessagePrefix
local Contains = tContains

local AV = 91
local WG = 1339
local AB = 1366
local EOTS = 112
local IOC = 169
local TP = 206
local BFG = 275
local EOTSR = 397
local TOK = 417
local SM = 423
local DG = 1576
local TMVS = 623
local ABW = 837
local ABJ = 1383
local SS = 907
local BFW = 1334
local CI = 1335
local ASH = 1478
local KR = 1537
local DR = 2345

RE.POIIconSize = 30
RE.POINumber = 40
RE.MapUpdateRate = 0.1
RE.LastMap = 0
RE.CurrentMap = -1
RE.NeedRefresh = false
RE.UpdateInProgress = false
RE.BGVehicles = {}
RE.BGVehicleInfo = {}
RE.POINodes = {}
RE.POIInfo = {}
RE.POIList = {}
RE.VignetteInfo = {}
RE.VignettePosition = {}
RE.PinTextures = {}
RE.ClickedPOI = ""

RE.DefaultTimer = 60
RE.CareAboutNodes = false
RE.CareAboutPoints = false
RE.CareAboutGates = false
RE.CareAboutFlags = false
RE.CareAboutVehicles = false
RE.PlayedFromStart = true
RE.IoCAllianceGateName = ""
RE.IoCHordeGateName = ""
RE.IoCGateHealth = 2400000
RE.IoCGateEstimator = {}
RE.IoCGateEstimatorText = ""
RE.SMEstimatorText = ""
RE.SMEstimatorReport = ""
RE.EstimatorTicks = {10000, 10000}
RE.EstimatorData = {0, 0, 0, 0, -1}
RE.IsWinning = ""
RE.IsBrawl = false
RE.IsRated = false
RE.IsOverlay = false

RE.BlipOffsetT = 0.5
RE.BlinkPOIMin = 0.3
RE.BlinkPOIMax = 0.6
RE.BlinkPOIValue = 0.3
RE.BlinkPOIUp = true

RE.FoundNewVersion = false
RE.AddonVersionCheck = 21009
RE.ScreenHeight, RE.ScreenWidth = UIParent:GetCenter()

RE.MapSettings = {
	[AB] = {["PlayerNumber"] = 15, ["WidgetID"] = 1671},
	[WG] = {["PlayerNumber"] = 10},
	[AV] = {["PlayerNumber"] = 40, ["NodeTimer"] = 240},
	[EOTS] = {["PlayerNumber"] = 15, ["WidgetID"] = 1671},
	[IOC] = {["PlayerNumber"] = 40},
	[BFG] = {["PlayerNumber"] = 10, ["WidgetID"] = 1671},
	[TP] = {["PlayerNumber"] = 10},
	[TOK] = {["PlayerNumber"] = 10},
	[SM] = {["PlayerNumber"] = 10, ["WidgetID"] = 1687},
	[DG] = {["PlayerNumber"] = 15, ["WidgetID"] = 2074},
	[TMVS] = {["PlayerNumber"] = 40},
	[SS] = {["PlayerNumber"] = 10, ["NodeTimer"] = 40},
	[BFW] = {["PlayerNumber"] = 40},
	[CI] = {["PlayerNumber"] = 10},
	[ASH] = {["PlayerNumber"] = 40},
	[DR] = {["PlayerNumber"] = 10, ["WidgetID"] = 1687}
}
RE.ZonesWithoutSubZones = {
	[SM] = true,
	[TOK] = true,
	[TMVS] = true,
	[CI] = true,
	[DR] = true
}
RE.POICaptureStatus = {
	[4] = FACTION_ALLIANCE, -- Graveyard
	[9] = FACTION_ALLIANCE, -- Tower/Keep
	[12] = FACTION_HORDE, -- Tower/Keep
	[14] = FACTION_HORDE, -- Graveyard
	[17] = FACTION_ALLIANCE, -- Mine/Quarry
	[19] = FACTION_HORDE, -- Mine/Quarry
	[22] = FACTION_ALLIANCE, -- Lumbermill
	[24] = FACTION_HORDE, -- Lumbermill
	[27] = FACTION_ALLIANCE, -- Waterworks/Blacksmith
	[29] = FACTION_HORDE, -- Waterworks/Blacksmith
	[32] = FACTION_ALLIANCE, -- Farm
	[34] = FACTION_HORDE, -- Farm
	[37] = FACTION_ALLIANCE, -- Stables
	[39] = FACTION_HORDE, -- Stables
	[137] = FACTION_ALLIANCE, -- Workshop
	[139] = FACTION_HORDE, -- Workshop
	[142] = FACTION_ALLIANCE, -- Air
	[144] = FACTION_HORDE, -- Air
	[147] = FACTION_ALLIANCE, -- Dock
	[149] = FACTION_HORDE, -- Dock
	[152] = FACTION_ALLIANCE, -- Oil
	[154] = FACTION_HORDE, -- Oil
	[208] = FACTION_ALLIANCE, -- Market
	[209] = FACTION_HORDE, -- Market
	[213] = FACTION_ALLIANCE, -- Ruins
	[214] = FACTION_HORDE, -- Ruins
	[218] = FACTION_ALLIANCE, -- Shrine
	[219] = FACTION_HORDE, -- Shrine
	[1001] = "" -- Azerite Node
}
RE.AzeriteNodes = {
	[0.391] = {[0.750] = L["Overlook"]},
	[0.286] = {[0.769] = L["Crash Site"]},
	[0.599] = {[0.358] = L["Tide Pools"], [0.553] = L["Shipwreck"]},
	[0.252] = {[0.423] = L["Ruins"]},
	[0.253] = {[0.427] = L["Ruins"]},
	[0.290] = {[0.556] = L["Waterfall"]},
	[0.450] = {[0.577] = L["Ridge"]},
	[0.527] = {[0.401] = L["Bonfire"]},
	[0.471] = {[0.283] = L["Tar Pits"]},
	[0.572] = {[0.263] = L["Temple"]},
	[0.386] = {[0.433] = L["Plunge"]},
	[0.349] = {[0.252] = L["Tower"]}
}
RE.AtlasNameToTextureIndex = {
	["eots_capPts-neutralIcon1-state1"] = 6,
	["eots_capPts-neutralIcon2-state1"] = 6,
	["eots_capPts-neutralIcon3-state1"] = 6,
	["eots_capPts-neutralIcon4-state1"] = 6,
	["eots_capPts-neutralIcon5-state1"] = 6,
	["eots_capPts-leftIcon1-state1"] = 9,
	["eots_capPts-leftIcon1-state2"] = 11,
	["eots_capPts-leftIcon2-state1"] = 9,
	["eots_capPts-leftIcon2-state2"] = 11,
	["eots_capPts-leftIcon3-state1"] = 9,
	["eots_capPts-leftIcon3-state2"] = 11,
	["eots_capPts-leftIcon4-state1"] = 9,
	["eots_capPts-leftIcon4-state2"] = 11,
	["eots_capPts-leftIcon5-state1"] = 9,
	["eots_capPts-leftIcon5-state2"] = 11,
	["eots_capPts-rightIcon1-state1"] = 12,
	["eots_capPts-rightIcon1-state2"] = 10,
	["eots_capPts-rightIcon2-state1"] = 12,
	["eots_capPts-rightIcon2-state2"] = 10,
	["eots_capPts-rightIcon3-state1"] = 12,
	["eots_capPts-rightIcon3-state2"] = 10,
	["eots_capPts-rightIcon4-state1"] = 12,
	["eots_capPts-rightIcon4-state2"] = 10,
	["eots_capPts-rightIcon5-state1"] = 12,
	["eots_capPts-rightIcon5-state2"] = 10,
	["orbs-leftIcon1-state1"] = 45,
	["orbs-leftIcon2-state1"] = 45,
	["orbs-leftIcon3-state1"] = 45,
	["orbs-leftIcon4-state1"] = 45,
	["orbs-rightIcon1-state1"] = 45,
	["orbs-rightIcon2-state1"] = 45,
	["orbs-rightIcon3-state1"] = 45,
	["orbs-rightIcon4-state1"] = 45
}
RE.BFWWalls = {86, 87, 88, 89, 90, 91, 95, 96, 97, 98, 99, 100}

RE.BackdropA = {
	edgeFile = "Interface\\FriendsFrame\\UI-Toast-Border",
	edgeSize = 12,
}
RE.BackdropB = {
	bgFile = "Interface\\TutorialFrame\\TutorialFrameBackground",
	tile = true,
	tileSize = 32,
}
RE.BackdropC = {
	edgeFile = "Interface\\FriendsFrame\\UI-Toast-Border",
	bgFile = "Interface\\TutorialFrame\\TutorialFrameBackground",
	tile = true,
	tileSize = 32,
	edgeSize = 12,
	insets = { left = 5, right = 5, top = 5, bottom = 5 },
}

RE.DefaultConfig = {
	profile = {
		BarHandle = 11,
		BarX = RE.ScreenHeight,
		BarY = RE.ScreenWidth,
		Locked = false,
		Opacity = 0.75,
		HideMinimap = false,
		DisplayMarks = false,
		DisplayHealers = false,
		UseRaidWarnings = false,
		Map = {
			[AB] = {["wx"] = RE.ScreenHeight, ["wy"] = RE.ScreenWidth, ["ww"] = 325, ["wh"] = 325, ["mx"] = 16, ["my"] = -77, ["ms"] = 1},
			[WG] = {["wx"] = RE.ScreenHeight, ["wy"] = RE.ScreenWidth, ["ww"] = 280, ["wh"] = 460, ["mx"] = -5, ["my"] = -38, ["ms"] = 1},
			[AV] = {["wx"] = RE.ScreenHeight, ["wy"] = RE.ScreenWidth, ["ww"] = 185, ["wh"] = 450, ["mx"] = 32, ["my"] = -36, ["ms"] = 1},
			[EOTS] = {["wx"] = RE.ScreenHeight, ["wy"] = RE.ScreenWidth, ["ww"] = 220, ["wh"] = 360, ["mx"] = 23, ["my"] = -41, ["ms"] = 1},
			[IOC] = {["wx"] = RE.ScreenHeight, ["wy"] = RE.ScreenWidth, ["ww"] = 290, ["wh"] = 375, ["mx"] = 13, ["my"] = -23, ["ms"] = 1},
			[BFG] = {["wx"] = RE.ScreenHeight, ["wy"] = RE.ScreenWidth, ["ww"] = 340, ["wh"] = 370, ["mx"] = 6, ["my"] = -28, ["ms"] = 1},
			[TP] = {["wx"] = RE.ScreenHeight, ["wy"] = RE.ScreenWidth, ["ww"] = 245, ["wh"] = 460, ["mx"] = 1, ["my"] = -33, ["ms"] = 1},
			[TOK] = {["wx"] = RE.ScreenHeight, ["wy"] = RE.ScreenWidth, ["ww"] = 390, ["wh"] = 250, ["mx"] = 19, ["my"] = -21, ["ms"] = 1},
			[SM] = {["wx"] = RE.ScreenHeight, ["wy"] = RE.ScreenWidth, ["ww"] = 460, ["wh"] = 350, ["mx"] = 7, ["my"] = -43, ["ms"] = 1},
			[DG] = {["wx"] = RE.ScreenHeight, ["wy"] = RE.ScreenWidth, ["ww"] = 555, ["wh"] = 470, ["mx"] = -15, ["my"] = -35, ["ms"] = 1},
			[TMVS] = {["wx"] = RE.ScreenHeight, ["wy"] = RE.ScreenWidth, ["ww"] = 220, ["wh"] = 370, ["mx"] = -2, ["my"] = -22, ["ms"] = 1},
			[SS] = {["wx"] = RE.ScreenHeight, ["wy"] = RE.ScreenWidth, ["ww"] = 360, ["wh"] = 385, ["mx"] = 66, ["my"] = -63, ["ms"] = 1},
			[BFW] = {["wx"] = RE.ScreenHeight, ["wy"] = RE.ScreenWidth, ["ww"] = 500, ["wh"] = 320, ["mx"] = -3, ["my"] = -84, ["ms"] = 1},
			[CI] = {["wx"] = RE.ScreenHeight, ["wy"] = RE.ScreenWidth, ["ww"] = 270, ["wh"] = 305, ["mx"] = -30, ["my"] = 55, ["ms"] = 1},
			[ASH] = {["wx"] = RE.ScreenHeight, ["wy"] = RE.ScreenWidth, ["ww"] = 270, ["wh"] = 330, ["mx"] = 15, ["my"] = -40, ["ms"] = 1},
			[DR] = {["wx"] = RE.ScreenHeight, ["wy"] = RE.ScreenWidth, ["ww"] = 270, ["wh"] = 330, ["mx"] = 15, ["my"] = -40, ["ms"] = 1}
		}
	}
}
RE.ReportBarAnchor = {
	[1] = {"BOTTOMLEFT", "BOTTOMRIGHT"},
	[2] = {"LEFT", "RIGHT"},
	[3] = {"TOPLEFT", "TOPRIGHT"},
	[4] = {"BOTTOMRIGHT", "BOTTOMLEFT"},
	[5] = {"RIGHT", "LEFT"},
	[6] = {"TOPRIGHT", "TOPLEFT"},
	[7] = {"BOTTOMLEFT", "TOPLEFT"},
	[8] = {"BOTTOM", "TOP"},
	[9] = {"BOTTOMRIGHT", "TOPRIGHT"},
	[10] = {"TOPLEFT", "BOTTOMLEFT"},
	[11] = {"TOP", "BOTTOM"},
	[12] = {"TOPRIGHT", "BOTTOMRIGHT"}
}
RE.AceConfig = {
	type = "group",
	args = {
		Options = {
			type = "group",
			name = OPTIONS,
			args = {
				Locked = {
					name = L["Lock map"],
					desc = L["When checked map and report bar is locked in place."],
					type = "toggle",
					width = "full",
					order = 1,
					set = function(_, val) RE.Settings.profile.Locked = val; RE:UpdateConfig() end,
					get = function(_) return RE.Settings.profile.Locked end
				},
				Description = {
					type = "description",
					name = L["When the lock is disabled map can be moved by dragging.\nDragging + SHIFT will move map inside the frame.\nMap frame can be resized by using holder at the bottom right corner.\nScroll wheel control map zoom."],
					order = 2,
				},
				HideMinimap = {
					name = L["Hide minimap on battlegrounds"],
					desc = L["When checked minimap will be hidden when a player is on the battleground."],
					type = "toggle",
					width = "full",
					order = 3,
					set = function(_, val) RE.Settings.profile.HideMinimap = val; RE:UpdateConfig() end,
					get = function(_) return RE.Settings.profile.HideMinimap end
				},
				DisplayMarks = {
					name = L["Always display raid markers"],
					desc = L["When checked player pins will be always replaced with raid markers."],
					type = "toggle",
					width = "full",
					order = 4,
					set = function(_, val) RE.Settings.profile.DisplayMarks = val; RE:UpdateConfig() end,
					get = function(_) return RE.Settings.profile.DisplayMarks end
				},
				DisplayHealers = {
					name = L["Always highlight the healers"],
					desc = L["When checked healers will always be highlighted."],
					type = "toggle",
					width = "full",
					order = 5,
					set = function(_, val) RE.Settings.profile.DisplayHealers = val; RE:UpdateConfig() end,
					get = function(_) return RE.Settings.profile.DisplayHealers end
				},
				UseRaidWarnings = {
					name = L["Use raid warnings"],
					desc = L["When checked alerts will also be sent as raid warnings."],
					type = "toggle",
					width = "full",
					order = 6,
					set = function(_, val) RE.Settings.profile.UseRaidWarnings = val; RE:UpdateConfig() end,
					get = function(_) return RE.Settings.profile.UseRaidWarnings end
				},
				BarHandle = {
					name = L["Report bar location"],
					desc = L["Anchor point of a bar with quick report buttons."],
					type = "select",
					width = "double",
					order = 7,
					values = {
						[1] = L["Right bottom"],
						[2] = L["Right"],
						[3] = L["Right top"],
						[4] = L["Left bottom"],
						[5] = L["Left"],
						[6] = L["Left top"],
						[7] = L["Top left"],
						[8] = L["Top"],
						[9] = L["Top right"],
						[10] = L["Bottom left"],
						[11] = L["Bottom"],
						[12] = L["Bottom right"],
						[13] = L["Standalone - Horizontal"],
						[14] = L["Standalone - Vertical"],
						[15] = L["Hidden"]
					},
					set = function(_, val) RE.Settings.profile.BarHandle = val; RE.Settings.profile.BarX, RE.Settings.profile.BarY = REPorterBar:GetCenter(); RE:UpdateConfig() end,
					get = function(_) return RE.Settings.profile.BarHandle end
				},
				MapSettings = {
					name = BATTLEGROUND,
					desc = L["Map position is saved separately for each battleground."],
					type = "select",
					width = "double",
					order = 8,
					disabled = function(_) if select(2, IsInInstance()) == "pvp" then return true else return false end end,
					values = {
						[AB] = GetMapInfo(AB).name,
						[WG] = GetMapInfo(WG).name,
						[AV] = GetMapInfo(AV).name,
						[EOTS] = GetMapInfo(EOTS).name,
						[IOC] = GetMapInfo(IOC).name,
						[BFG] = GetMapInfo(BFG).name,
						[TP] = GetMapInfo(TP).name,
						[SM] = GetMapInfo(SM).name,
						[TOK] = GetMapInfo(TOK).name,
						[DG] = GetMapInfo(DG).name,
						[TMVS] = GetMapInfo(TMVS).name,
						[SS] = GetMapInfo(SS).name,
						[BFW] = GetMapInfo(BFW).name,
						[CI] = GetMapInfo(CI).name,
						[ASH] = GetMapInfo(ASH).name,
						[DR] = GetMapInfo(DR).name
					},
					set = function(_, val) RE.LastMap = val; RE:ShowDummyMap(val) end,
					get = function(_) return RE.LastMap end
				},
				Scale = {
					name = L["Map scale"],
					desc = L["This option control map size."],
					type = "range",
					width = "double",
					order = 9,
					min = 0.5,
					max = 1.5,
					step = 0.05,
					set = function(_, val) RE:UpdateScaleConfig(_, val) end,
					get = function(_) return RE:UpdateScaleConfig() end
				},
				Opacity = {
					name = L["Map alpha"],
					desc = L["This option control map transparency."],
					type = "range",
					width = "double",
					order = 10,
					isPercent = true,
					min = 0.1,
					max = 1,
					step = 0.01,
					set = function(_, val) RE.Settings.profile.Opacity = val; RE:UpdateConfig() end,
					get = function(_) return RE.Settings.profile.Opacity end
				},
			}
		}
	}
}

-- *** Auxiliary functions
function RE:BlinkPOI()
	if RE.BlinkPOIValue + 0.03 <= RE.BlinkPOIMax and RE.BlinkPOIUp then
		RE.BlinkPOIValue = RE.BlinkPOIValue + 0.03
	else
		if RE.BlinkPOIUp then
			RE.BlinkPOIUp = false
			RE.BlinkPOIValue = RE.BlinkPOIValue - 0.03
		elseif RE.BlinkPOIValue - 0.03 <= RE.BlinkPOIMin then
			RE.BlinkPOIUp = true
			RE.BlinkPOIValue = RE.BlinkPOIValue - 0.03
		else
			RE.BlinkPOIValue = RE.BlinkPOIValue - 0.03
		end
	end
end

function RE:ShortTime(TimeRaw)
	local TimeSec = floor(TimeRaw % 60)
	local TimeMin = floor(TimeRaw / 60)
	if TimeSec < 10 then
        ---@diagnostic disable-next-line: cast-local-type
		TimeSec = "0" .. TimeSec
	end
	return TimeMin .. ":" .. TimeSec
end

function RE:Round(num, idp)
	local mult = 10^(idp or 0)
	return floor(num * mult + 0.5) / mult
end

function RE:GetRealCoords(rawX, rawY)
	-- X -17 Y -78
	return rawX * 783, -rawY * 522
end

function RE:CheckCoordinates(x1, y1, x2, y2)
	x1 = floor(x1)
	y1 = floor(y1)
	return (x1 == x2 or x1 == x2 + 1 or x1 == x2 - 1) and (y1 == y2 or y1 == y2 + 1 or y1 == y2 - 1)
end

function RE:FramesOverlap(frameA, frameB)
	local sA, sB = frameA:GetEffectiveScale(), frameB:GetEffectiveScale()
	return (frameA:GetLeft() * sA) < (frameB:GetRight() * sB)
	and (frameB:GetLeft() * sB) < (frameA:GetRight() * sA)
	and (frameA:GetBottom() * sA) < (frameB:GetTop() * sB)
	and (frameB:GetBottom() * sB) < (frameA:GetTop() * sA)
end

function RE:POIDropDown(root)
	local submenu = root:CreateButton(L["Incoming"])
	submenu:CreateButton("1", function() RE:SmallButton(1, true) end)
	submenu:CreateButton("2", function() RE:SmallButton(2, true) end)
	submenu:CreateButton("3", function() RE:SmallButton(3, true) end)
	submenu:CreateButton("4", function() RE:SmallButton(4, true) end)
	submenu:CreateButton("5", function() RE:SmallButton(5, true) end)
	submenu:CreateButton("5+", function() RE:SmallButton(6, true) end)
    root:CreateButton(HELP_LABEL, function() RE:BigButton(true, true) end)
	root:CreateButton(L["Clear"], function() RE:BigButton(false, true) end)
	root:CreateDivider()
	root:CreateButton(ATTACK, function() RE:ReportDropDownClick("Attack") end)
	root:CreateButton(L["Guard"], function() RE:ReportDropDownClick("Guard") end)
	root:CreateButton(L["Heavily defended"], function() RE:ReportDropDownClick("Heavily defended") end)
	root:CreateButton(L["Losing"], function() RE:ReportDropDownClick("Losing") end)
	root:CreateDivider()
	root:CreateButton(L["On my way"], function() RE:ReportDropDownClick("On my way") end)
	root:CreateButton(L["Report status"], function() RE:ReportDropDownClick("") end)
end

function RE:CreatePOI(index)
	local frameMain = CreateFrame("Frame", "REPorterFrameCorePOI"..index, REPorterFrameCorePOI)
	frameMain:SetFrameLevel(10)
	frameMain:SetWidth(RE.POIIconSize)
	frameMain:SetHeight(RE.POIIconSize)
	frameMain:SetScript("OnEnter", function(self) RE:UnitOnEnterPOI(self) end)
	frameMain:SetScript("OnLeave", function() GameTooltip:Hide() end)
	frameMain:SetScript("OnMouseDown", function(self) RE:OnClickPOI(self) end)
	local texture = frameMain:CreateTexture(frameMain:GetName().."Texture", "BORDER")
	texture:SetPoint("CENTER", frameMain, "CENTER")
	texture:SetWidth(RE.POIIconSize - 13)
	texture:SetHeight(RE.POIIconSize - 13)
	texture:SetTexture("Interface\\Minimap\\POIIcons")
	texture = frameMain:CreateTexture(frameMain:GetName().."TextureBG", "BACKGROUND")
	texture:SetPoint("TOPLEFT", frameMain, "TOPLEFT")
	texture:SetPoint("BOTTOMLEFT", frameMain, "BOTTOMLEFT")
	texture:SetWidth(RE.POIIconSize)
	texture:SetColorTexture(0,0,0,0.3)
	texture = frameMain:CreateTexture(frameMain:GetName().."TextureBGofBG", "BACKGROUND")
	texture:SetPoint("TOPRIGHT", frameMain, "TOPRIGHT")
	texture:SetPoint("BOTTOMRIGHT", frameMain, "BOTTOMRIGHT")
	texture:SetWidth(RE.POIIconSize)
	texture:SetColorTexture(0,0,0,0.3)
	texture:Hide()
	texture = frameMain:CreateTexture(frameMain:GetName().."TextureBGTop1", "BORDER")
	texture:SetPoint("TOPLEFT", frameMain, "TOPLEFT")
	texture:SetWidth(RE.POIIconSize)
	texture:SetHeight(2)
	texture:SetColorTexture(0,1,0,1)
	texture = frameMain:CreateTexture(frameMain:GetName().."TextureBGTop2", "BORDER")
	texture:SetPoint("BOTTOMLEFT", frameMain, "BOTTOMLEFT")
	texture:SetWidth(RE.POIIconSize)
	texture:SetHeight(2)
	texture:SetColorTexture(0,1,0,1)
	local frame = CreateFrame("Frame", "REPorterFrameCorePOI"..index.."Timer", REPorterFrameCorePOITimers, "REPorterPOITimerTemplate")
	frame:SetFrameLevel(11)
	frame:SetPoint("CENTER", frameMain, "CENTER")
end

function RE:TimerJoinCheck()
	RE.IsBrawl = IsInBrawl()
	RE.IsRated = IsRatedBattleground()

	if IsBrawlSoloRBG() then
		RE:LoadMapSettings()
		RE.DefaultTimer = 30
	elseif RE.MapSettings[RE.CurrentMap].NodeTimer then
		RE.DefaultTimer = RE.MapSettings[RE.CurrentMap].NodeTimer
	else
		RE.DefaultTimer = 60
	end

	if RE.CurrentMap ~= -1 and GetBattlefieldInstanceRunTime() / 1000 > 120 then
		RE.PlayedFromStart = false
		RE:OnPOIUpdate()
	end
end

function RE:TimerNull()
	-- And Now His Watch is Ended
end
--

-- *** Event functions
function RE:OnLoad(self)
	self:RegisterEvent("ADDON_LOADED")
	self:RegisterEvent("PLAYER_ENTERING_WORLD")
	self:RegisterEvent("ZONE_CHANGED_NEW_AREA")
	self:RegisterEvent("CHAT_MSG_ADDON")
	self:RegisterEvent("MODIFIER_STATE_CHANGED")
	self:RegisterEvent("GROUP_ROSTER_UPDATE")
	RE.FlagsPool = CreateFramePool("FRAME", REPorterFrameCore, "REPorterFlagTemplate")
end

function RE:OnEnterBar(_)
	TIMER:CancelTimer(RE.TimerBar)
	REPorterBar:SetAlpha(RE.Settings.profile.Opacity)
end

function RE:OnLeaveBar(_)
	if not REPorterBar:IsMouseOver() then
		TIMER:CancelTimer(RE.TimerBar)
		RE.TimerBar = TIMER:ScheduleTimer(function() REPorterBar:SetAlpha(0.25) end, 0.5)
	end
end

function RE:OnLeave(_)
	TIMER:CancelTimer(RE.TimerDropDown)
	RE.TimerDropDown = TIMER:ScheduleTimer(function() CloseDropDownMenus() end, 3)
end

function RE:OnDragStart(_)
	REPorterFrameCore:ClearAllPoints()
	REPorterFrameCore:SetPoint("CENTER", REPorterFrameCoreAnchor, "CENTER")
	if IsShiftKeyDown() then
		REPorterFrameCoreAnchor:StartMoving()
	else
		local x1, y1 = REPorterFrameClip:GetCenter()
		local x2, y2 = REPorterFrameCoreAnchor:GetCenter()
		REPorterFrameCoreAnchor:ClearAllPoints()
		REPorterFrameCoreAnchor:SetPoint("CENTER", REPorterFrameClip, "CENTER", x2-x1, y2-y1)
		REPorterFrame:StartMoving()
	end
end

function RE:OnDragStop(_)
	REPorterFrameCore:ClearAllPoints()
	REPorterFrameCore:SetPoint("CENTER", REPorterFrameCoreAnchor, "CENTER")
	if not RE:FramesOverlap(REPorterFrameClip, REPorterFrameCore) then
		REPorterFrameCoreAnchor:ClearAllPoints()
		REPorterFrameCoreAnchor:SetPoint("CENTER", REPorterFrameClip, "CENTER", 9, -39)
	end
end

function RE:OnMouseWheel(delta)
	local newscale = REPorterFrameCore:GetScale() + (delta * 0.05)
	if newscale > 1.5 then
		newscale = 1.5
	elseif newscale < 0.5 then
		newscale = 0.5
	end
	newscale = RE:Round(newscale, 2)
	REPorterFrameCore:SetScale(newscale)
	if SettingsPanel:IsShown() then
		RE.ConfigFrame.obj.children[1].children[1].children[9]:SetValue(newscale)
	end
end

function RE:OnEvent(self, event, ...)
	if event == "ADDON_LOADED" and ... == "REPorter" then
		RE.UpdateTimer = 0
		RE.Settings = LibStub("AceDB-3.0"):New("REPorterSettings", RE.DefaultConfig, true)
		RE.Settings.RegisterCallback(self, "OnProfileShutdown", function() RE:HideDummyMap(true) end)
		RE.Settings.RegisterCallback(self, "OnProfileReset", function() RE:HideDummyMap(false) end)
		RE.Settings.RegisterCallback(self, "OnProfileCopied", function() RE:HideDummyMap(false) end)
		RE.AceConfig.args.Profiles = LibStub("AceDBOptions-3.0"):GetOptionsTable(RE.Settings)

		LibStub("AceConfigRegistry-3.0"):RegisterOptionsTable("REPorter", RE.AceConfig)
		RE.ConfigFrame = LibStub("AceConfigDialog-3.0"):AddToBlizOptions("REPorter", "REPorter")
		SettingsPanel:HookScript("OnHide", function() RE:HideDummyMap(true) end)
		RE:UpdateConfig()

		RegisterAddonMessagePrefix("REPorter")
		BINDING_NAME_REPORTERINC1 = L["Incoming"].." 1"
		BINDING_NAME_REPORTERINC2 = L["Incoming"].." 2"
		BINDING_NAME_REPORTERINC3 = L["Incoming"].." 3"
		BINDING_NAME_REPORTERINC4 = L["Incoming"].." 4"
		BINDING_NAME_REPORTERINC5 = L["Incoming"].." 5"
		BINDING_NAME_REPORTERINC6 = L["Incoming"].." 5+"
		BINDING_NAME_REPORTERHELP = HELP_LABEL
		BINDING_NAME_REPORTERCLEAR = L["Clear"]
		REPorterBar:SetHitRectInsets(-5, -5, -5, -5)
		REPorterFrameClip:SetClipsChildren(true)
		REPorterFrameCoreUP.excludedMouseOverUnits = {}
		REPorterFrameCoreUP:SetMouseOverUnitExcluded("player", true)
		REPorterFrameCoreUP.UpdateUnitTooltips = function(self, tooltipFrame) RE:UnitOnEnterPlayer(self, tooltipFrame) end
		REPorterFrameCoreUP:SetFrameLevel(15)

		for i=1, RE.POINumber do
			RE:CreatePOI(i)
		end

		RE.IsSkinned = AddOnSkins and AddOnSkins[1]:CheckOption("REPorter") or false

		self:UnregisterEvent("ADDON_LOADED")
	elseif event == "CHAT_MSG_ADDON" and ... == "REPorter" then
		local _, REMessage = ...
		local REMessageEx = {strsplit(";", REMessage)}

		if REMessageEx[1] == "Version" then
			if not RE.FoundNewVersion and tonumber(REMessageEx[2]) > RE.AddonVersionCheck then
				print("\124cFF74D06C[REPorter]\124r "..L["New version released!"])
				RE.FoundNewVersion = true
			end
		end
	elseif event == "COMBAT_LOG_EVENT_UNFILTERED" and next(RE.POINodes) ~= nil then
		local _, e, _, _, _, _, _, guid, _, _, _, _, _, _, damage = CombatLogGetCurrentEventInfo()
		if e ~= "SPELL_BUILDING_DAMAGE" then return end

        ---@diagnostic disable-next-line: need-check-nil
		local gateID = guid:match("%-(%d-)%-%x-$")
		if gateID == "195496" then -- Horde East
			RE.POINodes[RE.IoCHordeGateName.." - "..L["East"]].health = RE.POINodes[RE.IoCHordeGateName.." - "..L["East"]].health - damage
			if RE.POINodes[RE.IoCHordeGateName.." - "..L["East"]].health < RE.IoCGateEstimator[FACTION_HORDE] then
				RE.IoCGateEstimator[FACTION_HORDE] = RE.POINodes[RE.IoCHordeGateName.." - "..L["East"]].health
			end
		elseif gateID == "195494" then -- Horde Central
			RE.POINodes[RE.IoCHordeGateName.." - "..L["Front"]].health = RE.POINodes[RE.IoCHordeGateName.." - "..L["Front"]].health - damage
			if RE.POINodes[RE.IoCHordeGateName.." - "..L["Front"]].health < RE.IoCGateEstimator[FACTION_HORDE] then
				RE.IoCGateEstimator[FACTION_HORDE] = RE.POINodes[RE.IoCHordeGateName.." - "..L["Front"]].health
			end
		elseif gateID == "195495" then -- Horde West
			RE.POINodes[RE.IoCHordeGateName.." - "..L["West"]].health = RE.POINodes[RE.IoCHordeGateName.." - "..L["West"]].health - damage
			if RE.POINodes[RE.IoCHordeGateName.." - "..L["West"]].health < RE.IoCGateEstimator[FACTION_HORDE] then
				RE.IoCGateEstimator[FACTION_HORDE] = RE.POINodes[RE.IoCHordeGateName.." - "..L["West"]].health
			end
		elseif gateID == "195700" then -- Alliance East
			RE.POINodes[RE.IoCAllianceGateName.." - "..L["East"]].health = RE.POINodes[RE.IoCAllianceGateName.." - "..L["East"]].health - damage
			if RE.POINodes[RE.IoCAllianceGateName.." - "..L["East"]].health < RE.IoCGateEstimator[FACTION_ALLIANCE] then
				RE.IoCGateEstimator[FACTION_ALLIANCE] = RE.POINodes[RE.IoCAllianceGateName.." - "..L["East"]].health
			end
		elseif gateID == "195698" then -- Alliance Center
			RE.POINodes[RE.IoCAllianceGateName.." - "..L["Front"]].health = RE.POINodes[RE.IoCAllianceGateName.." - "..L["Front"]].health - damage
			if RE.POINodes[RE.IoCAllianceGateName.." - "..L["Front"]].health < RE.IoCGateEstimator[FACTION_ALLIANCE] then
				RE.IoCGateEstimator[FACTION_ALLIANCE] = RE.POINodes[RE.IoCAllianceGateName.." - "..L["Front"]].health
			end
		elseif gateID == "195699" then -- Alliance West
			RE.POINodes[RE.IoCAllianceGateName.." - "..L["West"]].health = RE.POINodes[RE.IoCAllianceGateName.." - "..L["West"]].health - damage
			if RE.POINodes[RE.IoCAllianceGateName.." - "..L["West"]].health < RE.IoCGateEstimator[FACTION_ALLIANCE] then
				RE.IoCGateEstimator[FACTION_ALLIANCE] = RE.POINodes[RE.IoCAllianceGateName.." - "..L["West"]].health
			end
		end

		if RE.IoCGateEstimator[FACTION_HORDE] < RE.IoCGateEstimator[FACTION_ALLIANCE] then
			RE.IoCGateEstimatorText = "|cFF00A9FF"..RE:Round((RE.IoCGateEstimator[FACTION_HORDE] / RE.IoCGateHealth) * 100, 0).."%|r"
		elseif RE.IoCGateEstimator[FACTION_HORDE] > RE.IoCGateEstimator[FACTION_ALLIANCE] then
			RE.IoCGateEstimatorText = "|cFFFF141D"..RE:Round((RE.IoCGateEstimator[FACTION_ALLIANCE] / RE.IoCGateHealth) * 100, 0).."%|r"
		else
			RE.IoCGateEstimatorText = ""
		end
		REPorterFrameEstimatorText:SetText(RE.IoCGateEstimatorText)
	elseif event == "PLAYER_ENTERING_WORLD" or event == "ZONE_CHANGED_NEW_AREA" then
		local instance = select(2, IsInInstance())
		if RE.CurrentMap ~= -1 then
			RE:SaveMapSettings()
		end
		if instance ~= "pvp" then
			REPorterFrame:Hide()
			REPorterBar:Hide()
			REPorterFrameEstimator:Hide()
		end
		if instance == "pvp" and RE.CurrentMap == -1 then
			local mapID = GetBestMapForUnit("player")
			if mapID == ABW or mapID == ABJ then
				mapID = AB
			elseif mapID == EOTSR then
				mapID = EOTS
			elseif mapID == KR then
				mapID = AV
			end
			if mapID and RE.MapSettings[mapID] then
				RE.CurrentMap = mapID
				RE:Startup()
			end
		elseif instance ~= "pvp" and RE.CurrentMap ~= -1 then
			RE.CurrentMap = -1
			RE:Shutdown()
		end
	elseif event == "MODIFIER_STATE_CHANGED" and REPorterFrame:IsShown() then
		if IsShiftKeyDown() and IsAltKeyDown() then
			RE.NeedRefresh = true
			REPorterFrameCoreUP:Hide()
			REPorterFrameCorePOITimers:Show()
		elseif IsShiftKeyDown() and IsControlKeyDown() then
			RE.NeedRefresh = true
		elseif REPorterFrameCorePOITimers:IsShown() then
			RE.NeedRefresh = true
			REPorterFrameCoreUP:Show()
			REPorterFrameCorePOITimers:Hide()
		elseif RE.IsOverlay then
			RE.NeedRefresh = true
		end
	elseif event == "GROUP_ROSTER_UPDATE" and REPorterFrame:IsShown() then
		RE.NeedRefresh = true
	elseif event == "UPDATE_UI_WIDGET" then
		local WidgetInfo = ...
		if WidgetInfo and WidgetInfo.widgetID == RE.MapSettings[RE.CurrentMap].WidgetID then
			if RE.CurrentMap == SM or RE.CurrentMap == DR then
				RE:OnPointsUpdate(-1)
			else
				if RE.EstimatorData[5] == -1 then
					RE.EstimatorData[5] = GetTime()
				end
				local CurrentTick = GetTime()
				local RawTick = CurrentTick - RE.EstimatorData[5]
				if RawTick > 0.5 then
					RE:OnPointsUpdate(RawTick)
				end
				RE.EstimatorData[5] = CurrentTick
			end
		end
	elseif event == "AREA_POIS_UPDATED" or event == "VIGNETTES_UPDATED" then
		RE:OnPOIUpdate()
	end
end

function RE:OnPointsUpdate(RawTick)
	local Data = GetDoubleStatusBarWidgetVisualizationInfo(RE.MapSettings[RE.CurrentMap].WidgetID)
	if Data and Data.leftBarValue and Data.rightBarValue then
		if RawTick == -1 then
			local ACart, HCart = (Data.leftBarMax - Data.leftBarValue) / 150, (Data.rightBarMax - Data.rightBarValue) / 150
			RE.SMEstimatorText = "|cFF00A9FF"..RE:Round(ACart, 1).."|r   |cFFFF141D"..RE:Round(HCart, 1).."|r"
			RE.SMEstimatorReport = "Alliance victory: "..RE:Round(ACart, 1).." carts - Horde victory: "..RE:Round(HCart, 1).." carts"
			REPorterFrameEstimatorText:SetText(RE.SMEstimatorText)
		else
			RE.EstimatorData[2] = Data.leftBarValue - RE.EstimatorData[1]
			RE.EstimatorData[4] = Data.rightBarValue - RE.EstimatorData[3]
			RE.EstimatorData[1] = Data.leftBarValue
			RE.EstimatorData[3] = Data.rightBarValue
			if (RE.EstimatorData[2] == 0 and RE.EstimatorData[4] == 0) or RE.EstimatorData[2] >= 100 or RE.EstimatorData[4] >= 100 then
				return
			end
			local TickTime = RawTick % 1 >= 0.5 and ceil(RawTick) or floor(RawTick)
			RE.EstimatorTicks[1] = RE.EstimatorData[2] > 0 and ceil((Data.leftBarMax - Data.leftBarValue) / RE.EstimatorData[2]) or 10000
			RE.EstimatorTicks[2] = RE.EstimatorData[4] > 0 and ceil((Data.rightBarMax - Data.rightBarValue) / RE.EstimatorData[4]) or 10000
			TIMER:CancelTimer(RE.EstimatorTimer)
			if RE.EstimatorTicks[1] < RE.EstimatorTicks[2] then
				RE.IsWinning = "Alliance"
				RE.EstimatorTimer = TIMER:ScheduleTimer(RE.TimerNull, RE.EstimatorTicks[1] * TickTime)
			elseif RE.EstimatorTicks[1] > RE.EstimatorTicks[2] then
				RE.IsWinning = "Horde"
				RE.EstimatorTimer = TIMER:ScheduleTimer(RE.TimerNull, RE.EstimatorTicks[2] * TickTime)
			else
				RE.IsWinning = ""
			end
		end
	end
end

function RE:OnPOIUpdate()
	RE.UpdateInProgress = true
	wipe(RE.POIList)
	wipe(RE.POIInfo)
	for _, v in pairs(RE.POINodes) do
		v.active = false
	end
	if RE.CurrentMap == EOTS and (RE.IsRated or RE.IsBrawl) then
		RE.POIList = GetAreaPOIForMap(EOTSR)
	elseif RE.CurrentMap == SS or RE.CurrentMap == CI then
		RE.POIList = GetVignettes()
	else
		RE.POIList = GetAreaPOIForMap(RE.CurrentMap)
	end
	for i=1, #RE.POIList do
		local battlefieldPOIName = "REPorterFrameCorePOI"..i
		local battlefieldPOI = _G[battlefieldPOIName]
		local colorOverride = {}
		if RE.CurrentMap == SS or RE.CurrentMap == CI then
			wipe(RE.VignetteInfo)
			wipe(RE.VignettePosition)
			RE.VignetteInfo = GetVignetteInfo(RE.POIList[i]) or {}
			RE.VignettePosition = GetVignettePosition(RE.POIList[i], RE.CurrentMap) or {}
			if RE.VignetteInfo and RE.VignettePosition and RE.VignettePosition.x then
				local xZ, yZ = RE:Round(RE.VignettePosition.x, 3), RE:Round(RE.VignettePosition.y, 3)
				RE.POIInfo = {["areaPoiID"] = RE.VignetteInfo.vignetteID, ["name"] = RE.VignetteInfo.name, ["description"] = "", ["position"] = {["x"] = RE.VignettePosition.x, ["y"] = RE.VignettePosition.y}, ["textureIndex"] = 0, ["atlasID"] = RE.VignetteInfo.atlasName}
				if RE.CurrentMap == SS then
					if RE.AzeriteNodes[xZ] and RE.AzeriteNodes[xZ][yZ] then
						RE.POIInfo.name = RE.AzeriteNodes[xZ][yZ]
					end
					if RE.VignetteInfo.atlasName == "AzeriteReady" then
						RE.POIInfo.textureIndex = 1002
					elseif RE.VignetteInfo.atlasName == "AzeriteSpawning" then
						RE.POIInfo.textureIndex = 1001
					end
				elseif RE.POIInfo.atlasID == "QuestObjective" then
					RE.POIInfo.name = RE.POIInfo.areaPoiID
					RE.POIInfo.textureIndex = 2000
				end
			end
		elseif RE.CurrentMap == EOTS and (RE.IsRated or RE.IsBrawl) then
			RE.POIInfo = GetAreaPOIInfo(EOTSR, RE.POIList[i])
		else
			RE.POIInfo = GetAreaPOIInfo(RE.CurrentMap, RE.POIList[i])
		end
		if RE.POIInfo.atlasName and not RE.POIInfo.textureIndex then
			RE.POIInfo.textureIndex = RE.AtlasNameToTextureIndex[RE.POIInfo.atlasName]
		end
		if RE.POIInfo.name and RE.POIInfo.textureIndex ~= nil and RE.POIInfo.textureIndex ~= 0 then
			local x, y = RE:GetRealCoords(RE.POIInfo.position.x, RE.POIInfo.position.y)
			local x1, x2, y1, y2 = GetPOITextureCoords(RE.POIInfo.textureIndex)
			if RE.CurrentMap == IOC then
				RE.POIInfo.gate = false
				if RE:CheckCoordinates(x, y, 421, -401) then
					RE.IoCAllianceGateName = RE.POIInfo.name
					RE.POIInfo.name = RE.POIInfo.name.." - "..L["East"]
					RE.POIInfo.translatedName = "Alliance Gate - East"
					RE.POIInfo.gate = true
					x = x + 15
				elseif RE:CheckCoordinates(x, y, 381, -401) then
					RE.POIInfo.name = RE.POIInfo.name.." - "..L["West"]
					RE.POIInfo.translatedName = "Alliance Gate - West"
					RE.POIInfo.gate = true
					x = x - 13
				elseif RE:CheckCoordinates(x, y, 401, -384) then
					RE.POIInfo.name = RE.POIInfo.name.." - "..L["Front"]
					RE.POIInfo.translatedName = "Alliance Gate - Front"
					RE.POIInfo.gate = true
					y = y + 15
				elseif RE:CheckCoordinates(x, y, 380, -165) then
					RE.IoCHordeGateName = RE.POIInfo.name
					RE.POIInfo.name = RE.POIInfo.name.." - "..L["Front"]
					RE.POIInfo.translatedName = "Horde Gate - Front"
					RE.POIInfo.gate = true
					y = y - 15
				elseif RE:CheckCoordinates(x, y, 406, -145) then
					RE.POIInfo.name = RE.POIInfo.name.." - "..L["East"]
					RE.POIInfo.translatedName = "Horde Gate - East"
					RE.POIInfo.gate = true
					x = x + 10
				elseif RE:CheckCoordinates(x, y, 355, -145) then
					RE.POIInfo.name = RE.POIInfo.name.." - "..L["West"]
					RE.POIInfo.translatedName = "Horde Gate - West"
					RE.POIInfo.gate = true
					x = x - 10
					y = y - 1
				end
			elseif RE.CurrentMap == AV then
				if RE:CheckCoordinates(x, y, 385, -78) then
					y = y - 15
				elseif RE:CheckCoordinates(x, y, 405, -189) then
					y = y - 10
				elseif RE:CheckCoordinates(x, y, 404, -299) then
					x = x + 10
				elseif RE:CheckCoordinates(x, y, 385, -401) then
					x = x + 10
				elseif RE:CheckCoordinates(x, y, 332, -83) then
					x = x - 20
				elseif RE:CheckCoordinates(x, y, 334, -95) then
					y = y - 20
				elseif RE:CheckCoordinates(x, y, 354, -76) then
					y = y + 10
				elseif RE:CheckCoordinates(x, y, 352, -78) then
					y = y + 15
				elseif RE:CheckCoordinates(x, y, 390, -53) then
					y = y - 5
				elseif RE:CheckCoordinates(x, y, 387, -444) then
					x = x + 25
					y = y + 5
				elseif RE:CheckCoordinates(x, y, 385, -463) then
					y = y - 10
				end
			elseif RE.CurrentMap == TOK then
				if RE.POIInfo.areaPoiID == 2774 then
					RE.POIInfo.name = RE.POIInfo.name.." - "..BLUE_GEM
					colorOverride = {0, 0, 1}
				elseif RE.POIInfo.areaPoiID == 2775 then
					RE.POIInfo.name = RE.POIInfo.name.." - "..L["Purple"]
					colorOverride = {0.5, 0, 0.5}
				elseif RE.POIInfo.areaPoiID == 2776 then
					RE.POIInfo.name = RE.POIInfo.name.." - "..RED_GEM
					colorOverride = {1, 0, 0}
				elseif RE.POIInfo.areaPoiID == 2777 then
					RE.POIInfo.name = RE.POIInfo.name.." - "..L["Green"]
					colorOverride = {0, 1, 0}
				end
			elseif RE.CurrentMap == BFW then
				if Contains(RE.BFWWalls, RE.POIInfo.textureIndex) then
					RE.POIInfo.name = RE.POIInfo.name.." "..RE.POIInfo.areaPoiID
				end
			end
			if RE.POINodes[RE.POIInfo.name] == nil then
				RE.POINodes[RE.POIInfo.name] = {["id"] = i, ["poiID"] = RE.POIInfo.areaPoiID, ["name"] = RE.POIInfo.name, ["status"] = RE.POIInfo.description, ["x"] = x, ["y"] = y, ["texture"] = RE.POIInfo.textureIndex, ["active"] = true}
				if RE.CurrentMap == IOC and RE.POIInfo.gate then
					RE.POINodes[RE.POIInfo.name].health = RE.IoCGateHealth
					RE.POINodes[RE.POIInfo.name].maxHealth = RE.IoCGateHealth
					RE.POINodes[RE.POIInfo.name].translatedName = RE.POIInfo.translatedName
				elseif RE.CurrentMap == SS and RE.PlayedFromStart then
					RE:NodeChange(RE.POIInfo.textureIndex, RE.POIInfo.name)
				end
			else
				RE.POINodes[RE.POIInfo.name].id = i
				RE.POINodes[RE.POIInfo.name].poiID = RE.POIInfo.areaPoiID
				RE.POINodes[RE.POIInfo.name].name = RE.POIInfo.name
				RE.POINodes[RE.POIInfo.name].status = RE.POIInfo.description
				RE.POINodes[RE.POIInfo.name].x = x
				RE.POINodes[RE.POIInfo.name].y = y
				RE.POINodes[RE.POIInfo.name].active = true
				RE.POINodes[RE.POIInfo.name].translatedName = RE.POIInfo.translatedName
				if RE.CareAboutNodes and RE.POINodes[RE.POIInfo.name].texture and RE.POINodes[RE.POIInfo.name].texture ~= RE.POIInfo.textureIndex then
					RE:NodeChange(RE.POIInfo.textureIndex, RE.POIInfo.name)
				end
				RE.POINodes[RE.POIInfo.name].texture = RE.POIInfo.textureIndex
			end
			battlefieldPOI.name = RE.POIInfo.name
			battlefieldPOI:SetPoint("CENTER", "REPorterFrameCorePOI", "TOPLEFT", x, y)
			battlefieldPOI:SetWidth(RE.POIIconSize)
			battlefieldPOI:SetHeight(RE.POIIconSize)
			if RE.POIInfo.textureIndex > 1000 then
				_G[battlefieldPOIName.."Texture"]:SetAtlas(RE.POIInfo.atlasID)
			else
				_G[battlefieldPOIName.."Texture"]:SetTexCoord(x1, x2, y1, y2)
			end
			if next(colorOverride) ~= nil then
				_G[battlefieldPOIName.."Texture"]:SetVertexColor(colorOverride[1], colorOverride[2], colorOverride[3], 1)
			else
				_G[battlefieldPOIName.."Texture"]:SetVertexColor(1, 1, 1, 1)
			end
		end
	end
	RE.UpdateInProgress = false
end

function RE:OnUpdate(elapsed)
	if RE.UpdateTimer < 0 then
		RE:BlinkPOI()
		if not RE.ZonesWithoutSubZones[RE.CurrentMap] then
			local subZoneName = GetSubZoneText()
			if subZoneName and subZoneName ~= "" then
				for _, i in pairs({"B1", "B2", "B3", "B4", "B5", "B6", "B7", "B8"}) do
					_G["REPorterBar"..i]:Enable()
				end
			else
				for _, i in pairs({"B1", "B2", "B3", "B4", "B5", "B6", "B7", "B8"}) do
					_G["REPorterBar"..i]:Disable()
				end
			end
		end

		if RE.NeedRefresh then
			RE.NeedRefresh = false
			REPorterFrameCoreUP:ClearUnits()
		end
		REPorterFrameCoreUP:AddUnit("player", "Interface\\Minimap\\MinimapArrow", 40, 40, 1, 1, 1, 1, 1, true)
		if not (IsShiftKeyDown() and IsAltKeyDown()) then
			for i = 1, RE.MapSettings[RE.CurrentMap].PlayerNumber do
				local unit = "raid"..i
				local texture = ""
				if UnitExists(unit) and not UnitIsUnit(unit, "player") then
					texture = "Interface\\Addons\\REPorter\\Textures\\BlipNormal"
					local r, g, b = GetClassColor(select(2, UnitClass(unit)))
					if UnitAffectingCombat(unit) then
						if (UnitHealth(unit) / UnitHealthMax(unit)) * 100 < 26 then
							texture = "Interface\\Addons\\REPorter\\Textures\\BlipDying"
						else
							texture = "Interface\\Addons\\REPorter\\Textures\\BlipCombat"
						end
					elseif UnitIsDeadOrGhost(unit) then
						texture = "Interface\\Addons\\REPorter\\Textures\\BlipDead"
						r, g, b = r * 0.35, g * 0.35, b * 0.35
					end
					local raidMarker = GetRaidTargetIndex(unit)
					if IsShiftKeyDown() and IsControlKeyDown() then
						RE.IsOverlay = true
						if raidMarker ~= nil then
							texture = "Interface\\Addons\\REPorter\\Textures\\RaidMarker"..raidMarker
							REPorterFrameCoreUP:AddUnit(unit, texture, 25, 25, 1, 1, 1, 1, 0, false)
						elseif UnitGroupRolesAssigned(unit) == "HEALER" then
							REPorterFrameCoreUP:AddUnit(unit, texture.."Healer", 30, 30, r, g, b, 1, 0, false)
						end
					else
						RE.IsOverlay = false
						if RE.Settings.profile.DisplayMarks and raidMarker ~= nil then
							texture = "Interface\\Addons\\REPorter\\Textures\\RaidMarker"..raidMarker
							REPorterFrameCoreUP:AddUnit(unit, texture, 25, 25, 1, 1, 1, 1, 0, false)
						elseif RE.Settings.profile.DisplayHealers and UnitGroupRolesAssigned(unit) == "HEALER" then
							REPorterFrameCoreUP:AddUnit(unit, texture.."Healer", 30, 30, r, g, b, 1, 0, false)
						else
							REPorterFrameCoreUP:AddUnit(unit, texture, 25, 25, r, g, b, 1, 0, false)
						end
					end
				end
				if RE.PinTextures[unit] and RE.PinTextures[unit] ~= texture then
					RE.NeedRefresh = true
				end
				RE.PinTextures[unit] = texture
			end
		end
		REPorterFrameCoreUP:FinalizeUnits()
		REPorterFrameCoreUP:UpdateTooltips(GameTooltip)
		local playerBlipFrameLevel = REPorterFrameCoreUP:GetFrameLevel()

		if RE.CareAboutFlags then
			RE.FlagsPool:ReleaseAll()
			for i = 1, GetNumBattlefieldFlagPositions() do
				local flagX, flagY, flagTexture = GetBattlefieldFlagPosition(i, RE.CurrentMap)
				if flagX then
					local flagFrame = RE.FlagsPool:Acquire()
					flagX, flagY = RE:GetRealCoords(flagX, flagY)
					flagFrame.Texture:SetTexture(flagTexture)
					flagFrame:SetPoint("CENTER", "REPorterFrameCorePOI", "TOPLEFT", flagX, flagY)
					flagFrame:SetFrameLevel(playerBlipFrameLevel - 1)
					flagFrame:Show()
				end
			end
		end

		if RE.CareAboutVehicles then
			RE.NumVehicles = GetNumBattlefieldVehicles()
			local totalVehicles = #RE.BGVehicles
			local index = 0
			for i=1, RE.NumVehicles do
				if i > totalVehicles then
					local vehicleName = "REPorterFrameCorePOIVehicle"..i
					RE.BGVehicles[i] = CreateFrame("FRAME", vehicleName, REPorterFrameCorePOI, "REPorterVehicleTemplate")
					RE.BGVehicles[i].texture = _G[vehicleName.."Texture"]
				end
				RE.BGVehicleInfo = GetBattlefieldVehicleInfo(i, RE.CurrentMap)
				if RE.BGVehicleInfo and RE.BGVehicleInfo.x and RE.BGVehicleInfo.isAlive and not RE.BGVehicleInfo.isPlayer and RE.BGVehicleInfo.atlas ~= "Idle" then
					local vehicleX, vehicleY = RE:GetRealCoords(RE.BGVehicleInfo.x, RE.BGVehicleInfo.y)
					RE.BGVehicles[i].texture:SetAtlas(RE.BGVehicleInfo.atlas)
					RE.BGVehicles[i].texture:SetRotation(RE.BGVehicleInfo.facing)
					RE.BGVehicles[i].name = RE.BGVehicleInfo.name
					RE.BGVehicles[i]:SetPoint("CENTER", "REPorterFrameCorePOI", "TOPLEFT", vehicleX, vehicleY)
					if IsShiftKeyDown() and IsAltKeyDown() then
						RE.BGVehicles[i]:SetFrameLevel(9)
					else
						RE.BGVehicles[i]:SetFrameLevel(playerBlipFrameLevel - 1)
					end
					RE.BGVehicles[i]:Show()
					index = i
				else
					RE.BGVehicles[i]:Hide()
				end
			end
			if index < totalVehicles then
				for i=index+1, totalVehicles do
					RE.BGVehicles[i]:Hide()
				end
			end
		end

		if not RE.UpdateInProgress then
			for i=1, RE.POINumber do
				_G["REPorterFrameCorePOI"..i]:Hide()
				_G["REPorterFrameCorePOI"..i.."Timer"]:Hide()
			end
			for _, v in pairs(RE.POINodes) do
				if v.active then
				  local battlefieldPOIName = "REPorterFrameCorePOI"..v.id
					local battlefieldPOI = _G[battlefieldPOIName]
				  if TIMER:TimeLeft(v.timer) == 0 then
				    if strfind(v.status, FACTION_HORDE) then
				      _G[battlefieldPOIName.."TextureBG"]:SetColorTexture(1,0,0,0.3)
				    elseif strfind(v.status, FACTION_ALLIANCE) then
				      _G[battlefieldPOIName.."TextureBG"]:SetColorTexture(0,0,1,0.3)
				    else
				      if RE.CurrentMap == SS then
				        _G[battlefieldPOIName.."TextureBG"]:SetColorTexture(0,1,0,0.3)
							elseif RE.CurrentMap == CI or (RE.CurrentMap == BFW and Contains(RE.BFWWalls, v.texture)) then
								_G[battlefieldPOIName.."TextureBG"]:SetColorTexture(0,0,0,0)
				      else
				        _G[battlefieldPOIName.."TextureBG"]:SetColorTexture(0,0,0,0.3)
				      end
				    end
				    _G[battlefieldPOIName.."TextureBG"]:SetWidth(RE.POIIconSize)
				    _G[battlefieldPOIName.."TextureBGofBG"]:Hide()
				    if RE.CareAboutGates and v.health and v.health > 0 then
				      _G[battlefieldPOIName.."TextureBGTop1"]:Hide()
				      _G[battlefieldPOIName.."TextureBGTop2"]:Show()
				      _G[battlefieldPOIName.."TextureBGTop2"]:SetWidth((v.health/v.maxHealth) * RE.POIIconSize)
				      if RE.PlayedFromStart then
								_G[battlefieldPOIName.."TimerCaption"]:SetText(RE:Round((v.health/v.maxHealth)*100, 0).."%")
				      else
				        _G[battlefieldPOIName.."TimerCaption"]:SetText("|cFFFF141D"..RE:Round((v.health/v.maxHealth)*100, 0).."%|r")
				      end
				      _G[battlefieldPOIName.."Timer"]:Show()
				    else
				      _G[battlefieldPOIName.."TextureBGTop1"]:Hide()
				      _G[battlefieldPOIName.."TextureBGTop2"]:Hide()
				      _G[battlefieldPOIName.."Timer"]:Hide()
				    end
				  else
				    local timeLeft = TIMER:TimeLeft(v.timer)
				    _G[battlefieldPOIName.."TextureBG"]:SetWidth(RE.POIIconSize - ((timeLeft / RE.DefaultTimer) * RE.POIIconSize))
				    _G[battlefieldPOIName.."TextureBGofBG"]:Show()
				    _G[battlefieldPOIName.."TextureBGofBG"]:SetWidth((timeLeft / RE.DefaultTimer) * RE.POIIconSize)
				    if v.isCapturing == FACTION_HORDE or RE.CurrentMap == SS then
				      _G[battlefieldPOIName.."TextureBG"]:SetColorTexture(1,0,0,RE.BlinkPOIValue)
				    elseif v.isCapturing == FACTION_ALLIANCE then
				      _G[battlefieldPOIName.."TextureBG"]:SetColorTexture(0,0,1,RE.BlinkPOIValue)
				    end
				    if timeLeft <= 10 then
				      _G[battlefieldPOIName.."TextureBGTop1"]:Show()
				      _G[battlefieldPOIName.."TextureBGTop2"]:Show()
				      _G[battlefieldPOIName.."TextureBGTop1"]:SetWidth((timeLeft / 10) * RE.POIIconSize)
				      _G[battlefieldPOIName.."TextureBGTop2"]:SetWidth((timeLeft / 10) * RE.POIIconSize)
				    else
				      _G[battlefieldPOIName.."TextureBGTop1"]:Hide()
				      _G[battlefieldPOIName.."TextureBGTop2"]:Hide()
				    end
				    _G[battlefieldPOIName.."Timer"]:Show()
				    _G[battlefieldPOIName.."TimerCaption"]:SetText(RE:ShortTime(RE:Round(TIMER:TimeLeft(v.timer), 0)))
				  end
					battlefieldPOI:Show()
				end
			end
		end
		if TIMER:TimeLeft(RE.EstimatorTimer) > 0 then
			if RE.IsWinning == "Alliance" then
				REPorterFrameEstimatorText:SetText("|cFF00A9FF"..RE:ShortTime(RE:Round(TIMER:TimeLeft(RE.EstimatorTimer), 0)).."|r")
			elseif RE.IsWinning == "Horde" then
				REPorterFrameEstimatorText:SetText("|cFFFF141D"..RE:ShortTime(RE:Round(TIMER:TimeLeft(RE.EstimatorTimer), 0)).."|r")
			else
				REPorterFrameEstimatorText:SetText("")
			end
		end
		RE.UpdateTimer = RE.MapUpdateRate
	else
		RE.UpdateTimer = RE.UpdateTimer - elapsed
	end
end

function RE:UnitOnEnterPlayer(self, tooltipFrame)
	local tooltipText = ""
	local prefix = ""

	for unit in pairs(self.currentMouseOverUnits) do
		if not self:IsMouseOverUnitExcluded(unit) then
			local unitName = UnitName(unit)
			local unitHealth = (UnitHealth(unit) / UnitHealthMax(unit)) * 100
			local _, _, _, unitColor = GetClassColor(select(2, UnitClass(unit)))
			tooltipText = tooltipText..prefix.."|c"..unitColor..unitName.."|r |cFFFFFFFF["..RE:Round(unitHealth, 0).."%]|r"
			prefix = "\n"
		end
	end

	if tooltipText ~= "" then
		tooltipFrame:SetOwner(self, "ANCHOR_CURSOR_RIGHT")
		tooltipFrame:SetText(tooltipText)
	elseif tooltipFrame:GetOwner() == self then
		tooltipFrame:ClearLines()
		tooltipFrame:Hide()
	end
end

function RE:UnitOnEnterPOI(self)
	local tooltipText = ""
	local battlefieldPOI = _G[self:GetName()]

	if RE.CurrentMap == CI or (RE.CurrentMap == BFW and Contains(RE.BFWWalls, RE.POINodes[battlefieldPOI.name].texture)) then
		return
	end

	if battlefieldPOI:IsMouseOver() and battlefieldPOI.name ~= "" then
		local status = ""
		if RE.POINodes[battlefieldPOI.name].status and RE.POINodes[battlefieldPOI.name].status ~= "" then
			status = "\n"..RE.POINodes[battlefieldPOI.name].status
		end
		if RE.POINodes[battlefieldPOI.name].health then
			if RE.PlayedFromStart then
				status = "\n["..RE:Round((RE.POINodes[battlefieldPOI.name].health/RE.POINodes[battlefieldPOI.name].maxHealth)*100, 0).."%]"
			else
				status = "\n[|r|cFFFF141D"..RE:Round((RE.POINodes[battlefieldPOI.name].health/RE.POINodes[battlefieldPOI.name].maxHealth)*100, 0).."%|r|cFFFFFFFF]"
			end
		end
		if TIMER:TimeLeft(RE.POINodes[battlefieldPOI.name].timer) == 0 then
			tooltipText = tooltipText..battlefieldPOI.name.."|cFFFFFFFF"..status.."|r"
		else
			tooltipText = tooltipText..battlefieldPOI.name.."|cFFFFFFFF ["..RE:ShortTime(RE:Round(TIMER:TimeLeft(RE.POINodes[battlefieldPOI.name].timer), 0)).."]"..status.."|r"
		end
	end

	if tooltipText ~= "" then
		GameTooltip:SetOwner(self, "ANCHOR_CURSOR_RIGHT")
		GameTooltip:SetText(tooltipText)
		GameTooltip:Show()
	elseif GameTooltip:GetOwner() == self then
		GameTooltip:ClearLines()
		GameTooltip:Hide()
	end
end

function RE:OnClickPOI(self)
	if RE.CurrentMap == CI or (RE.CurrentMap == BFW and Contains(RE.BFWWalls, RE.POINodes[self.name].texture)) then
		return
	end

	CloseDropDownMenus()
	RE.ClickedPOI = RE.POINodes[self.name].name
	MenuUtil.CreateContextMenu(UIParent, RE.POIDropDown)
end
---

-- *** Core functions
function RE:Startup()
	RE.PlayedFromStart = true
	RE:Create()
	REPorterFrameCoreUP:ResetCurrentMouseOverUnits()
	REPorterFrame:Show()
	REPorterFrameEstimator:Show()
	if RE.Settings.profile.HideMinimap then
		MinimapCluster:Hide()
	end
	SendAddonMessage("REPorter", "Version;"..RE.AddonVersionCheck, "INSTANCE_CHAT")
	if IsInGuild() then
		SendAddonMessage("REPorter", "Version;"..RE.AddonVersionCheck, "GUILD")
	end
end

function RE:Shutdown()
	REPorterFrameCore:SetScript("OnUpdate", nil)
	TIMER:CancelTimer(RE.EstimatorTimer)
	RE.FlagsPool:ReleaseAll()
	RE.POINodes = {}
	RE.IsWinning = ""
	RE.IsBrawl = false
	RE.IsRated = false
	RE.CareAboutNodes = false
	RE.CareAboutPoints = false
	RE.CareAboutGates = false
	RE.CareAboutFlags = false
	RE.CareAboutVehicles = false
	REPorterFrame:UnregisterEvent("COMBAT_LOG_EVENT_UNFILTERED")
	REPorterFrame:UnregisterEvent("VIGNETTES_UPDATED")
	REPorterFrame:UnregisterEvent("AREA_POIS_UPDATED")
	REPorterFrame:UnregisterEvent("UPDATE_UI_WIDGET")
	REPorterFrameEstimatorText:SetText("")
	REPorterFrameCoreUP:ResetCurrentMouseOverUnits()
	CloseDropDownMenus()
	if not MinimapCluster:IsShown() and RE.Settings.profile.HideMinimap then
		MinimapCluster:Show()
	end
	for i=1, RE.POINumber do
		_G["REPorterFrameCorePOI"..i]:Hide()
		_G["REPorterFrameCorePOI"..i.."Timer"]:Hide()
		_G["REPorterFrameCorePOI"..i.."Texture"]:SetTexture("Interface\\Minimap\\POIIcons")
		_G["REPorterFrameCorePOI"..i.."Texture"]:SetTexCoord(0, 1, 0, 1)
		for _, v in pairs(RE.POINodes) do
			TIMER:CancelTimer(v.timer)
		end
	end
	if RE.NumVehicles then
		for i=1, RE.NumVehicles do
			RE.BGVehicles[i]:Hide()
		end
	end
	for i=1, 12 do
		_G["REPorterFrameCoreMap"..i]:SetTexture(nil)
	end
end

function RE:Create()
	REPorterFrameCore:SetScript("OnUpdate", nil)
	REPorterFrameEstimator:ClearAllPoints()
	REPorterFrameEstimator:SetPoint("TOP", UIWidgetTopCenterContainerFrame, "BOTTOM", 0, -10)
	RE.POINodes = {}

	if RE.CurrentMap == IOC then
		RE.IoCGateEstimator = {}
		RE.IoCGateEstimator[FACTION_ALLIANCE] = RE.IoCGateHealth
		RE.IoCGateEstimator[FACTION_HORDE] = RE.IoCGateHealth
		RE.IoCGateEstimatorText = ""
	elseif RE.CurrentMap == SM or RE.CurrentMap == DR then
		RE.SMEstimatorText = ""
		RE.SMEstimatorReport = ""
	else
		RE.EstimatorTicks = {10000, 10000}
		RE.EstimatorData = {0, 0, 0, 0, -1}
	end

	if Contains({AV, BFG, IOC, AB, DG, SS, EOTS, BFW, CI, ASH, TOK}, RE.CurrentMap) then
		RE.CareAboutNodes = true
		if RE.CurrentMap == SS then
			REPorterFrame:RegisterEvent("VIGNETTES_UPDATED")
		else
			REPorterFrame:RegisterEvent("AREA_POIS_UPDATED")
		end
	else
		RE.CareAboutNodes = false
	end
	if Contains({BFG, EOTS, AB, DG, SM, DR}, RE.CurrentMap) then
		RE.CareAboutPoints = true
		REPorterFrame:RegisterEvent("UPDATE_UI_WIDGET")
	else
		RE.CareAboutPoints = false
	end
	if RE.CurrentMap == IOC then
		RE.CareAboutGates = true
		REPorterFrame:RegisterEvent("COMBAT_LOG_EVENT_UNFILTERED")
	else
		RE.CareAboutGates = false
	end
	if Contains({WG, TP, EOTS, TOK, CI, DR}, RE.CurrentMap) then
		RE.CareAboutFlags = true
	else
		RE.CareAboutFlags = false
	end
	if Contains({IOC, SM, BFW, DR}, RE.CurrentMap) then
		RE.CareAboutVehicles = true
	else
		RE.CareAboutVehicles = false
	end

	RE:LoadMapSettings()
	RE:SetupReportBar()
	TIMER:ScheduleTimer(RE.TimerJoinCheck, 5)
	REPorterFrameCore:SetScript("OnUpdate", RE.OnUpdate)
end

function RE:NodeChange(newTexture, nodeName)
	TIMER:CancelTimer(RE.POINodes[nodeName].timer)
	if RE.POICaptureStatus[newTexture] ~= nil then
		RE.POINodes[nodeName].timer = TIMER:ScheduleTimer(RE.TimerNull, RE.DefaultTimer)
		RE.POINodes[nodeName].isCapturing = RE.POICaptureStatus[newTexture]
	end
end

function RE:POIStatus(POIName)
	if RE.POINodes[POIName]then
		if TIMER:TimeLeft(RE.POINodes[POIName].timer) == 0 then
			if RE.POINodes[POIName].health and RE.PlayedFromStart then
				local gateHealth = RE:Round((RE.POINodes[POIName].health / RE.POINodes[POIName].maxHealth) * 100, 0)
				return " - Health: "..gateHealth.."%"
			end
			return ""
		else
			local timeLeft = RE:ShortTime(RE:Round(TIMER:TimeLeft(RE.POINodes[POIName].timer), 0))
			return " - "..timeLeft
		end
	end
	return ""
end

function RE:POIOwner(POIName, isReport)
	local prefix = " - "
	if isReport then
		prefix = ""
	end
	local TranslatedName = LBS[POIName] or POIName
	if RE.POINodes[POIName] then
		if RE.POINodes[POIName].translatedName then
			TranslatedName = RE.POINodes[POIName].translatedName
		end
		if strfind(RE.POINodes[POIName].status, FACTION_HORDE) then
			return prefix..TranslatedName.." (Horde)"
		elseif strfind(RE.POINodes[POIName].status, FACTION_ALLIANCE) then
			return prefix..TranslatedName.." (Alliance)"
		else
			if RE.POINodes[POIName].isCapturing == FACTION_HORDE and TIMER:TimeLeft(RE.POINodes[POIName].timer) ~= 0 then
				return prefix..TranslatedName.." (Horde)"
			elseif RE.POINodes[POIName].isCapturing == FACTION_ALLIANCE and TIMER:TimeLeft(RE.POINodes[POIName].timer) ~= 0 then
				return prefix..TranslatedName.." (Alliance)"
			else
				return prefix..TranslatedName
			end
		end
	end
	return prefix..TranslatedName
end

function RE:SmallButton(number, otherNode)
	if select(2, IsInInstance()) == "pvp" then
		local name
		if otherNode then
			name = RE.ClickedPOI
		elseif RE.ZonesWithoutSubZones[RE.CurrentMap] then
			name = ""
		else
			name = GetSubZoneText()
		end
		local message
		if name and name ~= "" then
			if number < 6 then
				message = strupper("Incoming").." "..number
			else
				message = strupper("Incoming").." 5+"
			end
			message = message..RE:POIOwner(name)..RE:POIStatus(name)
			SendChatMessage(message, "INSTANCE_CHAT")
			if RE.Settings.profile.UseRaidWarnings then
				SendChatMessage(message, "RAID_WARNING")
			end
		else
			print("\124cFF74D06C[REPorter]\124r "..L["This location does not have a name. Action canceled."])
		end
	else
		print("\124cFF74D06C[REPorter]\124r "..L["This addon only works in battlegrounds."])
	end
end

function RE:BigButton(isHelp, otherNode)
	if select(2, IsInInstance()) == "pvp" then
		local name
		if otherNode then
			name = RE.ClickedPOI
		elseif RE.ZonesWithoutSubZones[RE.CurrentMap] then
			name = ""
		else
			name = GetSubZoneText()
		end
		local message
		if name and name ~= "" then
			if isHelp then
				message = strupper("Help")..RE:POIOwner(name)..RE:POIStatus(name)
			else
				message = strupper("Clear")..RE:POIOwner(name)..RE:POIStatus(name)
			end
			SendChatMessage(message, "INSTANCE_CHAT")
			if RE.Settings.profile.UseRaidWarnings then
				SendChatMessage(message, "RAID_WARNING")
			end
		else
			print("\124cFF74D06C[REPorter]\124r "..L["This location does not have a name. Action canceled."])
		end
	else
		print("\124cFF74D06C[REPorter]\124r "..L["This addon only works in battlegrounds."])
	end
end

function RE:ReportEstimator()
	if IsShiftKeyDown() then
		if TIMER:TimeLeft(RE.EstimatorTimer) > 0 then
			SendChatMessage(RE.IsWinning.." victory: "..RE:ShortTime(RE:Round(TIMER:TimeLeft(RE.EstimatorTimer), 0)), "INSTANCE_CHAT")
		elseif RE.CurrentMap == SM and RE.SMEstimatorReport ~= "" then
			SendChatMessage(RE.SMEstimatorReport, "INSTANCE_CHAT")
		elseif RE.CurrentMap == IOC and RE.PlayedFromStart then
			SendChatMessage("Alliance gate: "..RE:Round((RE.IoCGateEstimator[FACTION_ALLIANCE] / RE.IoCGateHealth) * 100, 0).."% - Horde gate: "..RE:Round((RE.IoCGateEstimator[FACTION_HORDE] / RE.IoCGateHealth) * 100, 0).."%", "INSTANCE_CHAT")
		end
	end
end

function RE:ReportDropDownClick(reportType)
	if reportType ~= "" then
		SendChatMessage(strupper(reportType)..RE:POIOwner(RE.ClickedPOI)..RE:POIStatus(RE.ClickedPOI), "INSTANCE_CHAT")
	else
		SendChatMessage(RE:POIOwner(RE.ClickedPOI, true)..RE:POIStatus(RE.ClickedPOI), "INSTANCE_CHAT")
	end
end
--

-- *** Config functions
function RE:UpdateConfig()
	REPorterFrame:SetAlpha(RE.Settings.profile.Opacity)
	REPorterBar:SetAlpha(0.25)
	REPorterFrameBorderResize:SetShown(not RE.Settings.profile.Locked)
	RE:SetupReportBar()
	if select(2, IsInInstance()) == "pvp" then
		MinimapCluster:SetShown(not RE.Settings.profile.HideMinimap)
	end
end

function RE:UpdateScaleConfig(_, val)
	if RE.Settings.profile.Map[RE.CurrentMap] then
		if val then
			local scale = RE:Round(val, 2)
			REPorterFrameCore:SetScale(scale)
			RE.Settings.profile.Map[RE.CurrentMap].ms = scale
			REPorterFrameCore:ClearAllPoints()
			REPorterFrameCore:SetPoint("CENTER", REPorterFrameCoreAnchor, "CENTER")
		end
		return RE:Round(REPorterFrameCore:GetScale(), 2)
	else
		return 1.0
	end
end

function RE:SetupReportBar()
	local previousButton = "B1"
	local handle = RE.Settings.profile.BarHandle
	local offset = 0

	if RE.IsSkinned then
		if handle == 3 or handle == 6 or handle == 9 or handle == 12 then
			offset = -2
		elseif handle == 1 or handle == 4 or handle == 7 or handle == 10 then
			offset = 2
		end
	end

	REPorterBar:ClearAllPoints()
	if handle < 15 and not RE.ZonesWithoutSubZones[RE.CurrentMap] then
		REPorterBar:SetAlpha(0.25)
		if RE.IsSkinned then
			REPorterBarB1:SetPoint("TOPLEFT", "REPorterBar", "TOPLEFT", 5, -5)
		else
			REPorterBarB1:SetPoint("TOPLEFT", "REPorterBar", "TOPLEFT", 10, -10)
		end
		if handle < 7 or handle == 13 then
			if handle == 13 then
				REPorterBar:SetPoint("CENTER", "UIParent", "BOTTOMLEFT", RE.Settings.profile.BarX, RE.Settings.profile.BarY)
			elseif handle > 3 then
				REPorterBar:SetPoint(RE.ReportBarAnchor[handle][1], REPorterFrameBorder, RE.ReportBarAnchor[handle][2], 1, offset)
			else
				REPorterBar:SetPoint(RE.ReportBarAnchor[handle][1], REPorterFrameBorder, RE.ReportBarAnchor[handle][2], -1, offset)
			end
			if RE.IsSkinned then
				REPorterBar:SetHeight(210)
				REPorterBar:SetWidth(35)
			else
				REPorterBar:SetHeight(220)
				REPorterBar:SetWidth(45)
			end
			for _, i in pairs({"B2", "B3", "B4", "B5", "B6", "B7", "B8"}) do
				_G["REPorterBar"..i]:ClearAllPoints()
				_G["REPorterBar"..i]:SetPoint("TOP", "REPorterBar"..previousButton, "BOTTOM")
				previousButton = i
			end
		else
			if handle == 14 then
				REPorterBar:SetPoint("CENTER", "UIParent", "BOTTOMLEFT", RE.Settings.profile.BarX, RE.Settings.profile.BarY)
			elseif handle > 9 then
				REPorterBar:SetPoint(RE.ReportBarAnchor[handle][1], REPorterFrameBorder, RE.ReportBarAnchor[handle][2], offset, -1)
			else
				REPorterBar:SetPoint(RE.ReportBarAnchor[handle][1], REPorterFrameBorder, RE.ReportBarAnchor[handle][2], offset, 1)
			end
			if RE.IsSkinned then
				REPorterBar:SetHeight(35)
				REPorterBar:SetWidth(210)
			else
				REPorterBar:SetHeight(45)
				REPorterBar:SetWidth(220)
			end
			for _, i in pairs({"B2", "B3", "B4", "B5", "B6", "B7", "B8"}) do
				_G["REPorterBar"..i]:ClearAllPoints()
				_G["REPorterBar"..i]:SetPoint("LEFT", "REPorterBar"..previousButton, "RIGHT")
				previousButton = i
			end
		end
		REPorterBar:Show()
	else
		REPorterBar:Hide()
	end
end

function RE:LoadMapSettings()
	if RE.CurrentMap ~= -1 then
		local wx, wy = RE.Settings.profile.Map[RE.CurrentMap].wx, RE.Settings.profile.Map[RE.CurrentMap].wy
		local ww = RE.Settings.profile.Map[RE.CurrentMap].ww
		local wh = RE.Settings.profile.Map[RE.CurrentMap].wh
		local mx, my = RE.Settings.profile.Map[RE.CurrentMap].mx, RE.Settings.profile.Map[RE.CurrentMap].my
		local ms = RE.Settings.profile.Map[RE.CurrentMap].ms

		REPorterFrame:ClearAllPoints()
		REPorterFrameCore:ClearAllPoints()
		REPorterFrameCoreAnchor:ClearAllPoints()
		REPorterFrame:SetWidth(ww)
		REPorterFrame:SetHeight(wh)
		REPorterFrame:SetPoint("CENTER", "UIParent", "BOTTOMLEFT", wx, wy)
		REPorterFrameCore:SetScale(ms)
		REPorterFrameCore:SetPoint("CENTER", REPorterFrameCoreAnchor, "CENTER")
		REPorterFrameCoreAnchor:SetPoint("CENTER", REPorterFrameClip, "CENTER", mx, my)
		REPorterFrame:SetAlpha(RE.Settings.profile.Opacity)

		local textures
		if RE.CurrentMap == AB and RE.IsBrawl then
			local currentMap = GetBestMapForUnit("player")
			if currentMap == ABJ then
				textures = GetMapArtLayerTextures(AB, 1)
				RE.ZonesWithoutSubZones[AB] = true
			elseif currentMap == ABW then
				textures = GetMapArtLayerTextures(ABW, 1)
				RE.ZonesWithoutSubZones[AB] = true
			else
				textures = GetMapArtLayerTextures(RE.CurrentMap, 1)
				RE.ZonesWithoutSubZones[AB] = nil
			end
		else
			textures = GetMapArtLayerTextures(RE.CurrentMap, 1)
			RE.ZonesWithoutSubZones[AB] = nil
		end
		for i=1, #textures do
			_G["REPorterFrameCoreMap"..i]:SetTexture(textures[i])
		end
	end
end

function RE:SaveMapSettings()
	if RE.CurrentMap ~= -1 then
		local wx, wy = REPorterFrame:GetCenter()
		local ww = REPorterFrame:GetWidth()
		local wh = REPorterFrame:GetHeight()
		local x1, y1 = REPorterFrameClip:GetCenter()
		local x2, y2 = REPorterFrameCoreAnchor:GetCenter()
		local mx, my = x2-x1, y2-y1
		local ms = RE:Round(REPorterFrameCore:GetScale(), 2)

		RE.Settings.profile.Map[RE.CurrentMap] = {["wx"] = RE:Round(wx, 0), ["wy"] = RE:Round(wy, 0), ["ww"] = RE:Round(ww, 0), ["wh"] = RE:Round(wh, 0), ["mx"] = RE:Round(mx, 0), ["my"] = RE:Round(my, 0), ["ms"] = RE:Round(ms, 2)}
	end
end

function RE:ShowDummyMap(mapID)
	if REPorterFrame:IsShown() and RE.CurrentMap ~= -1 then
		RE:SaveMapSettings()
	end

	RE.CurrentMap = mapID
	RE:LoadMapSettings()
	RE:SetupReportBar()
	REPorterFrame:Show()
	REPorterFrame:SetFrameStrata("HIGH")
end

function RE:HideDummyMap(save)
	if REPorterFrame:IsShown() and select(2, IsInInstance()) ~= "pvp" then
		if save then RE:SaveMapSettings() end
		RE.CurrentMap = -1
		RE.LastMap = 0
		REPorterFrame:Hide()
		REPorterFrame:SetFrameStrata("MEDIUM")
		REPorterBar:Hide()
	end
end
--
