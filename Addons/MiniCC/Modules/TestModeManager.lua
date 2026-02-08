-- TODO: refactor such that each module is responsible for it's own test mode
---@type string, Addon
local addonName, addon = ...
local mini = addon.Core.Framework
local capabilities = addon.Capabilities
local ccModule = addon.Modules.CcModule
local healerCcModule = addon.Modules.HealerCcModule
local portraitModule = addon.Modules.PortraitModule
local alertsModule = addon.Modules.AlertsModule
local nameplateModule = addon.Modules.NameplatesModule
local kickTimerModule = addon.Modules.KickTimerModule
local trinketsModule = addon.Modules.TrinketsModule
local frames = addon.Core.Frames
local LCG
---@type Db
local db
local enabled = false
---@type InstanceOptions|nil
local instanceOptions = nil
---@type table<table, table>
local testHeaders = {}
---@type TestSpell[]
local testSpells = {}
local testCcNameplateSpellIds = {
	-- kidney shot
	408,
	-- fear
	5782,
}
local testImportantNameplateSpellIds = {
	-- warlock wall
	104773,
	-- precog
	377362,
}
local hasDanders = false
local testHealerHeader
local previousSoundEnabled

---@class TestModeManager
local M = {}
addon.Modules.TestModeManager = M

local function HideTestFrames()
	for _, testHeader in pairs(testHeaders) do
		if testHeader.Icons then
			for _, btn in ipairs(testHeader.Icons) do
				LCG.ProcGlow_Stop(btn)
			end
		end
		testHeader:Hide()
	end

	local testPartyFrames = frames:GetTestFrames()
	for _, testPartyFrame in ipairs(testPartyFrames) do
		testPartyFrame:Hide()
	end

	local testFramesContainer = frames:GetTestFrameContainer()
	if testFramesContainer then
		testFramesContainer:Hide()
	end
end

local function HideHealerOverlay()
	testHealerHeader:Hide()
	healerCcModule:Hide()

	-- resume tracking cc events
	healerCcModule:Resume()

	previousSoundEnabled = nil
end

local function HidePortraitIcons()
	local containers = portraitModule:GetContainers()

	for _, container in ipairs(containers) do
		container:ResetAllSlots()
	end

	portraitModule:Refresh()
	portraitModule:Resume()
end

local function HideAlertsTestMode()
	alertsModule:ClearAll()
	alertsModule:Resume()

	local alertAnchor = alertsModule:GetAnchor()
	if not alertAnchor then
		return
	end

	alertAnchor.Frame:EnableMouse(false)
	alertAnchor.Frame:SetMovable(false)
end

local function HideNameplateTestMode()
	nameplateModule:Resume()
end

local function HideKickTimer()
	local container = kickTimerModule:GetContainer()
	kickTimerModule:ClearIcons()
	container:Hide()

	container:SetMovable(false)
	container:EnableMouse(false)
end

local function ShowKickTimer()
	local container = kickTimerModule:GetContainer()
	container:Show()

	container:SetMovable(true)
	container:EnableMouse(true)

	kickTimerModule:ClearIcons()
	-- mage
	kickTimerModule:KickedBySpec(62)
	-- hunter
	kickTimerModule:KickedBySpec(254)
	-- rogue
	kickTimerModule:KickedBySpec(259)
end

