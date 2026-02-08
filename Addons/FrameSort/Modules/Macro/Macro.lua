---@type string, Addon
local _, addon = ...
local wow = addon.WoW.Api
local events = addon.WoW.Events
local fsScheduler = addon.Scheduling.Scheduler
local fsMacroParser = addon.Modules.Macro.Parser
local fsLog = addon.Logging.Log
local fsUnit = addon.WoW.Unit
local fsSortedUnits = addon.Modules.Sorting.SortedUnits
local fsEnumerable = addon.Collections.Enumerable
local isSelfEditingMacro = false
local eventFrame = nil
---@type table<number, boolean>
local isFsMacroCache = {}
---@class MacroModule: IInitialise
local M = addon.Modules.Macro
-- wow has 150 macro slots according to https://warcraft.wiki.gg/wiki/API_GetMacroInfo
M.MaxMacros = 150

local function FilterPets(units)
    return fsEnumerable
        :From(units)
        :Where(function(x)
            return not fsUnit:IsPet(x)
        end)
        :ToTable()
end

---@return boolean updated, boolean isFrameSortMacro, number newId
local function Rewrite(id, friendlyUnits, enemyUnits)
    local _, _, body = wow.GetMacroInfo(id)

    if not body or not fsMacroParser:IsFrameSortMacro(body) then
        return false, false, id
    end

    local newBody = fsMacroParser:GetNewBody(body, friendlyUnits, enemyUnits)

    if not newBody or body == newBody then
        return false, true, id
    end

    isSelfEditingMacro = true
    local newId = wow.EditMacro(id, nil, nil, newBody)
    isSelfEditingMacro = false

    return true, true, newId
end

local function UpdateMacro(id, friendlyUnits, enemyUnits, bypassCache)
    -- if we've already inspected this macro and it's not a framesort macro
    -- then skip attempting to re-process it
    local shouldInspect = bypassCache or isFsMacroCache[id] == nil or isFsMacroCache[id]

    if not shouldInspect then
        return false
    end

    friendlyUnits = friendlyUnits or FilterPets(fsSortedUnits:FriendlyUnits())
    enemyUnits = enemyUnits or FilterPets(fsSortedUnits:ArenaUnits())

    local updated, isFsMacro, newId = Rewrite(id, friendlyUnits, enemyUnits)
    isFsMacroCache[newId] = isFsMacro

    if id ~= newId then
        -- invalidate the cache if the id changed
        -- I believe the id only changes when the name or icon is updated which we don't touch
        -- but maybe that changes in the future, who knows
        isFsMacroCache = {}
    end

    return updated
end

local function ScanMacros()
    local start = wow.GetTimePreciseSec()
    local friendlyUnits = FilterPets(fsSortedUnits:FriendlyUnits())
    local enemyUnits = FilterPets(fsSortedUnits:ArenaUnits())
    local updatedCount = 0

    for id = 1, M.MaxMacros do
        local updated = UpdateMacro(id, friendlyUnits, enemyUnits, false)

        if updated then
            updatedCount = updatedCount + 1
        end
    end

    local stop = wow.GetTimePreciseSec()
    fsLog:Debug("Update macros took %fms, %d updated.", (stop - start) * 1000, updatedCount)
end

local function OnEditMacro(id, _, _, _)
    -- prevent recursion from EditMacro hook
    if isSelfEditingMacro then
        return
    end

    fsScheduler:RunWhenCombatEnds(function()
        local updated = UpdateMacro(id, nil, nil, true)

        if updated then
            fsLog:Debug("Updated macro: %s", id)
        end
    end, "EditMacro" .. id)
end

local function OnUpdateMacros()
    -- if the event was triggered by us, then ignore it
    if isSelfEditingMacro then
        return
    end

    -- someone else has edited a macro
    -- invalidate our cache as ids may have all completely changed
    -- macro "ids" aren't really an id, just the index they are visually displayed in the macro window
    -- therefore simply creating or deleting 1 macro can change a lot of ids
    isFsMacroCache = {}
end

function M:Run()
    if wow.InCombatLockdown() then
        fsLog:Error("Cannot run macro module during combat.")
        return
    end

    ScanMacros()
end

function M:Init()
    if #isFsMacroCache > 0 then
        isFsMacroCache = {}
    end

    wow.hooksecurefunc("EditMacro", OnEditMacro)

    eventFrame = wow.CreateFrame("Frame")
    eventFrame:SetScript("OnEvent", OnUpdateMacros)
    eventFrame:RegisterEvent(events.UPDATE_MACROS)

    fsLog:Debug("Initialised the macro module.")
end
