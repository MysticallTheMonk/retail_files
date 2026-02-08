local name,addon = ...;
local tsv = LibStub("AceAddon-3.0"):NewAddon("TrueStatValues", "AceConsole-3.0", "AceEvent-3.0")



--[[----------------------------------------------------------------------------
Defaults
------------------------------------------------------------------------------]]
local function Color(r,g,b,a)
	local t = {};
	t.r = r;
	t.g = g;
	t.b = b;
	t.a = a or 1;
	return t;
end

local defaults = {
	global = {
		showStatTooltips=true,
		showItemTooltips=true,
		fontColor=Color(68/255,173/255,255/255,1),
    }
}

local num_pattern = "%.2f";


--[[----------------------------------------------------------------------------
Options
------------------------------------------------------------------------------]]
local _TEST=nil;
local options = {
	name = "True Stat Values",
	handler = tsv,
	childGroups = "tab",
	type = "group",
	args = {
		optionsTab = { 
			name = "Options",
			type = "group",
			order = 1,
			args = {
				headerSettings = {
					name = "True Stat Value Settings",
					desc = "",
					type = "header",
					order = 1
				},
				showStatTooltips = {
					name = "Stat Tooltips",
					desc = "When checked, displays True Stat Rating information on Secondary-Stat tooltips.",
					type = "toggle",
					order = 3,
					width = "full",
					get = function(info) return tsv.db.global.showStatTooltips end,
					set = function(info,val) tsv.db.global.showStatTooltips = val; end
				},
				showItemTooltips = {
					name = "Item Tooltips",
					desc = "When checked, displays True Stat Rating information on Item tooltips.",
					type = "toggle",
					order = 5,
					width = "full",
					get = function(info) return tsv.db.global.showItemTooltips end,
					set = function(info,val) tsv.db.global.showItemTooltips = val; end
                },
				fontColor = {
					name = "Font Color",
					type = "color",
					order = 7,
					get = function(info) return tsv.db.global.fontColor.r,tsv.db.global.fontColor.g,tsv.db.global.fontColor.b,tsv.db.global.fontColor.a end,
					set = function(info,r,g,b,a) 
						tsv.db.global.fontColor = Color(r,g,b,a); --ignore alpha?
					end
				},
			}
		},
	}
}
local BlizOptionsTable = {
	name = "True Stat Values",
	type = "group",
	args = options
}



--[[----------------------------------------------------------------------------
Addon Initialized
------------------------------------------------------------------------------]]
function tsv:OnInitialize()
    self.db = LibStub("AceDB-3.0"):New("TSV_DB", defaults)
	LibStub("AceConfigRegistry-3.0"):RegisterOptionsTable("TSV_Bliz",options);
	self.optionsFrame = LibStub("AceConfigDialog-3.0"):AddToBlizOptions("TSV_Bliz", "True Stat Values");

	local tooltipEvents = {
        "OnShow"
    };

	C_Timer.After(0.2,function()
		for k,v in ipairs(tooltipEvents) do
			GameTooltip:HookScript(v,function(tooltip,...)
				tsv:OnTooltip(v,tooltip,...)
			end);
		end
	end);
end



local function OnTooltipSetItem(tooltip, data)
    if tooltip == GameTooltip then
		tsv:OnTooltip("OnTooltipSetItem", tooltip)
    end
end

local function OnTooltipSetSpell(tooltip, data)
    if tooltip == GameTooltip then
		tsv:OnTooltip("OnTooltipSetSpell",tooltip)
    end
end

TooltipDataProcessor.AddTooltipPostCall(Enum.TooltipDataType.Item, OnTooltipSetItem)
TooltipDataProcessor.AddTooltipPostCall(Enum.TooltipDataType.Spell, OnTooltipSetSpell)

addon.SegmentLabels = SegmentLabels;
addon.tsv = tsv;