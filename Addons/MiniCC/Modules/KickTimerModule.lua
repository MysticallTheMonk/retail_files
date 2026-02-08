---@type string, Addon
local addonName, addon = ...
local mini = addon.Core.Framework
local enabled = false
---@type Db
local db

-- fallback icon (rogue Kick)
local kickIcon = C_Spell.GetSpellTexture(1766)

---@type { string: boolean }
local kickedByUnits = {}

---@type KickBar
local kickBar = {
	Icons = {},
	Size = 50,
	Spacing = 1,
}

local friendlyUnitsToWatch = {
	"player",
	"party1",
	"party2",
}

local enemyUnitsToWatch = {
	"arena1",
	"arena2",
	"arena3",
}

---@type { string: table }
local partyUnitsEventsFrames = {}
---@type { string: table }
local enemyUnitsEventsFrames = {}
local matchEventsFrame
local playerSpecEventsFrame

local minKickCooldown = 15

---@type EnemyLastCastState
local lastEnemyCastState = {
	Time = nil,
	Unit = nil,
}

-- mininum delta between enemy cast success and us getting interrupted
-- unsure if it's affected by lag or not, needs testing
local lastEnemyKickTimeDuration = 0.5

-- per arena unit computed at arena prep
local kickDurationsByUnit = {} ---@type table<string, number?>
local kickIconsByUnit = {} ---@type table<string, any?>

local function KI(spellId)
	return spellId and C_Spell.GetSpellTexture(spellId) or nil
end

---@class SpecKickInfo
---@field KickCd number?
---@field IsCaster boolean
---@field IsHealer boolean
---@field KickIcon any? -- texture path/id for the kick/interrupt ability

