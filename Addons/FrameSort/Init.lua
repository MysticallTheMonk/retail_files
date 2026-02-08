---@type string, Addon
local addonName, addon = ...
local wow = addon.WoW.Api
local wowEx = addon.WoW.WowEx
local fsLog = addon.Logging.Log

function addon:InitDB()
    fsLog:Debug("Loading saved variables.")

    FrameSortDB = FrameSortDB or wow.CopyTable(addon.Configuration.DbDefaults)
    FrameSortDB.Options = FrameSortDB.Options or wow.CopyTable(addon.Configuration.DbDefaults.Options)

    local success = addon.Configuration.Upgrader:UpgradeDb(FrameSortDB)

    if not success then
        fsLog:Critical("Saved variables are corrupt, resetting to default settings.")

        FrameSortDB = wow.CopyTable(addon.Configuration.DbDefaults)
    end

    addon.DB = FrameSortDB
end

---Initialises the addon.
function addon:Init()
    fsLog:Init()
    fsLog:Debug("--- Initialising ---")

    addon:InitDB()
    addon.Locale:Init()

    local fsVersion = wow.GetAddOnMetadata(addonName, "Version")
    local expansionName, buildVersion = wowEx.ExpansionAndBuildInfo()
    fsLog:Debug("We are version %s running on %s build %s.", fsVersion, expansionName, buildVersion)

    addon.Configuration.Specs:Init()
    addon.Configuration:Init()
    addon.Modules:Init()
    addon.Providers:Init()
    addon.Api:Init()
    addon.Modules.EventDispatcher:Init()

    addon.Loaded = true
    fsLog:Debug("--- Initialisation finished ---")
end

---Listens for our to be loaded and then initialises it.
---@param name string the name of the addon being loaded.
local function OnLoadAddon(_, _, name)
    if name ~= addonName then
        return
    end

    addon:Init()
    addon.Loader:UnregisterEvent("ADDON_LOADED")
end

addon.Loader = wow.CreateFrame("Frame")
addon.Loader:SetScript("OnEvent", OnLoadAddon)
addon.Loader:RegisterEvent("ADDON_LOADED")

FrameSort = addon
