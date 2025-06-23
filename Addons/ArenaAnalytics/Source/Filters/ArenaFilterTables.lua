local _, ArenaAnalytics = ...; -- Addon Namespace
local FilterTables = ArenaAnalytics.FilterTables;

-- Local module aliases
local API = ArenaAnalytics.API;
local Filters = ArenaAnalytics.Filters;

-------------------------------------------------------------------------


-- Initialize all tables
function FilterTables:Init()
    FilterTables:Init_Brackets();
    FilterTables:Init_Comps();
    FilterTables:Init_MoreFilters();
end

---------------------------------
-- Helpers
---------------------------------

function FilterTables.GetCurrentFilterValue(dropdownContext)
    assert(dropdownContext, "Nil dropdownContext.");
    assert(dropdownContext.key, "dropdownContext is missing a key for func FilterTables.GetCurrentFilterValue. Make sure your table specify one.");

    return Filters:Get(dropdownContext.key);
end

function FilterTables.SetFilterValue(dropdownContext, btn)
    if(btn == "RightButton") then
        Filters:Reset(dropdownContext.key);
    else
        Filters:Set(dropdownContext.key, (dropdownContext.value or dropdownContext.label));
    end
end

function FilterTables.IsFilterEntryChecked(dropdownContext)
    assert(dropdownContext ~= nil, "Invalid contextFrame");

    return Filters:Get(dropdownContext.key) == (dropdownContext.value or dropdownContext.label);
end

function FilterTables.IsFilterActive(dropdownContext)
    assert(dropdownContext.key)
    return Filters:IsFilterActive(dropdownContext.key);
end

function FilterTables.ResetFilterValue(dropdownContext, btn)
    assert(dropdownContext.key ~= nil, "Failed to get key for: " .. dropdownContext:GetName());

    if(btn == "RightButton") then
        Filters:Reset(dropdownContext.key, true);
        dropdownContext:Hide();
    else
        dropdownContext.parent:Toggle();
    end
end
