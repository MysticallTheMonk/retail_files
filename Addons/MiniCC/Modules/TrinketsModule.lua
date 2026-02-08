---@type string, Addon
local _, addon = ...
local mini = addon.Core.Framework
local frames = addon.Core.Frames
local eventFrame
local enabled = false
local paused = false
local testModeActive = false
local defaultSpellId = 336126
local defaultTrinketIcon
---@type { [table]: TrinketWatcher }
local watchers = {}
---@type Db
local db
---@type TrinketsOptions
local options

---@class TrinketsModule : IModule
local M = {}
addon.Modules.TrinketsModule = M

local units = {
	-- track self
	"player",
	-- track party123 for test mode purposes
	"party1",
	"party2",
	"party3",
	-- arena is a raid, so we want to track raid units
	"raid1",
	"raid2",
	"raid3",
}

local function IsInArena()
	local inInstance, instanceType = IsInInstance()
	return inInstance and (instanceType == "arena")
end

local function GetSpellTexture(spellId)
	if not spellId then
		return nil
	end

	return C_Spell.GetSpellTexture(spellId)
end

local function FormatSeconds(seconds)
	if not seconds or seconds <= 0 then
		return ""
	end
	if seconds >= 60 then
		return string.format("%dm", math.floor(seconds / 60 + 0.5))
	end
	return string.format("%d", math.floor(seconds + 0.5))
end

local function IsTrackedUnit(unit)
	for _, u in ipairs(units) do
		if u == unit then
			return true
		end
	end

	return false
end

local function NormalizeCooldownValues(start, duration)
	if not start or not duration then
		return start, duration
	end

	return start / 1000, duration / 1000
end

local function CreateIcon(unit)
	local frame = CreateFrame("Frame", nil, UIParent)
	frame:SetSize(options.Icons.Size, options.Icons.Size)

	frame.Icon = frame:CreateTexture(nil, "ARTWORK")
	frame.Icon:SetAllPoints()
	frame.Icon:SetTexture(defaultTrinketIcon or "Interface\\Icons\\INV_Misc_QuestionMark")

	frame.CD = CreateFrame("Cooldown", nil, frame, "CooldownFrameTemplate")
	frame.CD:SetAllPoints()
	frame.CD:SetDrawSwipe(true)
	frame.CD:SetDrawEdge(false)
	frame.CD:SetDrawBling(false)
	frame.CD:SetReverse(false)

	frame.Text = frame:CreateFontString(nil, "OVERLAY", options.Font.File)
	frame.Text:SetPoint("CENTER", frame, "CENTER", 0, 0)
	frame.Text:SetText("")

	frame.Unit = unit
	frame.SpellId = nil
	frame.Start = nil
	frame.Duration = nil
	frame.Ticker = nil

	frame:Hide()
	return frame
end

local function ApplyOptionsToIcon(frame)
	local size = tonumber(options.Icons.Size) or 32
	local _, fontSize, flags = frame.Text:GetFont()

	frame:SetSize(size, size)
	frame.Text:SetFont(options.Font.File, fontSize or 12, flags)
end

local function StopTicker(icon)
	if icon and icon.Ticker then
		icon.Ticker:Cancel()
		icon.Ticker = nil
	end
end

local function TickText(icon)
	if not options.Icons.ShowText then
		icon.Text:SetText("")
		StopTicker(icon)
		return
	end

	if not icon.Start or not icon.Duration or icon.Duration <= 0 then
		icon.Text:SetText("")
		StopTicker(icon)
		return
	end

	local remain = (icon.Start + icon.Duration) - GetTime()
	if remain > 0.1 then
		icon.Text:SetText(FormatSeconds(remain))
	else
		icon.Text:SetText("")
		StopTicker(icon)
	end
end

local function StartTicker(icon)
	StopTicker(icon)

	-- render once immediately
	TickText(icon)

	if not icon.Start or not icon.Duration or icon.Duration <= 0 then
		return
	end

	icon.Ticker = C_Timer.NewTicker(1, function()
		TickText(icon)
	end)
end