---@type table<number, SpecKickInfo>
local specInfoBySpecId = {
	-- Rogue — Kick
	[259] = { KickCd = 15, IsCaster = false, IsHealer = false, KickIcon = KI(1766) }, -- Assassination
	[260] = { KickCd = 15, IsCaster = false, IsHealer = false, KickIcon = KI(1766) }, -- Outlaw
	[261] = { KickCd = 15, IsCaster = false, IsHealer = false, KickIcon = KI(1766) }, -- Subtlety

	-- Warrior — Pummel
	[71] = { KickCd = 15, IsCaster = false, IsHealer = false, KickIcon = KI(6552) }, -- Arms
	[72] = { KickCd = 15, IsCaster = false, IsHealer = false, KickIcon = KI(6552) }, -- Fury
	[73] = { KickCd = 15, IsCaster = false, IsHealer = false, KickIcon = KI(6552) }, -- Protection

	-- Death Knight — Mind Freeze
	[250] = { KickCd = 15, IsCaster = false, IsHealer = false, KickIcon = KI(47528) }, -- Blood
	[251] = { KickCd = 15, IsCaster = false, IsHealer = false, KickIcon = KI(47528) }, -- Frost
	[252] = { KickCd = 15, IsCaster = false, IsHealer = false, KickIcon = KI(47528) }, -- Unholy

	-- Demon Hunter — Disrupt
	[577] = { KickCd = 15, IsCaster = false, IsHealer = false, KickIcon = KI(183752) }, -- Havoc
	[581] = { KickCd = 15, IsCaster = false, IsHealer = false, KickIcon = KI(183752) }, -- Vengeance
	[1480] = { KickCd = 15, IsCaster = false, IsHealer = false, KickIcon = KI(183752) }, -- Devourer

	-- Monk — Spear Hand Strike
	[268] = { KickCd = 15, IsCaster = false, IsHealer = false, KickIcon = KI(116705) }, -- Brewmaster
	[269] = { KickCd = 15, IsCaster = false, IsHealer = false, KickIcon = KI(116705) }, -- Windwalker
	[270] = { KickCd = nil, IsCaster = false, IsHealer = true, KickIcon = KI(116705) }, -- Mistweaver

	-- Paladin — Rebuke
	[65] = { KickCd = nil, IsCaster = false, IsHealer = true, KickIcon = KI(96231) }, -- Holy
	[66] = { KickCd = 15, IsCaster = false, IsHealer = false, KickIcon = KI(96231) }, -- Protection
	[70] = { KickCd = 15, IsCaster = false, IsHealer = false, KickIcon = KI(96231) }, -- Retribution

	-- Druid
	[102] = { KickCd = 60, IsCaster = true, IsHealer = false, KickIcon = KI(78675) }, -- Balance (Solar Beam)
	[103] = { KickCd = 15, IsCaster = false, IsHealer = false, KickIcon = KI(106839) }, -- Feral (Skull Bash)
	[104] = { KickCd = 15, IsCaster = false, IsHealer = false, KickIcon = KI(106839) }, -- Guardian (Skull Bash)
	[105] = { KickCd = nil, IsCaster = false, IsHealer = true, KickIcon = nil }, -- Restoration

	-- Hunter — Counter Shot
	[253] = { KickCd = 24, IsCaster = true, IsHealer = false, KickIcon = KI(147362) }, -- Beast Mastery
	[254] = { KickCd = 24, IsCaster = true, IsHealer = false, KickIcon = KI(147362) }, -- Marksmanship
	[255] = { KickCd = 15, IsCaster = false, IsHealer = false, KickIcon = KI(147362) }, -- Survival

	-- Mage — Counterspell
	[62] = { KickCd = 24, IsCaster = true, IsHealer = false, KickIcon = KI(2139) }, -- Arcane
	[63] = { KickCd = 24, IsCaster = true, IsHealer = false, KickIcon = KI(2139) }, -- Fire
	[64] = { KickCd = 24, IsCaster = true, IsHealer = false, KickIcon = KI(2139) }, -- Frost

	-- Warlock — Spell Lock (Felhunter)
	[265] = { KickCd = 24, IsCaster = true, IsHealer = false, KickIcon = KI(19647) }, -- Affliction
	[266] = { KickCd = 24, IsCaster = true, IsHealer = false, KickIcon = KI(19647) }, -- Demonology
	[267] = { KickCd = 24, IsCaster = true, IsHealer = false, KickIcon = KI(19647) }, -- Destruction

	-- Shaman — Wind Shear
	[262] = { KickCd = 12, IsCaster = true, IsHealer = false, KickIcon = KI(57994) }, -- Elemental
	[263] = { KickCd = 12, IsCaster = false, IsHealer = false, KickIcon = KI(57994) }, -- Enhancement
	[264] = { KickCd = 30, IsCaster = false, IsHealer = true, KickIcon = KI(57994) }, -- Restoration

	-- Evoker — Quell
	[1467] = { KickCd = 40, IsCaster = true, IsHealer = false, KickIcon = KI(351338) }, -- Devastation
	[1468] = { KickCd = 40, IsCaster = false, IsHealer = true, KickIcon = KI(351338) }, -- Preservation
	[1473] = { KickCd = 40, IsCaster = true, IsHealer = false, KickIcon = KI(351338) }, -- Augmentation

	-- Priest
	[256] = { KickCd = nil, IsCaster = false, IsHealer = true, KickIcon = nil }, -- Discipline
	[257] = { KickCd = nil, IsCaster = false, IsHealer = true, KickIcon = nil }, -- Holy
	[258] = { KickCd = 45, IsCaster = true, IsHealer = false, KickIcon = KI(15487) }, -- Shadow (Silence)
}

---@class KickTimerModule : IModule
local M = {}
addon.Modules.KickTimerModule = M

local function GetPlayerSpecId()
	local specIndex = GetSpecialization()
	if not specIndex then
		return nil
	end
	local specId = GetSpecializationInfo(specIndex)
	if specId and specId > 0 then
		return specId
	end
	return nil
end

