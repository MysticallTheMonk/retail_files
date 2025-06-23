local addonName, addon = ...; -- Global addon namespace
addon.Libs = {}; -- Global library names table
local libs = addon.Libs; -- Local library names table

libs.AceLocale = "AceLocale-3.0";
-- libs.AceEvent = "AceEvent-3.0";
libs.Krowi_Util = "Krowi_Util-1.0";

-- [[ Personal libraries ]] --
addon.Util = LibStub(addon.Libs.Krowi_Util);
addon.Metadata = addon.Util.Metadata.GetAddOnMetadata(addonName);