local function ShowAlertsTestMode()
	local alertAnchor = alertsModule:GetAnchor()
	if not alertAnchor then
		return
	end

	alertsModule:Pause()

	alertAnchor.Frame:EnableMouse(true)
	alertAnchor.Frame:SetMovable(true)

	local testAlertSpellIds = {
		190319, -- Combustion
		121471, -- Shadow Blades
		107574, -- Avatar
	}

	local count = math.min(#testAlertSpellIds, alertAnchor.Count or #testAlertSpellIds)
	alertAnchor:SetCount(count)

	local now = GetTime()
	for i = 1, count do
		alertAnchor:SetSlotUsed(i)

		local spellId = testAlertSpellIds[i]
		local tex = C_Spell.GetSpellTexture(spellId)
		local duration = 12 + (i - 1) * 3
		local startTime = now - (i - 1) * 1.25

		alertAnchor:SetLayer(
			i,
			1,
			tex,
			startTime,
			duration,
			true,
			db.Alerts.Icons.Glow,
			db.Alerts.Icons.ReverseCooldown
		)

		alertAnchor:FinalizeSlot(i, 1)
	end

	for i = count + 1, alertAnchor.Count do
		alertAnchor:SetSlotUnused(i)
	end
end

local function AnchorTestFrames()
	local width, height = 144, 72
	local anchors = frames:GetAll(false)
	local anchoredToReal = false
	local padding = 10
	local testFrames = frames:GetTestFrames()
	local testFramesContainer = frames:GetTestFrameContainer()

	if not testFramesContainer or not testFrames then
		return
	end

	for i, frame in ipairs(testFrames) do
		frame:ClearAllPoints()
		frame:SetSize(width, height)

		local anchor = #anchors > #testFrames and anchors[i]

		if
			anchor
			and anchor:GetWidth() > 0
			and anchor:GetHeight() > 0
			and anchor:GetTop() ~= nil
			and anchor:GetLeft() ~= nil
			and not hasDanders
		then
			frame:SetAllPoints(anchors[i])
			anchoredToReal = true
		else
			frame:SetPoint("TOP", testFramesContainer, "TOP", 0, (i - 1) * -frame:GetHeight() - padding)
		end
	end

	if anchoredToReal then
		testFramesContainer:Hide()
	else
		testFramesContainer:SetSize(width + padding * 2, height * #testFrames + padding * 2)
		testFramesContainer:Show()
	end
end

local function ShowTestFrames()
	if not instanceOptions then
		return
	end

	-- hide real headers
	ccModule:HideHeaders()

	local testPartyFrames = frames:GetTestFrames()
	local headers = ccModule:GetHeaders()

	-- try to show on real frames first
	local anyRealShown = false
	for anchor, _ in pairs(headers) do
		local testHeader = M:EnsureTestHeader(anchor)
		M:UpdateTestHeader(testHeader, instanceOptions.Icons)

		ccModule:AnchorHeader(testHeader, anchor, instanceOptions)
		frames:ShowHideFrame(testHeader, anchor, true, instanceOptions)
		anyRealShown = anyRealShown or testHeader:IsVisible()
	end

	if anyRealShown then
		for i = 1, #testPartyFrames do
			testPartyFrames[i]:Hide()
		end
	else
		AnchorTestFrames()

		local anchor, testHeader = next(testHeaders)
		for i = 1, #testPartyFrames do
			if testHeader then
				local testPartyFrame = testPartyFrames[i]
				M:UpdateTestHeader(testHeader, instanceOptions.Icons)

				ccModule:AnchorHeader(testHeader, testPartyFrame, instanceOptions)

				testHeader:Show()
				testHeader:SetAlpha(1)
				testPartyFrame:Show()

				anchor, testHeader = next(testHeaders, anchor)
			end
		end
	end
end

local function ShowHealerOverlay()
	testHealerHeader:Show()
	healerCcModule:Show()

	-- pause the healer manager from tracking cc events
	healerCcModule:Pause()

	-- update the size
	M:UpdateTestHeader(testHealerHeader, db.Healer.Icons)

	-- keep track of whether we have already played the test sound so we don't spam it
	if
		capabilities:HasNewFilters() and (not previousSoundEnabled or previousSoundEnabled ~= db.Healer.Sound.Enabled)
	then
		if db.Healer.Sound.Enabled then
			healerCcModule:PlaySound()
		end

		previousSoundEnabled = db.Healer.Sound.Enabled
	end
end

local function ShowPortraitIcons()
	local containers = portraitModule:GetContainers()
	local tex = C_Spell.GetSpellTexture(testSpells[1].SpellId)
	local now = GetTime()

	portraitModule:Pause()

	for _, container in ipairs(containers) do
		container:SetSlotUsed(1)
		container:SetLayer(
			1,
			1,
			tex,
			now,
			15, -- 15 second duration for test
			true, -- alphaBoolean
			false, -- glow
			db.Portrait.ReverseCooldown
		)
		container:FinalizeSlot(1, 1)
	end
end

local function ShowNameplateTestMode()
	nameplateModule:Pause()

	local containers = nameplateModule:GetAllContainers()

	for _, container in ipairs(containers) do
		local now = GetTime()
		local options = nameplateModule:GetUnitOptions(container.UnitToken)
		local ccOptions = options.CC
		local importantOptions = options.Important
		local ccContainer = container.CcContainer
		local importantContainer = container.ImportantContainer

		if ccContainer and ccOptions then
			for i = 1, #testCcNameplateSpellIds do
				ccContainer:SetSlotUsed(i)

				local spellId = testCcNameplateSpellIds[i]
				local tex = C_Spell.GetSpellTexture(spellId)
				local duration = 15 + (i - 1) * 3
				local startTime = now - (i - 1) * 0.5

				ccContainer:SetLayer(
					i,
					1,
					tex,
					startTime,
					duration,
					true,
					ccOptions.Icons.Glow,
					ccOptions.Icons.ReverseCooldown
				)
				ccContainer:FinalizeSlot(i, 1)
			end

			-- Mark remaining slots as unused
			for i = #testCcNameplateSpellIds + 1, ccContainer.Count do
				ccContainer:SetSlotUnused(i)
			end
		end

		if importantContainer and importantOptions then
			for i = 1, #testImportantNameplateSpellIds do
				importantContainer:SetSlotUsed(i)

				local spellId = testImportantNameplateSpellIds[i]
				local tex = C_Spell.GetSpellTexture(spellId)
				local duration = 15 + (i - 1) * 3
				local startTime = now - (i - 1) * 0.5
				importantContainer:SetLayer(
					i,
					1,
					tex,
					startTime,
					duration,
					true,
					importantOptions.Icons.Glow,
					importantOptions.Icons.ReverseCooldown
				)
				importantContainer:FinalizeSlot(i, 1)
			end

			-- Mark remaining slots as unused
			for i = #testImportantNameplateSpellIds + 1, importantContainer.Count do
				importantContainer:SetSlotUnused(i)
			end
		end
	end
end

function M:Init()
	db = mini:GetSavedVars()

	LCG = LibStub and LibStub("LibCustomGlow-1.0", false)

	local IsAddOnLoaded = (C_AddOns and C_AddOns.IsAddOnLoaded) or IsAddOnLoaded
	hasDanders = IsAddOnLoaded("DandersFrames")

	local kidneyShot = { SpellId = 408, DispelColor = DEBUFF_TYPE_NONE_COLOR }
	local fear = { SpellId = 5782, DispelColor = DEBUFF_TYPE_MAGIC_COLOR }
	local hex = { SpellId = 254412, DispelColor = DEBUFF_TYPE_CURSE_COLOR }
	local multipleTestSpells = { kidneyShot, fear, hex }

	testSpells = capabilities:HasNewFilters() and multipleTestSpells or { kidneyShot }

	-- healer overlay
	local healerAnchor = healerCcModule:GetAnchor()
	testHealerHeader = CreateFrame("Frame", addonName .. "TestHealerHeader", healerAnchor)
	testHealerHeader:EnableMouse(false)
	testHealerHeader:SetPoint("BOTTOM", healerAnchor, "BOTTOM", 0, 0)

	M:UpdateTestHeader(testHealerHeader, db.Healer.Icons)
end

function M:IsEnabled()
	return enabled
end

---@param options InstanceOptions?
function M:Enable(options)
	enabled = true
	instanceOptions = options
end

function M:Disable()
	enabled = false
end

---@param options InstanceOptions?
function M:SetOptions(options)
	instanceOptions = options
end

---@param frame table
---@param options IconOptions
function M:UpdateTestHeader(frame, options)
	local cols = #testSpells
	local rows = 1
	local size = tonumber(options.Size) or 32
	local padX, padY = 0, 0
	local stepX = size + padX
	local stepY = -(size + padY)
	local maxIcons = math.min(#testSpells, cols * rows)

	frame.Icons = frame.Icons or {}

	for i = 1, maxIcons do
		local btn = frame.Icons[i]
		if not btn then
			btn = CreateFrame("Button", nil, frame, "MiniCCAuraButtonTemplate")
			frame.Icons[i] = btn
		end

		btn:SetSize(size, size)
		btn.Icon:SetAllPoints(btn)

		btn:EnableMouse(false)
		btn.Icon:EnableMouse(false)

		local spell = testSpells[i]
		local texture = C_Spell.GetSpellTexture(spell.SpellId)

		btn.Icon:SetTexture(texture)

		local col = (i - 1) % cols
		local row = math.floor((i - 1) / cols)

		btn:ClearAllPoints()
		btn:SetPoint("TOPLEFT", frame, "TOPLEFT", col * stepX, row * stepY)
		btn:Show()

		if options.Glow then
			-- sometimes calling stop fails with some very weird LCG release error
			-- but we need to clear any existing glow and re-apply to fix an issue with icons not always glowing
			pcall(function()
				LCG.ProcGlow_Stop(btn)
			end)

			local color = options.ColorByDispelType
					and {
						spell.DispelColor.r,
						spell.DispelColor.g,
						spell.DispelColor.b,
						spell.DispelColor.a,
					}
				or nil
			LCG.ProcGlow_Start(btn, { startAnim = false, color = color })
		else
			pcall(function()
				LCG.ProcGlow_Stop(btn)
			end)
		end
	end

	local width = (cols * size) + ((cols - 1) * padX)
	local height = (rows * size) + ((rows - 1) * padY)
	frame:SetSize(width, height)
end

function M:EnsureTestHeader(anchor)
	local header = testHeaders[anchor]
	if not header then
		header = CreateFrame("Frame", nil, UIParent)
		testHeaders[anchor] = header
	end

	if instanceOptions then
		M:UpdateTestHeader(header, instanceOptions.Icons)
	end

	return header
end

function M:Hide()
	HideTestFrames()
	HideHealerOverlay()
	HidePortraitIcons()
	HideAlertsTestMode()
	HideNameplateTestMode()
	HideKickTimer()
	trinketsModule:StopTesting()
end

function M:Show()
	if instanceOptions and instanceOptions.Enabled then
		ShowTestFrames()
	else
		HideTestFrames()
	end

	if db.Healer.Enabled then
		ShowHealerOverlay()
	else
		HideHealerOverlay()
	end

	if db.Portrait.Enabled then
		ShowPortraitIcons()
	else
		HidePortraitIcons()
	end

	if db.Alerts.Enabled then
		ShowAlertsTestMode()
	else
		HideAlertsTestMode()
	end

	local anyNameplateEnabled = db.Nameplates.Friendly.CC.Enabled
		or db.Nameplates.Friendly.Important.Enabled
		or db.Nameplates.Enemy.CC.Enabled
		or db.Nameplates.Enemy.Important.Enabled

	if anyNameplateEnabled then
		ShowNameplateTestMode()
	else
		HideNameplateTestMode()
	end

	if kickTimerModule:IsEnabledForPlayer(db.KickTimer) then
		ShowKickTimer()
	else
		HideKickTimer()
	end

	if db.Trinkets and db.Trinkets.Enabled then
		trinketsModule:StartTesting()
	else
		trinketsModule:StopTesting()
	end
end

---@class TestSpell
---@field SpellId number
---@field DispelColor table
