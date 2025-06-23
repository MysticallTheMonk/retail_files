local _, ArenaAnalytics = ...; -- Addon Namespace
local FilterTables = ArenaAnalytics.FilterTables;

-- Local module aliases
local API = ArenaAnalytics.API;
local Filters = ArenaAnalytics.Filters;

-------------------------------------------------------------------------


FilterTables.brackets = {}

local function GetCurrentBracketName(dropdownContext)
    assert(dropdownContext, "Nil dropdownContext.");
    assert(dropdownContext.key, "dropdownContext is missing a key for func FilterTables.GetCurrentFilterValue. Make sure your table specify one.");

    local currentValue = Filters:Get(dropdownContext.key);
    if(currentValue == 0 or currentValue == "All") then
        return "All";
    end

    local brackets = API.availableBrackets or {};
    for _,data in pairs(brackets) do
        if(data and data.key == currentValue) then
            return data.name;
        end
    end
    return "";
end

local function AddBracket(bracket)
    tinsert(FilterTables.brackets.entries, {
        label = bracket.name or bracket,
        alignment = "CENTER",
        fontSize = 12,
        key = "Filter_Bracket",
        value = bracket.key,
        onClick = FilterTables.SetFilterValue,
    })
end

function FilterTables:Init_Brackets()
    FilterTables.brackets = { 
        mainButton = {
            label = GetCurrentBracketName,
            alignment = "CENTER",
            fontSize = 12,
            key = "Filter_Bracket",
            onClick = FilterTables.ResetFilterValue,
        },
        entries = {}
    }

    AddBracket("All");

    local brackets = API.availableBrackets or {};
    for _,bracket in ipairs(brackets) do
        AddBracket(bracket);
    end
end