local function EnsureKickBar()
	local options = db.KickTimer
	local relativeTo = _G[options.RelativeTo] or UIParent
	local frame = CreateFrame("Frame", addonName .. "KickBar", UIParent, "BackdropTemplate")

	frame:SetPoint(options.Point, relativeTo, options.RelativePoint, options.Offset.X, options.Offset.Y)
	frame:SetSize(200, kickBar.Size)
	frame:SetFrameStrata("HIGH")
	frame:SetClampedToScreen(true)
	frame:SetMovable(false)
	frame:EnableMouse(false)
	frame:SetDontSavePosition(true)
	frame:SetIgnoreParentScale(true)
	frame:RegisterForDrag("LeftButton")
	frame:SetScript("OnDragStart", frame.StartMoving)
	frame:SetScript("OnDragStop", function(frameSelf)
		frameSelf:StopMovingOrSizing()

		local point, movedRelativeTo, relativePoint, x, y = frameSelf:GetPoint()
		options.Point = point
		options.RelativePoint = relativePoint
		options.RelativeTo = (movedRelativeTo and movedRelativeTo:GetName()) or "UIParent"
		options.Offset.X = x
		options.Offset.Y = y
	end)

	kickBar.Anchor = frame
end

local function ApplyKickBarIconOptions()
	local options = db.KickTimer
	local iconOptions = options.Icons

	kickBar.Size = iconOptions.Size or 50

	if kickBar.Anchor then
		kickBar.Anchor:SetHeight(kickBar.Size)
	end

	for _, frame in ipairs(kickBar.Icons) do
		frame:SetSize(kickBar.Size, kickBar.Size)
		if frame.Icon then
			frame.Icon:SetAllPoints()
		end
		if frame.Cooldown then
			frame.Cooldown:SetReverse(iconOptions.ReverseCooldown)
		end
	end
end

local function LayoutKickBar()
	-- Count active icons
	local activeCount = 0
	for _, iconFrame in ipairs(kickBar.Icons) do
		if iconFrame.Active then
			activeCount = activeCount + 1
		end
	end

	if activeCount == 0 then
		kickBar.Anchor:Hide()
		return
	end

	-- Calculate total width and starting offset for centering
	local totalWidth = (activeCount * kickBar.Size) + ((activeCount - 1) * kickBar.Spacing)
	local startX = -totalWidth / 2

	-- Position active icons centered
	local x = startX
	for _, iconFrame in ipairs(kickBar.Icons) do
		if iconFrame.Active then
			iconFrame:ClearAllPoints()
			iconFrame:SetPoint("LEFT", kickBar.Anchor, "CENTER", x, 0)
			x = x + kickBar.Size + kickBar.Spacing
		end
	end

	kickBar.Anchor:SetWidth(math.max(200, totalWidth + 8))
	kickBar.Anchor:Show()
end

local function CreateKickIcon(reverseCooldown)
	local frame = CreateFrame("Frame", nil, kickBar.Anchor)
	frame:SetSize(kickBar.Size, kickBar.Size)

	local icon = frame:CreateTexture(nil, "ARTWORK")
	icon:SetAllPoints()

	local cd = CreateFrame("Cooldown", nil, frame, "CooldownFrameTemplate")
	cd:SetAllPoints()
	cd:SetReverse(reverseCooldown)
	cd:SetDrawEdge(false)
	cd:SetDrawBling(false)

	frame.Icon = icon
	frame.Cooldown = cd
	frame.Active = false
	frame:Hide()

	return frame
end

local function GetOrCreateIcon()
	for _, frame in ipairs(kickBar.Icons) do
		if not frame.Active then
			local iconOptions = db.KickTimer.Icons
			frame:SetSize(kickBar.Size, kickBar.Size)
			frame.Cooldown:SetReverse(iconOptions.ReverseCooldown)
			return frame
		end
	end

	local iconOptions = db.KickTimer.Icons
	local frame = CreateKickIcon(iconOptions.ReverseCooldown)
	table.insert(kickBar.Icons, frame)
	return frame
end

