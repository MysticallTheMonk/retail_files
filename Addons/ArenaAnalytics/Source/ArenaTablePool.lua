local _, ArenaAnalytics = ... -- Namespace
local TablePool = ArenaAnalytics.TablePool;

-- Local module aliases
local Helpers = ArenaAnalytics.Helpers;

-------------------------------------------------------------------------

local MAX_POOL_SIZE = 25;  -- Set a reasonable limit for your case

function TablePool:Release(tbl)
    if tbl then
        -- Clear all data
        for k in pairs(tbl) do
            tbl[k] = nil;
        end

        -- Only add the table if the pool hasn't reached max size
        if #self < MAX_POOL_SIZE then
            table.insert(self, tbl);
        end
    end
end

function TablePool:ReleaseNested(tbl)
    if tbl then
        -- Clear all data
        for k,v in pairs(tbl) do
            if(type(v) == "table") then
                self:Release(v);
            end
            tbl[k] = nil;
        end

        -- Only add the table if the pool hasn't reached max size
        if #self < MAX_POOL_SIZE then
            table.insert(self, tbl);
        end
    end
end

function TablePool:Clear(tbl)
    if(tbl) then
        for k,v in pairs(tbl) do
            if(type(v) == "table") then
                self:ReleaseNested(v);
            end
            tbl[k] = nil;
        end
    end
end

-- Acquire a table from the pool or create a new one
function TablePool:Acquire()
    if #self > 0 then
        return table.remove(self)
    else
        return {}
    end
end