---@type string, Addon
local _, addon = ...
local fsFrame = addon.WoW.Frame
local fsProviders = addon.Providers
local fsLog = addon.Logging.Log
local wowEx = addon.WoW.WowEx
local events = addon.WoW.Events
local M = {}
local useEvents = false
local containersChangedCallbacks = {}
local sortCallbacks = {}
local fsPlugin = nil
local pluginName = "FrameSort"

fsProviders.ElvUI = M
table.insert(fsProviders.All, M)

local function RequestSort(reason)
    for _, callback in ipairs(sortCallbacks) do
        callback(M, reason)
    end
end

local function RequestUpdateContainers()
    for _, callback in ipairs(containersChangedCallbacks) do
        callback(M)
    end
end

local function IntegrationEnabled()
    if not ElvUI then
        return false
    end

    local E = ElvUI[1]

    if not E or not E.db or not E.db.FrameSort then
        return true
    end

    return E.db.FrameSort.Enabled
end

local function ElvUiEnabled()
    return wowEx.IsAddOnEnabled("ElvUI")
end

local function OnHook(_, event)
    if not IntegrationEnabled() then
        return
    end

    RequestSort(event)
end

function M:Name()
    return "ElvUI"
end

function M:Enabled()
    return ElvUiEnabled() and IntegrationEnabled()
end

function M:RegisterRequestSortCallback(callback)
    if not callback then
        fsLog:Bug("ElvUI:RegisterRequestSortCallback() - callback must not be nil.")
        return
    end

    sortCallbacks[#sortCallbacks + 1] = callback
end

function M:RegisterContainersChangedCallback(callback)
    if not callback then
        fsLog:Bug("ElvUI:RegisterContainersChangedCallback() - callback must not be nil.")
        return
    end

    containersChangedCallbacks[#containersChangedCallbacks + 1] = callback
end

function M:ProcessEvent(event)
    if not useEvents then
        return
    end

    if event == events.GROUP_ROSTER_UPDATE then
        RequestSort(event)
    elseif event == events.PLAYER_ROLES_ASSIGNED then
        RequestSort(event)
    elseif event == events.PLAYER_SPECIALIZATION_CHANGED then
        RequestSort(event)
    elseif event == events.UNIT_PET then
        RequestSort(event)
    end
end

function M:Containers()
    local containers = {}

    if not ElvUiEnabled() then
        return containers
    end

    if ElvUF_PartyGroup1 then
        ---@type FrameContainer
        local party = {
            Frame = ElvUF_PartyGroup1,
            Type = fsFrame.ContainerType.Party,
            LayoutType = fsFrame.LayoutType.NameList,
        }

        containers[#containers + 1] = party
    end

    return containers
end

function M:Init()
    if not ElvUiEnabled() then
        return
    end

    if not ElvUI then
        fsLog:Bug("ElvUI is nil.")
        return
    end

    local E, _, _, P, _ = unpack(ElvUI)

    if not E then
        fsLog:Bug("ElvUI module handler is nil.")
        return
    end

    if not P then
        fsLog:Bug("ElvUI plugin handler is nil.")
        return
    end

    local EP = LibStub("LibElvUIPlugin-1.0", true)

    if not EP then
        fsLog:Bug("ElvUI plugin stub is nil.")
        return
    end

    local UF = E:GetModule("UnitFrames")

    if not UF then
        fsLog:Bug("ElvUI unit frames is nil.")
        return
    end

    fsPlugin = E:NewModule(pluginName, "AceHook-3.0")

    if not fsPlugin then
        fsLog:Bug("Failed to create ElvUI plugin module.")
        return
    end

    P[pluginName] = {
        ["Enabled"] = true,
    }

    function fsPlugin.Initialize()
        EP:RegisterPlugin(pluginName, fsPlugin.InsertOptions)

        fsPlugin:SecureHook(UF, "LoadUnits", function()
            if not ElvUF_PartyGroup1 then
                fsLog:Bug("Missing ElvUF_PartyGroup1.")

                useEvents = true
                return
            end

            fsLog:Debug("ElvUI loaded units, requesting container update.")
            RequestUpdateContainers()

            ElvUF_PartyGroup1:HookScript("OnEvent", OnHook)
        end)
    end

    function fsPlugin.InsertOptions()
        E.Options.args.FrameSort = {
            order = 100,
            type = "group",
            name = pluginName,
            args = {
                Enabled = {
                    order = 1,
                    type = "toggle",
                    name = "Enabled",
                    desc = "Enables/disables FrameSort integration.",
                    get = function(_)
                        return E.db.FrameSort.Enabled
                    end,
                    set = function(_, value)
                        E.db.FrameSort.Enabled = value
                    end,
                },
            },
        }
    end

    E:RegisterModule(pluginName)
end