local function OnFriendlyUnitEvent(unit, _, event, ...)
	if event == "UNIT_SPELLCAST_START" then
		kickedByUnits[unit] = false
	elseif event == "UNIT_SPELLCAST_INTERRUPTED" then
		if kickedByUnits[unit] then
			return
		end

		local kickedBy = select(4, ...)
		if not kickedBy then
			return
		end

		local now = GetTime()
		local timeSinceLastAction = now - lastEnemyCastState.Time
		local u = nil

		if lastEnemyCastState.Time and timeSinceLastAction < lastEnemyKickTimeDuration then
			u = lastEnemyCastState.Unit
		end

		kickedByUnits[unit] = true
		M:Kicked(u)
	end
end

local function OnEnemyUnitEvent(unit, _, event)
	if event == "UNIT_SPELLCAST_SUCCEEDED" then
		lastEnemyCastState.Unit = unit
		lastEnemyCastState.Time = GetTime()
	end
end

local function UpdateMinKickCooldownFromArenaSpecs()
	local minCd = 15
	local found = false

	for i = 1, 5 do
		local specId = GetArenaOpponentSpec(i)
		if specId and specId > 0 then
			local info = specInfoBySpecId[specId]
			local cd = info and info.KickCd
			if cd then
				if not found or cd < minCd then
					minCd = cd
				end
				found = true
			end
		end
	end

	minKickCooldown = found and minCd or 15
end

local function OnArenaPrep()
	UpdateMinKickCooldownFromArenaSpecs()

	wipe(kickDurationsByUnit)
	wipe(kickIconsByUnit)

	local numSpecs = GetNumArenaOpponentSpecs()

	for i = 1, numSpecs do
		local unit = "arena" .. i
		local specId = GetArenaOpponentSpec(i)
		local info = specInfoBySpecId[specId]

		kickDurationsByUnit[unit] = info and info.KickCd or nil
		kickIconsByUnit[unit] = (info and info.KickIcon) or nil
	end

	M:ClearIcons()
end

local function Disable()
	for _, unit in ipairs(friendlyUnitsToWatch) do
		local frame = partyUnitsEventsFrames[unit]
		if frame then
			frame:UnregisterEvent("UNIT_SPELLCAST_START")
			frame:UnregisterEvent("UNIT_SPELLCAST_INTERRUPTED")
			frame:SetScript("OnEvent", nil)
		end
		kickedByUnits[unit] = nil
	end

	for _, unit in ipairs(enemyUnitsToWatch) do
		local frame = enemyUnitsEventsFrames[unit]
		if frame then
			frame:UnregisterEvent("UNIT_SPELLCAST_SUCCEEDED")
			frame:SetScript("OnEvent", nil)
		end
	end

	if kickBar.Anchor then
		kickBar.Anchor:Hide()
	end

	M:ClearIcons()

	enabled = false
end

local function Enable(options)
	if enabled then
		return
	end

	for _, unit in ipairs(friendlyUnitsToWatch) do
		local frame = partyUnitsEventsFrames[unit]
		if frame then
			frame:RegisterUnitEvent("UNIT_SPELLCAST_START", unit)
			frame:RegisterUnitEvent("UNIT_SPELLCAST_INTERRUPTED", unit)
			frame:SetScript("OnEvent", function(...)
				OnFriendlyUnitEvent(unit, ...)
			end)
		end
	end

	for _, unit in ipairs(enemyUnitsToWatch) do
		local frame = enemyUnitsEventsFrames[unit]
		if frame then
			frame:RegisterUnitEvent("UNIT_SPELLCAST_SUCCEEDED", unit)
			frame:SetScript("OnEvent", function(...)
				OnEnemyUnitEvent(unit, ...)
			end)
		end
	end

	local relativeTo = _G[options.RelativeTo] or UIParent
	kickBar.Anchor:ClearAllPoints()
	kickBar.Anchor:SetPoint(options.Point, relativeTo, options.RelativePoint, options.Offset.X, options.Offset.Y)
	kickBar.Anchor:Show()

	enabled = true
end

