---@type string, Addon
local _, addon = ...
local wow = addon.WoW.Api
local fsFrame = addon.WoW.Frame
local fsProviders = addon.Providers
local fsLog = addon.Logging.Log
local M = {}
local containersChangedCallbacks = {}
local fsPlugin = nil
local pluginName = "FrameSort"

fsProviders.ElvUI = M
table.insert(fsProviders.All, M)

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

local function PluginEnabled()
    return wow.GetAddOnEnableState(nil, "ElvUI") ~= 0 and ElvUI ~= nil
end

local function RequestUpdateContainers()
    for _, callback in ipairs(containersChangedCallbacks) do
        callback(M)
    end
end

function M:Name()
    return "ElvUI"
end

function M:Enabled()
    return PluginEnabled() and IntegrationEnabled()
end

function M:Init()
    if not PluginEnabled() then
        return
    end

    local E, _, _, P, _ = unpack(ElvUI)
    local EP = LibStub("LibElvUIPlugin-1.0")
    local UF = E:GetModule("UnitFrames")

    fsPlugin = E:NewModule(pluginName, "AceHook-3.0")

    P[pluginName] = {
        ["Enabled"] = true,
    }

    function fsPlugin:Initialize()
        EP:RegisterPlugin(pluginName, fsPlugin.InsertOptions)

        fsPlugin:SecureHook(UF, "LoadUnits", function()
            if not ElvUF_PartyGroup1 then
                fsLog:Error("ElvUF_PartyGroup1 container is nil")
                return
            end

            RequestUpdateContainers()
        end)
    end

    function fsPlugin:InsertOptions()
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

function M:RegisterRequestSortCallback(_) end

function M:RegisterContainersChangedCallback(callback)
    containersChangedCallbacks[#containersChangedCallbacks + 1] = callback
end

function M:Containers()
    if not ElvUF_PartyGroup1 then
        return {}
    end

    ---@type FrameContainer
    local party = {
        Frame = ElvUF_PartyGroup1,
        Type = fsFrame.ContainerType.Party,
        LayoutType = fsFrame.LayoutType.NameList,
    }

    return {
        party,
    }
end
