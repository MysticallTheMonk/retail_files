local AddOnName, NS = ...

local E = CreateFrame("Frame")
E.L = LibStub("AceLocale-3.0"):GetLocale(AddOnName)
E.defaults = { global = {}, profile = { modules = {} } }

NS[1] = E
NS[2] = E.L
NS[3] = E.defaults.profile
NS[4] = E.defaults.global

E.Libs = {}
E.Libs.ACD = LibStub("AceConfigDialog-3.0-OmniCDC")
E.Libs.ACR = LibStub("AceConfigRegistry-3.0")
E.Libs.LSM = LibStub("LibSharedMedia-3.0")
E.Libs.OmniCDC = LibStub("LibOmniCDC")

E.Aura = CreateFrame("Frame")
LibStub("AceHook-3.0"):Embed(E.Aura)

local GetAddOnMetadata = C_AddOns.GetAddOnMetadata
E.Version = GetAddOnMetadata(AddOnName, "Version")
E.Author = GetAddOnMetadata(AddOnName, "Author")
E.Notes = GetAddOnMetadata(AddOnName, "Notes")
E.License = GetAddOnMetadata(AddOnName, "X-License")
E.Localizations = GetAddOnMetadata(AddOnName, "X-Localizations")
E.AddOn = AddOnName
E.userGUID = UnitGUID("player")
E.userClass = select(2, UnitClass("player"))
E.userClassHexColor = "|c" .. select(4, GetClassColor(E.userClass))
E.LoginMessage = E.userClassHexColor .. AddOnName .. " v" .. E.Version .. "|r - /oa"

_G.OmniAuras = {}