local function CreateKickEntry(duration, icon)
	local frame = GetOrCreateIcon()
	frame.Icon:SetTexture(icon)
	frame.Active = true
	frame.Key = key
	frame:Show()
	frame.Cooldown:SetCooldown(GetTime(), duration)

	LayoutKickBar()

	C_Timer.After(duration, function()
		if frame and frame.Active and frame.Key == key then
			frame.Active = false
			frame:Hide()
			LayoutKickBar()
		end
	end)
end

---@param options KickTimerOptions
function M:IsEnabledForPlayer(options)
	if not options then
		return false
	end

	-- nothing toggled on
	if not (options.AllEnabled or options.CasterEnabled or options.HealerEnabled) then
		return false
	end

	if options.AllEnabled then
		return true
	end

	local specId = GetPlayerSpecId()
	if not specId then
		return false
	end

	local info = specInfoBySpecId[specId]
	if not info then
		return false
	end

	if options.HealerEnabled and info.IsHealer then
		return true
	end

	if options.CasterEnabled and info.IsCaster then
		return true
	end

	return false
end

---@param specId number?
function M:KickedBySpec(specId)
	if not specId then
		return
	end

	local specInfo = specInfoBySpecId[specId]

	if not specInfo or not specInfo.KickCd or not specInfo.KickIcon then
		return
	end

	local duration = specInfo.KickCd
	local tex = specInfo.KickIcon

	CreateKickEntry(duration, tex)
end

---@param kickedBy string?
function M:Kicked(kickedBy)
	local duration = minKickCooldown
	if kickedBy and kickDurationsByUnit[kickedBy] then
		duration = kickDurationsByUnit[kickedBy]
	end

	local tex = kickIcon

	if kickedBy and kickIconsByUnit[kickedBy] then
		tex = kickIconsByUnit[kickedBy]
	end

	CreateKickEntry(duration, tex)
end

function M:ClearIcons()
	for _, frame in ipairs(kickBar.Icons) do
		frame.Active = false
		frame:Hide()
	end

	if kickBar.Anchor then
		LayoutKickBar()
	end
end

function M:GetContainer()
	return kickBar.Anchor
end

function M:Init()
	db = mini:GetSavedVars()

	kickBar.Size = db.KickTimer.Icons.Size

	EnsureKickBar()

	for _, unit in ipairs(friendlyUnitsToWatch) do
		partyUnitsEventsFrames[unit] = CreateFrame("Frame")
	end

	for _, unit in ipairs(enemyUnitsToWatch) do
		enemyUnitsEventsFrames[unit] = CreateFrame("Frame")
	end

	-- always populate even if disabled, as they might re-enable during arena
	matchEventsFrame = CreateFrame("Frame")
	matchEventsFrame:RegisterEvent("PLAYER_ENTERING_WORLD")
	matchEventsFrame:RegisterEvent("ARENA_PREP_OPPONENT_SPECIALIZATIONS")
	matchEventsFrame:SetScript("OnEvent", OnArenaPrep)

	playerSpecEventsFrame = CreateFrame("Frame")
	playerSpecEventsFrame:RegisterEvent("PLAYER_SPECIALIZATION_CHANGED")
	playerSpecEventsFrame:SetScript("OnEvent", function(_, event, ...)
		if event == "PLAYER_SPECIALIZATION_CHANGED" then
			local unit = ...
			if unit == "player" then
				M:Refresh()
			end
		end
	end)

	M:Refresh()
end

function M:Refresh()
	local options = db.KickTimer

	if not M:IsEnabledForPlayer(options) then
		Disable()
		return
	end

	-- Apply icon options even if already enabled (for config changes)
	ApplyKickBarIconOptions()

	-- Update layout to reflect new sizes
	LayoutKickBar()

	Enable(options)
end

---@class KickBar
---@field Anchor table?
---@field Icons table
---@field Size number
---@field Spacing number

---@class EnemyLastCastState
---@field Time number?
---@field Unit string?
