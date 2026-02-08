---@type string, Addon
local addonName, addon = ...
local wow = addon.WoW.Api
local events = addon.WoW.Events
local L = addon.Locale.Current
---@class Log
local M = {
    Level = {
        Debug = 1,
        Notify = 2,
        Warning = 3,
        Error = 4,
        Critical = 5,
        Bug = 6,
    },
}
addon.Logging.Log = M

local defaultMax = 5000
local started = wow.GetTimePreciseSec()
local warningsNotified = {}
local errorsNotified = {}
local bugsNotified = {}
local callbacks = {}

local levelText = {
    [M.Level.Debug] = "Debug",
    [M.Level.Notify] = "Notify",
    [M.Level.Warning] = "Warning",
    [M.Level.Error] = "Error",
    [M.Level.Critical] = "Critical",
    [M.Level.Bug] = "Bug",
}

local function NotifyCallbacks(msg, level, timestamp)
    for i = 1, #callbacks do
        local cb = callbacks[i]

        if cb then
            local ok, err = pcall(cb, msg, level, timestamp)

            if not ok then
                -- avoid infinite recursion: don't call Write() here
                print(("|cFFFF0000FrameSort - Log callback error: %s.|r"):format(err or "Unknown"))
            end
        end
    end
end

local function LogPush(db, entry)
    local fallbackMax = addon.Configuration.DbDefaults.Log.Max or defaultMax

    db.Buffer = db.Buffer or {}
    db.Max = tonumber(db.Max) or fallbackMax
    db.Head = tonumber(db.Head) or 1
    db.Size = tonumber(db.Size) or 0

    -- the below shouldn't happen unless someone corrupts our saved variables
    if db.Max < 1 then
        db.Max = fallbackMax
    end
    if db.Head < 1 then
        db.Head = 1
    end
    if db.Size < 0 then
        db.Size = 0
    end
    if db.Head > db.Max then
        db.Head = 1
    end
    if db.Size > db.Max then
        db.Size = db.Max
    end

    local buf = db.Buffer
    local max = db.Max

    buf[db.Head] = entry
    db.Head = (db.Head % max) + 1
    db.Size = math.min(db.Size + 1, max)
end

local function Write(msg, level)
    local ts = wow.GetTimePreciseSec() - started
    NotifyCallbacks(msg, level, ts)

    -- addon.DB may not have been inititalised yet, so use the global
    if FrameSortDB then
        FrameSortDB.Log = FrameSortDB.Log or wow.CopyTable(addon.Configuration.DbDefaults.Log)

        local entry = {
            Message = msg,
            Level = level,
            Timestamp = ts,
        }

        LogPush(FrameSortDB.Log, entry)
    end

    if level == M.Level.Notify then
        print(string.format("FrameSort - %s", msg))
    elseif level == M.Level.Critical or level == M.Level.Bug then
        print(string.format("|cFFFF0000FrameSort - %s|r", msg))
    end
end

local function OnAddonError(_, eventName, errorAddon, error)
    if errorAddon ~= addonName then
        return
    end

    if not error then
        return
    end

    local errorText = ("%s: %s"):format(eventName or "Unknown", tostring(error))

    Write(errorText, M.Level.Error)
end

---Iterates over the database log entries and invokes the callback for each log entry.
---@param fn function()
function M:IterateLog(fn)
    if not FrameSortDB then
        return
    end

    if not FrameSortDB.Log then
        return
    end

    local db = FrameSortDB.Log
    local buffer = db.Buffer
    local count = tonumber(db.Size)
    local head = tonumber(db.Head)
    local max = tonumber(db.Max)

    if not buffer or not count or not head or not max then
        return
    end

    if count == 0 then
        return
    end

    -- protect against saved variables corruption
    if max < 1 then
        max = defaultMax
    end
    if head < 1 or head > max then
        head = 1
    end
    if count < 0 then
        count = 0
    end
    if count > max then
        count = max
    end

    -- Oldest entry is count steps behind the current head
    local firstIndex = head - count

    if firstIndex <= 0 then
        firstIndex = firstIndex + max
    end

    for offset = 0, count - 1 do
        local index = firstIndex + offset
        if index > max then
            index = index - max
        end

        local entry = buffer[index]

        if entry then
            fn(entry)
        end
    end
end

---Returns a text representation of the log level.
function M:LevelText(level)
    return levelText[level] or "Unknown"
end

---Logs a debug message.
---@param msg string
function M:Debug(msg, ...)
    local formatted = string.format(msg, ...)
    Write(formatted, M.Level.Debug)
end

---Logs and prints a notification message.
---@param msg string
function M:Notify(msg, ...)
    local formatted = string.format(msg, ...)
    Write(formatted, M.Level.Notify)
end

---Logs and prints the combat lockdown notification message.
function M:NotifyCombatLockdown()
    self:Notify(L["Can't do that during combat."])
end

---Logs a warning message.
---@param msg string
function M:Warning(msg, ...)
    local formatted = string.format(msg, ...)
    Write(formatted, M.Level.Warning)
end

---Logs a warning message if one hasn't already been logged with the same message.
---@param msg string
function M:WarnOnce(msg, ...)
    local formatted = string.format(msg, ...)

    if warningsNotified[formatted] then
        return
    end

    warningsNotified[formatted] = true

    Write(formatted, M.Level.Warning)
end

---Logs an error message if one hasn't already been logged with the same message.
---@param msg string
function M:ErrorOnce(msg, ...)
    local formatted = string.format(msg, ...)

    if errorsNotified[formatted] then
        return
    end

    errorsNotified[formatted] = true

    Write(formatted, M.Level.Error)
end

---Logs an error message.
---@param msg string
function M:Error(msg, ...)
    local formatted = string.format(msg, ...)
    Write(formatted, M.Level.Error)
end

---Logs and prints a critical error message.
---@param msg string
function M:Critical(msg, ...)
    local formatted = string.format(msg, ...)
    Write(formatted, M.Level.Critical)
end

---Logs and prints a critical error bug message.
---@param msg string
function M:Bug(msg, ...)
    local formatted = string.format(msg, ...)

    if bugsNotified[formatted] then
        return
    end

    bugsNotified[formatted] = true

    Write(formatted .. " Please notify the developer about this.", M.Level.Bug)
end

---Logs a message.
---@param msg string
function M:Log(msg, level, ...)
    local formatted = string.format(msg, ...)
    Write(formatted, level)
end

---Adds a callback to be invoked whenever a log entry is added.
---@param callback function
function M:AddLogCallback(callback)
    callbacks[#callbacks + 1] = callback
end

function M:Init()
    local frame = wow.CreateFrame("Frame")
    frame:SetScript("OnEvent", OnAddonError)
    frame:RegisterEvent(events.ADDON_ACTION_BLOCKED)
    frame:RegisterEvent(events.ADDON_ACTION_FORBIDDEN)
end
