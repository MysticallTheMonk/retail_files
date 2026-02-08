---@type string, Addon
local _, addon = ...
local mini = addon.Core.Framework
local scheduler = addon.Utils.Scheduler
local frames = addon.Core.Frames
local config = addon.Config
local testModeManager = addon.Modules.TestModeManager
local modules = {
	addon.Modules.CcModule,
	addon.Modules.HealerCcModule,
	addon.Modules.PortraitModule,
	addon.Modules.AlertsModule,
	addon.Modules.NameplatesModule,
	addon.Modules.KickTimerModule,
	addon.Modules.TrinketsModule,
}
local eventsFrame
local db

local function NotifyChanges()
	if db.NotifiedChanges then
		return
	end

	local title = "MiniCC - What's New?"
	db.NotifiedChanges = true

	if db.Version == 6 then
		mini:ShowDialog({
			Title = title,
			Text = table.concat(db.WhatsNew, "\n"),
		})
	elseif db.Version == 7 then
		mini:ShowDialog({
			Title = title,
			Text = table.concat({
				"- CC icons in player/target/focus portraits (beta only).",
				"- New option to colour the glow based on the dispel type.",
			}, "\n"),
		})
	elseif db.Version == 8 then
		mini:ShowDialog({
			Title = title,
			Text = table.concat({
				"- Portrait icons now supported in prepatch (was beta only).",
				"- Included important spells (defensives/offensives) in portrait icons, not just CC.",
			}, "\n"),
		})
	elseif db.Version == 9 then
		mini:ShowDialog({
			Title = title,
			Text = "- New spell alerts bar that shows enemy cooldowns.",
		})
	elseif db.Version >= 10 then
		local whatsNew = db.WhatsNew

		if not whatsNew then
			return
		end

		mini:ShowDialog({
			Title = title,
			Text = table.concat(whatsNew, "\n"),
		})
	end

	db.WhatsNew = {}
end

local function OnEvent(_, event)
	if event == "PLAYER_REGEN_DISABLED" then
		if testModeManager:IsEnabled() then
			testModeManager:Disable()
			addon:Refresh()
		end
	end

	if event == "PLAYER_ENTERING_WORLD" then
		NotifyChanges()
		addon:Refresh()
	end
end

local function OnAddonLoaded()
	config:Init()
	scheduler:Init()
	frames:Init()

	for _, module in ipairs(modules) do
		module:Init()
	end

	testModeManager:Init()

	eventsFrame = CreateFrame("Frame")
	eventsFrame:SetScript("OnEvent", OnEvent)
	eventsFrame:RegisterEvent("PLAYER_REGEN_DISABLED")
	eventsFrame:RegisterEvent("PLAYER_ENTERING_WORLD")

	db = mini:GetSavedVars()
end

function addon:Refresh()
	if InCombatLockdown() then
		scheduler:RunWhenCombatEnds(function()
			addon:Refresh()
		end, "Refresh")
		return
	end

	for _, module in ipairs(modules) do
		module:Refresh()
	end

	if testModeManager:IsEnabled() then
		testModeManager:Show()
	else
		testModeManager:Hide()
	end
end

---@param options InstanceOptions?
function addon:ToggleTest(options)
	if testModeManager:IsEnabled() then
		testModeManager:Disable()
	else
		testModeManager:Enable(options)
	end

	addon:Refresh()

	if InCombatLockdown() then
		mini:Notify("Can't test during combat, we'll test once combat drops.")
	end
end

---@param options InstanceOptions?
function addon:TestOptions(options)
	testModeManager:SetOptions(options)

	if testModeManager:IsEnabled() then
		addon:Refresh()
	end
end

mini:WaitForAddonLoad(OnAddonLoaded)

---@class Addon
---@field Capabilities Capabilities
---@field Utils Utils
---@field Core Core
---@field Config Config
---@field Modules Modules
---@field Refresh fun(self: table)
---@field ToggleTest fun(self: table, options: InstanceOptions)
---@field TestOptions fun(self: table, options: InstanceOptions)

---@class Utils
---@field CcUtil CcUtil
---@field Scheduler SchedulerUtil
---@field Units UnitUtil
---@field Array ArrayUtil

---@class Core
---@field Framework MiniFramework
---@field Frames Frames
---@field UnitAuraWatcher UnitAuraWatcher
---@field IconSlotContainer IconSlotContainer
---@field CcHeader CcHeader

---@class Modules
---@field TestModeManager TestModeManager
---@field PortraitModule PortraitModule
---@field HealerCcModule HealerCcModule
---@field NameplatesModule NameplatesModule
---@field KickTimerModule KickTimerModule
---@field AlertsModule AlertsModule
---@field CcModule CcModule
---@field TrinketsModule TrinketsModule

---@class IModule
---@field Init fun(self: IModule)
---@field Refresh fun(self: IModule)
---@field Pause fun(self: IModule)
---@field Resume fun(self: IModule)
