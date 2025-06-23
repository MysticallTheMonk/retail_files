local AddOnName, NS = ...

local AddOn = CreateFrame("Frame")
AddOn.L = LibStub("AceLocale-3.0"):GetLocale(AddOnName)
AddOn.defaults = { global = {}, profile = { modules = { ["Party"] = true } } }

NS[1] = AddOn
NS[2] = AddOn.L
NS[3] = AddOn.defaults.profile
NS[4] = AddOn.defaults.global

function NS:unpack()
	return self[1], self[2], self[3], self[4]
end

NS[1].Libs = {}
NS[1].Libs.ACD = LibStub("AceConfigDialog-3.0-OmniCDC")
NS[1].Libs.ACR = LibStub("AceConfigRegistry-3.0")
NS[1].Libs.CBH = LibStub("CallbackHandler-1.0"):New(NS[1])
NS[1].Libs.LSM = LibStub("LibSharedMedia-3.0")
NS[1].Libs.OmniCDC = LibStub("LibOmniCDC")

NS[1].Party = CreateFrame("Frame")
NS[1].Comm = CreateFrame("Frame")
NS[1].Cooldowns = CreateFrame("Frame")

NS[1].AddOn = AddOnName
NS[1].Version = C_AddOns.GetAddOnMetadata(AddOnName, "Version")
NS[1].Author = C_AddOns.GetAddOnMetadata(AddOnName, "Author")
NS[1].Notes = C_AddOns.GetAddOnMetadata(AddOnName, "Notes")
NS[1].License = C_AddOns.GetAddOnMetadata(AddOnName, "X-License")
NS[1].Localizations = C_AddOns.GetAddOnMetadata(AddOnName, "X-Localizations")

NS[1].userGUID = UnitGUID("player")
NS[1].userName = UnitName("player")
NS[1].userRealm = GetRealmName()
NS[1].userNameWithRealm = format("%s-%s", NS[1].userName, NS[1].userRealm)
NS[1].userClass = select(2, UnitClass("player"))
NS[1].userRaceID = select(3, UnitRace("player"))
NS[1].userLevel = UnitLevel("player")
NS[1].userFaction = UnitFactionGroup("player")
NS[1].userClassHexColor = "|c" .. select(4, GetClassColor(NS[1].userClass))

NS[1].TocVersion = select(4, GetBuildInfo())
NS[1].LoginMessage = format("%sOmniCD v%s|r - /oc", NS[1].userClassHexColor, NS[1].Version)

NS[1].isRetail = WOW_PROJECT_ID == WOW_PROJECT_MAINLINE
NS[1].isClassic = WOW_PROJECT_ID == WOW_PROJECT_CLASSIC
NS[1].isBCC = WOW_PROJECT_ID == WOW_PROJECT_BURNING_CRUSADE_CLASSIC
NS[1].isWOTLKC = WOW_PROJECT_ID == WOW_PROJECT_WRATH_CLASSIC
NS[1].isCata = WOW_PROJECT_ID == WOW_PROJECT_CATACLYSM_CLASSIC


NS[1].preBCC = LE_EXPANSION_LEVEL_CURRENT <= LE_EXPANSION_BURNING_CRUSADE
NS[1].preWOTLKC = LE_EXPANSION_LEVEL_CURRENT <= LE_EXPANSION_WRATH_OF_THE_LICH_KING
NS[1].preCata = LE_EXPANSION_LEVEL_CURRENT <= LE_EXPANSION_CATACLYSM
NS[1].postMoP = LE_EXPANSION_LEVEL_CURRENT >= LE_EXPANSION_MISTS_OF_PANDARIA
NS[1].isSL = LE_EXPANSION_LEVEL_CURRENT == LE_EXPANSION_SHADOWLANDS
NS[1].postSL = LE_EXPANSION_LEVEL_CURRENT >= LE_EXPANSION_SHADOWLANDS
NS[1].postDF = LE_EXPANSION_LEVEL_CURRENT >= LE_EXPANSION_DRAGONFLIGHT

_G.OmniCD = NS
