local _, NS = ...

-- luacheck: push ignore
--[==[@debug@
NS.Debug = function(...)
    if false then print("|cFFFF0000[D]|r" .. format(...)) end
end

NS.Info = function(...)
    if false then print("|cFFFF0000[I]|r" .. format(...)) end
end
--@end-debug@]==]
-- luacheck: pop

-- Copies table values from src to dst if they don't exist in dst
NS.CopyDefaults = function(src, dst)
    if type(src) ~= "table" then return {} end
    if type(dst) ~= "table" then dst = {} end

    for k, v in pairs(src) do
        if type(v) == "table" then
            dst[k] = NS.CopyDefaults(v, dst[k])
        elseif type(v) ~= type(dst[k]) then
            dst[k] = v
        end
    end

    return dst
end

-- Cleanup savedvariables by removing table values in src that no longer
-- exists in table dst (default settings)
NS.CleanupDB = function(src, dst)
    for key, value in pairs(src) do

        if dst[key] == nil then
            -- HACK: offsetsXY are not set in DEFAULT_SETTINGS but sat on demand instead to save memory,
            -- which causes nil comparison to always be true here, so always ignore these for now
            if key ~= "offsetsX" and key ~= "offsetsY" and key ~= "version" then
                src[key] = nil
            end
        elseif type(value) == "table" then
            if key ~= "disabledCategories" and key ~= "categoryTextures" then -- also sat on demand
                dst[key] = NS.CleanupDB(value, dst[key])
            end
        end
    end
    return dst
end

-- Find debuff duration by aura indices
local UnitAura = _G.UnitAura
NS.GetAuraDuration = function(unitID, spellID)
    if not unitID or not spellID then return end

    for i = 1, 40 do
        local _, _, _, _, duration, expirationTime, _, _, _, id = C_UnitAuras.GetAuraDataByIndex(unitID, i, "HARMFUL")
        if not id then return end -- no more debuffs

        if spellID == id then
            return duration, expirationTime
        end
    end
end

-- Pool for reusing tables. (Garbage collector isn't ran in combat unless max garbage is reached, which causes fps drops)
do
    local pool = {}
    local wipe = _G.table.wipe
    local next = _G.next

    NS.NewTable = function()
        local t = next(pool) or {}
        pool[t] = nil -- remove from pool

        return t
    end

    NS.RemoveTable = function(tbl)
        if tbl then
            pool[wipe(tbl)] = true -- add to pool, wipe returns pointer to tbl here
        end
    end

    NS.ReleaseTables = function()
        if next(pool) then
            pool = {}
        end
    end
end
