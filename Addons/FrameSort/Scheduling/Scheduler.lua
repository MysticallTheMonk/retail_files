---@type string, Addon
local _, addon = ...
local wow = addon.WoW.Api
local events = addon.WoW.Api.Events
---@class Scheduler: IInitialise
local M = {}
addon.Scheduling.Scheduler = M

local eventFrame = nil
local enteringWorldCallbacks = {}
local combatEndCallbacks = {}
local combatEndKeyedCallbacks = {}

local function OnCombatEnded()
    for _, callback in ipairs(combatEndCallbacks) do
        callback()
    end

    for _, callback in pairs(combatEndKeyedCallbacks) do
        callback()
    end

    combatEndCallbacks = wow.wipe(combatEndCallbacks)
    combatEndKeyedCallbacks = wow.wipe(combatEndKeyedCallbacks)
end

local function OnEnteringWorld()
    for _, callback in pairs(enteringWorldCallbacks) do
        callback()
    end
end

local function OnEvent(_, event)
    assert(event ~= nil)

    if event == events.PLAYER_ENTERING_WORLD then
        OnEnteringWorld()
    elseif event == events.PLAYER_REGEN_ENABLED then
        OnCombatEnded()
    end
end

---Invokes the callback on the next frame.
---@param callback fun()
function M:RunNextFrame(callback)
    wow.C_Timer.After(0, callback)
end

--- invokes the callback after the specified number of seconds.
---@param callback fun()
---@param seconds number
function M:RunAfter(seconds, callback)
    wow.C_Timer.After(seconds, callback)
end

---Invokes the callback once combat ends.
---@param key string? an optional key which will ensure only the latest callback provided with the same key will be executed.
---@param callback fun()
function M:RunWhenCombatEnds(callback, key)
    if not wow.InCombatLockdown() then
        callback()
        return
    end

    if key then
        combatEndKeyedCallbacks[key] = callback
    else
        combatEndCallbacks[#combatEndCallbacks + 1] = callback
    end
end

function M:RunWhenEnteringWorld(callback)
    enteringWorldCallbacks[#enteringWorldCallbacks + 1] = callback
end

function M:Init()
    eventFrame = wow.CreateFrame("Frame")
    eventFrame:HookScript("OnEvent", OnEvent)
    eventFrame:RegisterEvent(events.PLAYER_REGEN_ENABLED)
    eventFrame:RegisterEvent(events.PLAYER_ENTERING_WORLD)
end