local function SetIconState(icon, spellId, start, duration)
	if not icon then
		return
	end

	start, duration = NormalizeCooldownValues(start, duration)

	icon.SpellId = spellId
	icon.Start = start
	icon.Duration = duration

	if not spellId or not start or not duration or duration <= 0 then
		icon.Icon:SetTexture(defaultTrinketIcon or "Interface\\Icons\\INV_Misc_QuestionMark")
		icon.CD:Clear()
		icon.Text:SetText("")
		StopTicker(icon)
		return
	end

	local tex = GetSpellTexture(spellId) or defaultTrinketIcon or "Interface\\Icons\\INV_Misc_QuestionMark"
	icon.Icon:SetTexture(tex)

	icon.CD:SetCooldown(start, duration)
	StartTicker(icon)
end

local function UpdateUnit(unit, spellId, start, duration)
	for _, w in pairs(watchers) do
		if w.Unit == unit then
			SetIconState(w.Icon, spellId, start, duration)
		end
	end
end

local function ClearAll()
	for _, w in pairs(watchers) do
		SetIconState(w.Icon, nil, nil, nil)
	end
end

local function AnchorIconToFrame(icon, anchorFrame)
	icon:ClearAllPoints()
	icon:SetPoint(options.Point, anchorFrame, options.RelativePoint, options.Offset.X, options.Offset.Y)
end

local function EnsureWatcher(anchorFrame, unit)
	local watcher = watchers[anchorFrame]
	if watcher then
		watcher.Unit = unit
		watcher.Icon.Unit = unit
		ApplyOptionsToIcon(watcher.Icon)
		return watcher
	end

	local icon = CreateIcon(unit)

	watcher = {
		Anchor = anchorFrame,
		Unit = unit,
		Icon = icon,
	}
	watchers[anchorFrame] = watcher

	return watcher
end

local function DestroyWatcher(anchorFrame)
	local watcher = watchers[anchorFrame]
	if not watcher then
		return
	end

	if watcher.Icon then
		StopTicker(watcher.Icon)
		watcher.Icon:Hide()
		watcher.Icon:SetParent(nil)
	end

	watchers[anchorFrame] = nil
end

local function RebuildAnchors()
	local anchors = frames:GetAll(true, testModeActive)
	local seen = {}

	for _, anchor in ipairs(anchors) do
		if anchor and not (anchor.IsForbidden and anchor:IsForbidden()) then
			local unit = anchor.unit or (anchor.GetAttribute and anchor:GetAttribute("unit"))
			if unit and unit ~= "" and IsTrackedUnit(unit) then
				local w = EnsureWatcher(anchor, unit)
				seen[anchor] = true
				AnchorIconToFrame(w.Icon, anchor)
			end
		end
	end

	for anchorFrame in pairs(watchers) do
		if not seen[anchorFrame] then
			DestroyWatcher(anchorFrame)
		end
	end
end

local function RequestAll()
	if not IsInArena() then
		return
	end

	for _, unit in ipairs(units) do
		if UnitExists(unit) then
			C_PvP.RequestCrowdControlSpell(unit)
		end
	end
end

-- Refresh only one unit (using unitTarget from ARENA_COOLDOWNS_UPDATE)
local function RefreshUnit(unit)
	if not unit or unit == "" or not UnitExists(unit) then
		return
	end

	local spellId, start, duration = C_PvP.GetArenaCrowdControlInfo(unit)

	if not spellId or not start or not duration then
		-- don't overwrite existing data if they've already trinketed
		return
	end

	for _, watcher in pairs(watchers) do
		if watcher.Icon and watcher.Unit == unit then
			SetIconState(watcher.Icon, spellId, start, duration)
		end
	end
end

local function RefreshAll()
	for _, watcher in pairs(watchers) do
		local unit = watcher.Unit
		local icon = watcher.Icon

		if icon and unit and UnitExists(unit) then
			local spellId, start, duration = C_PvP.GetArenaCrowdControlInfo(unit)

			if spellId and start and duration then
				SetIconState(icon, spellId, start, duration)
			else
				if not icon.SpellId then
					SetIconState(icon, nil, nil, nil)
				end
			end
		elseif icon then
			SetIconState(icon, nil, nil, nil)
		end
	end
end

