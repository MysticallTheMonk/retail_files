local _, addonTable = ...
addonTable.callbackRegistry = {}
local CR = addonTable.callbackRegistry

local next = next

local status_events = {}
local callbacks = {}

local counter = 0 
local function generateID()
    counter = counter + 1
    return counter
end

function CR:RegisterCallback(event, callback)
    if not callbacks[event] then
        self:StartStatus(event)
    end
    if not callbacks[event] then
        callbacks[event] = {}
    end
    local ID = generateID()
    callbacks[event][ID] = callback
    return ID
end

function CR:UnregisterCallback(event, ID)
    if not callbacks[event] then
        return
    end
    callbacks[event][ID] = nil
    if next(callbacks[event]) == nil then
        callbacks[event] = nil
        self:StopStatus(event)
    end
end

function CR:Fire(event, ...)  
    if not callbacks[event] then
        return
    end
    for ID, callback in next, callbacks[event] do
        callback(...)
    end
end

--[[
    Staus
]]
function CR:RegisterStatusEvent(event, status_module)
    status_events[event] = status_module
end

function CR:StartStatus(event, options)
    local status_module = status_events[event]
    if status_module then
        status_module:Start(event)
        status_module.enabled = true
    end
end

function CR:StopStatus(event, options)
    local status_module = status_events[event]
    if status_module then
        status_module:Stop(event)
        status_module.enabled = false
    end
end

--@TODO could need improvements to restore previous state but not a big deal
function CR:RestartStatus(event)
    local status_module = status_events[event]
    if not status_module then 
        return
    end
    if status_module.enabled then
        status_module:Stop(event)
        status_module:Start(event)
    end
end