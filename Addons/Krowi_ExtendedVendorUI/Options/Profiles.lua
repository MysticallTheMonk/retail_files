local _, addon = ...;
local options = addon.Options;
options.Profiles = {};
local profiles = options.Profiles;
tinsert(options.OptionsTables, profiles);

local OrderPP = addon.InjectOptions.AutoOrderPlusPlus;
local AdjustedWidth = addon.InjectOptions.AdjustedWidth;

function profiles.RegisterOptionsTable()
    options.OptionsTable.args.Profiles.args.Options = LibStub("AceDBOptions-3.0"):GetOptionsTable(addon.Options.db);
    options.OptionsTable.args.Profiles.args.Options.order = OrderPP();
    options.OptionsTable.args.Profiles.args.Options.name = addon.L["Options"];

    addon.Filters:Load();
    options.OptionsTable.args.Profiles.args.Filters = LibStub("AceDBOptions-3.0"):GetOptionsTable(addon.Filters.db);
    options.OptionsTable.args.Profiles.args.Filters.order = OrderPP();
    options.OptionsTable.args.Profiles.args.Filters.name = addon.L["Filters"];

    LibStub("AceConfig-3.0"):RegisterOptionsTable(addon.Metadata.Prefix .. "_Profiles", options.OptionsTable.args.Profiles);
    LibStub("AceConfigDialog-3.0"):AddToBlizOptions(addon.Metadata.Prefix .. "_Profiles", addon.Util.L["Profiles"], addon.Metadata.Title);
end

options.OptionsTable.args["Profiles"] = {
    type = "group", childGroups = "tab",
    name = addon.Util.L["Profiles"],
    args = {}
};