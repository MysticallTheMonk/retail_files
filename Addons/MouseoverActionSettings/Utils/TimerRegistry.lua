local _, addonTable = ...
addonTable.timerRegistry = {}
local Timer = addonTable.timerRegistry

local C_Timer_After = C_Timer.After

local timers = {}

function Timer:Start(seconds, callback)
    local timer = {}
    timer.delay = seconds
    timer.callback = function()
        if timer.stopped then
            return
        end
        callback()
    end
    timers[timer] = timer
    C_Timer_After(seconds, timer.callback)
    return timer
end

function Timer:Stop(timer)
    if not timers[timer] then
        return
    end
    timers[timer].stopped = true
end