local function UpdateVisibility()
	local show = options.Enabled and (IsInArena() or testModeActive)

	for _, watcher in pairs(watchers) do
		if watcher.Icon then
			if show and watcher.Anchor and watcher.Anchor.IsVisible and watcher.Anchor:IsVisible() then
				watcher.Icon:Show()
			else
				watcher.Icon:Hide()
			end
		end
	end
end

local function OnEvent(_, event, ...)
	if paused then
		-- While paused, we still allow anchor rebuild + visibility so people can position frames,
		if event == "PLAYER_ENTERING_WORLD" or event == "GROUP_ROSTER_UPDATE" or event == "PLAYER_TARGET_CHANGED" then
			RebuildAnchors()
			UpdateVisibility()
		end
		return
	end

	if event == "PVP_MATCH_STATE_CHANGED" then
		local matchState = C_PvP.GetActiveMatchState()
		if matchState == Enum.PvPMatchState.StartUp then
			ClearAll()
		end

		-- in case they trinketed before the gates opened
		-- TODO: does this work?
		RequestAll()
		RefreshAll()

		return
	end

	if event == "PLAYER_ENTERING_WORLD" then
		M:Refresh()
		return
	end

	if event == "GROUP_ROSTER_UPDATE" then
		-- for some  reason it doesn't work right away
		C_Timer.After(1, function()
			M:Refresh()
		end)
		return
	end

	if event == "ARENA_COOLDOWNS_UPDATE" then
		local unitTarget = ...

		if unitTarget and unitTarget ~= "" then
			RefreshUnit(unitTarget)
		else
			RefreshAll()
		end
		return
	end
end

function M:StartTesting()
	testModeActive = true
	self:Pause()

	RebuildAnchors()
	UpdateVisibility()

	local now = GetTime() * 1000

	-- Stagger durations so you can see different states
	local stateByUnit = {
		player = {
			spellId = defaultSpellId,
			start = now,
			duration = 90 * 1000,
		},
		party1 = {
			spellId = defaultSpellId,
			start = now,
			duration = 120 * 1000,
		},
		party2 = {
			spellId = defaultSpellId,
			start = now,
			duration = 60 * 1000,
		},
		party3 = {
			spellId = defaultSpellId,
			start = now,
			duration = 45 * 1000,
		},
	}

	for unit, state in pairs(stateByUnit or {}) do
		if state then
			UpdateUnit(unit, state.spellId, state.start, state.duration)
		else
			UpdateUnit(unit, nil, nil, nil)
		end
	end
end

function M:StopTesting()
	testModeActive = false

	ClearAll()
	M:Resume()
end

function M:Enable()
	if eventFrame then
		return
	end

	enabled = true

	eventFrame = CreateFrame("Frame")
	eventFrame:RegisterEvent("PLAYER_ENTERING_WORLD")
	eventFrame:RegisterEvent("GROUP_ROSTER_UPDATE")
	eventFrame:RegisterEvent("ARENA_COOLDOWNS_UPDATE")
	eventFrame:RegisterEvent("PVP_MATCH_STATE_CHANGED")
	eventFrame:SetScript("OnEvent", OnEvent)
end

function M:Disable()
	enabled = false

	if eventFrame then
		eventFrame:UnregisterAllEvents()
		eventFrame:SetScript("OnEvent", nil)
		eventFrame = nil
	end

	for anchorFrame in pairs(watchers) do
		DestroyWatcher(anchorFrame)
	end
end

function M:Pause()
	paused = true
end

function M:Resume()
	paused = false
	self:Refresh()
end

function M:Refresh()
	if options.Enabled and not enabled then
		M:Enable()
	elseif not options.Enabled and enabled then
		M:Disable()
	end

	if enabled then
		RebuildAnchors()
		UpdateVisibility()
		RequestAll()
		RefreshAll()

		for _, watcher in pairs(watchers) do
			if watcher.Icon then
				ApplyOptionsToIcon(watcher.Icon)
			end
		end
	end
end

function M:Init()
	db = mini:GetSavedVars()
	options = db.Trinkets

	defaultTrinketIcon = GetSpellTexture(defaultSpellId)

	M:Refresh()
end

---@class TrinketWatcher
---@field Anchor table
---@field Unit string
---@field Icon table
