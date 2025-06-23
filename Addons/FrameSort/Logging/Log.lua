local _, addon = ...
local logLevelDebug = "Debug"
local logLevelWarning = "Warning"
local logLevelError = "Error"
---@class Log
local M = {}
addon.Logging.Log = M

local function Write(msg, level)
    local enabled = addon.DB and addon.DB.Options and addon.DB.Options.Logging and addon.DB.Options.Logging.Enabled
    if not enabled then
        return
    end

    print(string.format("FrameSort: %s - %s", level, msg))
end

---Logs a debug message.
---@param msg string
function M:Debug(msg)
    Write(msg, logLevelDebug)
end

---Logs a warning message.
---@param msg string
function M:Warning(msg)
    Write(msg, logLevelWarning)
end

---Logs an error message.
---@param msg string
function M:Error(msg)
    Write(msg, logLevelError)
end
