---@type string, Namespace
local _, ns = ...

---@class Constants
local constants = {}
ns.constants = constants

---@type UnitType[]
constants.unitTypes = {
    "player",
}

constants.IsMidnight = (select(4, GetBuildInfo()) >= 120000);

if not constants.IsMidnight then
    table.insert(constants.unitTypes, "party1");
    table.insert(constants.unitTypes, "party2");
    table.insert(constants.unitTypes, "party3");
    table.insert(constants.unitTypes, "party4");
    table.insert(constants.unitTypes, "arena1");
    table.insert(constants.unitTypes, "arena2");
    table.insert(constants.unitTypes, "arena3");
    table.insert(constants.unitTypes, "target");
    table.insert(constants.unitTypes, "focus");
end

---@type LayoutType[]
constants.layoutTypes = {
    "player",
}

if not constants.IsMidnight then
    table.insert(constants.layoutTypes, "party");
    table.insert(constants.layoutTypes, "arena");
    table.insert(constants.layoutTypes, "target");
    table.insert(constants.layoutTypes, "focus");
end
