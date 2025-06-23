---@type string, Addon
local addonName, addon = ...
local wow = addon.WoW.Api
local loader = nil

function addon:InitLocale()
    local function DefaultIndex(_, key)
        -- if there is no translation specified, then use the the key itself
        return key
    end

    setmetatable(addon.Locale, { __index = DefaultIndex })
end

function addon:InitDB()
    FrameSortDB = FrameSortDB or {}
    FrameSortDB.Options = FrameSortDB.Options or wow.CopyTable(addon.Configuration.Defaults)

    addon.DB = FrameSortDB
    addon.Configuration.Upgrader:UpgradeOptions(addon.DB.Options)
end

---Initialises the addon.
function addon:Init()
    addon:InitLocale()
    addon:InitDB()
    addon.Configuration:Init()
    addon.Providers:Init()
    addon.Modules:Init()
    addon.Api:Init()
    addon.Scheduling.Scheduler:Init()

    addon.Loaded = true
end

---Listens for our to be loaded and then initialises it.
---@param name string the name of the addon being loaded.
local function OnLoadAddon(_, _, name)
    if name ~= addonName then
        return
    end

    assert(loader)

    addon:Init()
    loader:UnregisterEvent("ADDON_LOADED")
end

loader = wow.CreateFrame("Frame")
loader:HookScript("OnEvent", OnLoadAddon)
loader:RegisterEvent("ADDON_LOADED")

FrameSort = addon
