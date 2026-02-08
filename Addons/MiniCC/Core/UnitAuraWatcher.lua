---@type string, Addon
local _, addon = ...
local capabilities = addon.Capabilities
local maxAuras = 40
local ccFilter = capabilities:HasNewFilters() and "HARMFUL|CROWD_CONTROL" or "HARMFUL|INCLUDE_NAME_PLATE_ONLY"
local importantHelpfulFilter = capabilities:HasNewFilters() and "HELPFUL|IMPORTANT" or "HELPFUL|INCLUDE_NAME_PLATE_ONLY"
local importantHarmfulFilter = capabilities:HasNewFilters() and "HARMFUL|IMPORTANT" or "HARMFUL|INCLUDE_NAME_PLATE_ONLY"

---@class UnitAuraWatcher
local M = {}
addon.Core.UnitAuraWatcher = M

local function NotifyCallbacks(watcher)
	local callbacks = watcher.State.Callbacks
	if not callbacks or #callbacks == 0 then
		return
	end
	for _, callback in ipairs(callbacks) do
		callback(watcher)
	end
end

---Quick check using updateInfo to avoid scanning every time.
---Return true if updateInfo suggests there might be relevant changes.
local function MightAffectOurFilters(updateInfo)
	if not updateInfo then
		return true
	end

	-- If anything was removed/added/updated we probably care.
	if updateInfo.isFullUpdate then
		return true
	end

	if
		(updateInfo.addedAuras and #updateInfo.addedAuras > 0)
		or (updateInfo.updatedAuras and #updateInfo.updatedAuras > 0)
		or (updateInfo.removedAuraInstanceIDs and #updateInfo.removedAuraInstanceIDs > 0)
	then
		return true
	end

	return false
end

local function RebuildStates(watcher)
	local unit = watcher.State.Unit
	if not unit then
		return
	end

	local excludeDefensivesFromImportant = watcher.State.ExcludeDefensivesFromImportant
	---@type AuraInfo[]
	local ccSpellData = {}
	---@type AuraInfo[]
	local importantSpellData = {}
	---@type AuraInfo[]
	local defensivesSpellData = {}
	local seenDefensives = {}

	for i = 1, maxAuras do
		local ccData = C_UnitAuras.GetAuraDataByIndex(unit, i, ccFilter)

		if ccData then
			local durationInfo = C_UnitAuras.GetAuraDuration(unit, ccData.auraInstanceID)
			local start = durationInfo and durationInfo:GetStartTime()
			local duration = durationInfo and durationInfo:GetTotalDuration()

			if start and duration then
				if capabilities:HasNewFilters() then
					ccSpellData[#ccSpellData + 1] = {
						IsCC = true,
						SpellId = ccData.spellId,
						SpellIcon = ccData.icon,
						StartTime = start,
						TotalDuration = duration,
					}
				else
					local isCC = C_Spell.IsSpellCrowdControl(ccData.spellId)
					ccSpellData[#ccSpellData + 1] = {
						IsCC = isCC,
						SpellId = ccData.spellId,
						SpellIcon = ccData.icon,
						StartTime = start,
						TotalDuration = duration,
					}
				end
			end
		end

		if capabilities:HasNewFilters() then
			local defensivesData =
				C_UnitAuras.GetAuraDataByIndex(unit, i, "HELPFUL|BIG_DEFENSIVE|INCLUDE_NAME_PLATE_ONLY")
			if defensivesData then
				local durationInfo = C_UnitAuras.GetAuraDuration(unit, defensivesData.auraInstanceID)
				local start = durationInfo and durationInfo:GetStartTime()
				local duration = durationInfo and durationInfo:GetTotalDuration()

				if start and duration then
					defensivesSpellData[#defensivesSpellData + 1] = {
						IsDefensive = true,
						SpellId = defensivesData.spellId,
						SpellIcon = defensivesData.icon,
						StartTime = start,
						TotalDuration = duration,
					}
				end

				if excludeDefensivesFromImportant then
					seenDefensives[defensivesData.auraInstanceID] = true
				end
			end
		end

		local importantHelpfulData = C_UnitAuras.GetAuraDataByIndex(unit, i, importantHelpfulFilter)
		if importantHelpfulData and not seenDefensives[importantHelpfulData.auraInstanceID] then
			local isImportant = C_Spell.IsSpellImportant(importantHelpfulData.spellId)
			local durationInfo = C_UnitAuras.GetAuraDuration(unit, importantHelpfulData.auraInstanceID)
			local start = durationInfo and durationInfo:GetStartTime()
			local duration = durationInfo and durationInfo:GetTotalDuration()

			if start and duration then
				importantSpellData[#importantSpellData + 1] = {
					IsImportant = capabilities:HasNewFilters() or isImportant,
					SpellId = importantHelpfulData.spellId,
					SpellIcon = importantHelpfulData.icon,
					StartTime = start,
					TotalDuration = duration,
				}
			end
		end

		-- avoid doubling up with cc data, as both CC and HARMFUL return the same thing sometimes
		local importantHarmfulData = not ccData and C_UnitAuras.GetAuraDataByIndex(unit, i, importantHarmfulFilter)
		if importantHarmfulData and not seenDefensives[importantHarmfulData.auraInstanceID] then
			local isImportant = C_Spell.IsSpellImportant(importantHarmfulData.spellId)
			local durationInfo = C_UnitAuras.GetAuraDuration(unit, importantHarmfulData.auraInstanceID)
			local start = durationInfo and durationInfo:GetStartTime()
			local duration = durationInfo and durationInfo:GetTotalDuration()

			if start and duration then
				importantSpellData[#importantSpellData + 1] = {
					IsImportant = capabilities:HasNewFilters() or isImportant,
					SpellId = importantHarmfulData.spellId,
					SpellIcon = importantHarmfulData.icon,
					StartTime = start,
					TotalDuration = duration,
				}
			end
		end
	end

	---@type WatcherState
	local state = watcher.State
	state.CcAuraState = ccSpellData
	state.ImportantAuraState = importantSpellData
	state.DefensiveState = defensivesSpellData
end

local function OnEvent(watcher, event, ...)
	local state = watcher.State
	if event == "UNIT_AURA" then
		local unit, updateInfo = ...
		if unit and unit ~= state.Unit then
			return
		end

		if not MightAffectOurFilters(updateInfo) then
			return
		end
	end

	if event == "ARENA_OPPONENT_UPDATE" then
		local unit = ...
		if unit ~= state.Unit then
			return
		end
	end

	local u = state.Unit

	if not u then
		return
	end

	RebuildStates(watcher)
	NotifyCallbacks(watcher)
end

---@param unit string
---@param events string[]?
---@return Watcher
function M:New(unit, events, excludeDefensivesFromImportant)
	if not unit then
		error("unit must not be nil")
	end

	local watcher = {
		---@class WatcherState
		State = {
			Unit = unit,
			Events = events,
			Enabled = false,
			Callbacks = {},
			CcAuraState = {},
			ImportantAuraState = {},
			DefensiveState = {},
			ExcludeDefensivesFromImportant = excludeDefensivesFromImportant,
		},
		Frame = nil,

		GetUnit = function(watcherSelf)
			return watcherSelf.State.Unit
		end,

		RegisterCallback = function(watcherSelf, callback)
			if not callback then
				return
			end
			watcherSelf.State.Callbacks[#watcherSelf.State.Callbacks + 1] = callback
		end,

		IsEnabled = function(watcherSelf)
			return watcherSelf.State.Enabled
		end,
		Enable = function(watcherSelf)
			if watcherSelf.State.Enabled then
				return
			end

			local frame = watcherSelf.Frame
			frame:SetScript("OnEvent", function(_, event, ...)
				OnEvent(watcherSelf, event, ...)
			end)
			frame:RegisterUnitEvent("UNIT_AURA", watcherSelf.State.Unit)

			if watcherSelf.State.Events then
				for _, event in ipairs(watcherSelf.State.Events) do
					frame:RegisterEvent(event)
				end
			end
		end,

		Disable = function(watcherSelf)
			if not watcherSelf.State.Enabled then
				return
			end

			watcherSelf.Frame:UnregisterEvent("UNIT_AURA")
			watcherSelf.Frame:SetScript("OnEvent", nil)

			if watcherSelf.Events then
				for _, event in ipairs(watcherSelf.Events) do
					frame:UnregisterEvent(event)
				end
			end
		end,

		ClearState = function(watcherSelf, notify)
			local state = watcherSelf.State
			state.CcAuraState = {}
			state.ImportantAuraState = {}
			state.DefensiveState = {}
			if notify then
				NotifyCallbacks(watcherSelf)
			end
		end,

		ForceFullUpdate = function(watcherSelf)
			-- force a rebuild immediately (important when tokens are reused)
			OnEvent(watcherSelf, "UNIT_AURA", watcherSelf.State.Unit, { isFullUpdate = true })
		end,

		Dispose = function(watcherSelf)
			local f = watcherSelf.Frame
			if f then
				f:UnregisterAllEvents()
				f:SetScript("OnEvent", nil)
				watcherSelf.Frame = nil
			end
			-- ensure we don't keep closures alive
			watcherSelf.State.Callbacks = {}
			watcherSelf:ClearState(false)
		end,

		GetCcState = function(watcherSelf)
			return watcherSelf.State.CcAuraState
		end,
		GetImportantState = function(watcherSelf)
			return watcherSelf.State.ImportantAuraState
		end,
		GetDefensiveState = function(watcherSelf)
			return watcherSelf.State.DefensiveState
		end,
	}

	watcher.Frame = CreateFrame("Frame")
	watcher:Enable()
	-- Prime once to get initial state
	watcher:ForceFullUpdate()

	return watcher
end

---@class Watcher
---@field Frame Frame?
---@field GetCcState fun(self: Watcher): AuraInfo[]
---@field GetImportantState fun(self: Watcher): AuraInfo[]
---@field GetDefensiveState fun(self: Watcher): AuraInfo[]
---@field RegisterCallback fun(self: Watcher, callback: fun(self: Watcher))
---@field IsEnabled fun(self: Watcher): boolean
---@field GetUnit fun(self: Watcher): string
---@field Enable fun(self: Watcher)
---@field Disable fun(self: Watcher)
---@field ClearState fun(self: Watcher, notify: boolean?)
---@field ForceFullUpdate fun(self: Watcher)
---@field Dispose fun(self: Watcher)

---@class WatcherState
---@field Unit string
---@field EventsFrame table
---@field Filter string
---@field Callbacks fun()[]
---@field CcAuras AuraInfo[]
---@field ImportantAuras AuraInfo[]

---@class AuraInfo
---@field IsImportant? boolean
---@field IsCC? boolean
---@field IsDefensive? boolean
---@field SpellId number?
---@field SpellIcon string?
---@field TotalDuration number?
---@field StartTime number?
