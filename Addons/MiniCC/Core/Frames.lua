---@type string, Addon
local addonName, addon = ...
local mini = addon.Core.Framework
local array = addon.Utils.Array
local units = addon.Utils.Units
local maxParty = MAX_PARTY_MEMBERS or 4
local maxRaid = MAX_RAID_MEMBERS or 40
local maxTestFrames = 3
local testPartyFrames = {}
local testFramesContainer = nil
---@type Db
local db
local initialised = false
---@class Frames
local M = {}
addon.Core.Frames = M

local function CreateTestFrame(i)
	local frame = CreateFrame("Frame", addonName .. "TestFrame" .. i, UIParent, "BackdropTemplate")
	frame:SetSize(144, 72)

	local _, class = UnitClass("player")
	local colour = RAID_CLASS_COLORS[class] or NORMAL_FONT_COLOR

	frame:SetBackdrop({
		bgFile = "Interface\\Buttons\\WHITE8X8",
		edgeFile = "Interface\\Tooltips\\UI-Tooltip-Border",
		edgeSize = 12,
		insets = { left = 2, right = 2, top = 2, bottom = 2 },
	})

	frame:SetBackdropColor(colour.r, colour.g, colour.b, 0.9)
	frame:SetBackdropBorderColor(0, 0, 0, 1)

	frame.Text = frame:CreateFontString(nil, "OVERLAY", "GameFontNormalLarge")
	frame.Text:SetPoint("CENTER")
	frame.Text:SetText(("party%d"):format(i))
	frame.Text:SetTextColor(1, 1, 1)

	-- some modules expect this, e.g. trinket module
	frame.unit = "party" .. i

	return frame
end

local function CreateTestFrames()
	testFramesContainer = CreateFrame("Frame", addonName .. "TestContainer")
	testFramesContainer:SetClampedToScreen(true)
	testFramesContainer:EnableMouse(true)
	testFramesContainer:SetMovable(true)
	testFramesContainer:RegisterForDrag("LeftButton")
	testFramesContainer:SetScript("OnDragStart", function(containerSelf)
		containerSelf:StartMoving()
	end)
	testFramesContainer:SetScript("OnDragStop", function(containerSelf)
		containerSelf:StopMovingOrSizing()
	end)
	testFramesContainer:SetPoint("CENTER", UIParent, "CENTER", -450, 0)
	testFramesContainer:Hide()

	local width, height = 144, 72
	local padding = 10

	for i = 1, maxTestFrames do
		local frame = testPartyFrames[i]
		if not frame then
			frame = CreateTestFrame(i)
			testPartyFrames[i] = frame
		end

		frame:ClearAllPoints()
		frame:SetSize(width, height)
		frame:SetPoint("TOP", testFramesContainer, "TOP", 0, (i - 1) * -frame:GetHeight() - padding)
	end

	testFramesContainer:SetSize(width + padding * 2, height * maxTestFrames + padding * 2)
end

---Retrieves a list of Blizzard frames.
---@param visibleOnly boolean
---@return table
function M:BlizzardFrames(visibleOnly)
	local frames = {}

	-- + 1 for player/self
	for i = 1, maxParty + 1 do
		local frame = _G["CompactPartyFrameMember" .. i]

		if frame and (frame:IsVisible() or not visibleOnly) then
			frames[#frames + 1] = frame
		end
	end

	for i = 1, maxRaid do
		local frame = _G["CompactRaidFrame" .. i]

		if frame and (frame:IsVisible() or not visibleOnly) then
			frames[#frames + 1] = frame
		end
	end

	return frames
end

---Retrieves a list of DandersFrames frames.
---@param visibleOnly boolean
---@return table
function M:DandersFrames(visibleOnly)
	if not DandersFrames or not DandersFrames.Api or not DandersFrames.Api.GetFrameForUnit then
		return {}
	end

	local frames = {}
	local playerParty = DandersFrames.Api.GetFrameForUnit("player", "party")
	local playerRaid = DandersFrames.Api.GetFrameForUnit("player", "raid")

	if playerParty and (playerParty:IsVisible() or not visibleOnly) then
		frames[#frames + 1] = playerParty
	end

	if playerRaid and (playerRaid:IsVisible() or not visibleOnly) then
		frames[#frames + 1] = playerRaid
	end

	for i = 1, maxParty do
		local frame = DandersFrames.Api.GetFrameForUnit("party" .. i, "party")

		if frame and frame:IsVisible() then
			frames[#frames + 1] = frame
		end
	end

	for i = 1, maxRaid do
		local frame = DandersFrames.Api.GetFrameForUnit("raid" .. i, "raid")

		if frame and frame:IsVisible() then
			frames[#frames + 1] = frame
		end
	end

	return frames
end

---Retrieves a list of Grid2 frames.
---@param visibleOnly boolean
---@return table
function M:Grid2Frames(visibleOnly)
	if not Grid2 or not Grid2.GetUnitFrames then
		return {}
	end

	local frames = {}
	local playerFrames = Grid2:GetUnitFrames("player")
	local playerFrame = playerFrames and next(playerFrames)

	if playerFrame and (playerFrame:IsVisible() or not visibleOnly) then
		frames[#frames + 1] = playerFrame
	end

	for i = 1, maxParty do
		local partyFrames = Grid2:GetUnitFrames("party" .. i)
		local frame = partyFrames and next(partyFrames)

		if frame and (frame:IsVisible() or not visibleOnly) then
			frames[#frames + 1] = frame
		end
	end

	for i = 1, maxRaid do
		local raidFrames = Grid2:GetUnitFrames("party" .. i)
		local frame = raidFrames and next(raidFrames)

		if frame and (frame:IsVisible() or not visibleOnly) then
			frames[#frames + 1] = frame
		end
	end

	return frames
end

---Retrieves a list of ElvUI frames.
---@param visibleOnly boolean
---@return table
function M:ElvUIFrames(visibleOnly)
	if not ElvUI then
		return {}
	end

	---@diagnostic disable-next-line: deprecated
	local E = unpack(ElvUI)

	if not E then
		return {}
	end

	local UF = E:GetModule("UnitFrames")

	if not UF then
		return {}
	end

	local frames = {}

	for groupName in pairs(UF.headers) do
		local group = UF[groupName]
		if group and group.GetChildren then
			local groupFrames = { group:GetChildren() }

			for _, frame in ipairs(groupFrames) do
				-- is this a unit frame or a subgroup?
				if not frame.Health then
					local children = { frame:GetChildren() }

					for _, child in ipairs(children) do
						if child.unit and (child:IsVisible() or not visibleOnly) then
							frames[#frames + 1] = child
						end
					end
				elseif frame.unit and (frame:IsVisible() or not visibleOnly) then
					frames[#frames + 1] = frame
				end
			end
		end
	end

	return frames
end

---Retrieves a list of Shadowed Unit Frames (SUF) frames.
---@param visibleOnly boolean
---@return table
function M:ShadowedUFFrames(visibleOnly)
	if not SUFUnitplayer and not SUFHeaderpartyUnitButton1 and not SUFHeaderraidUnitButton1 then
		return {}
	end

	local frames = {}

	local function Add(frame)
		if not frame then
			return
		end
		if frame.IsForbidden and frame:IsForbidden() then
			return
		end
		if (not visibleOnly) or frame:IsVisible() then
			frames[#frames + 1] = frame
		end
	end

	-- “Normal” SUF unit frames (SUFUnit<unit>) :contentReference[oaicite:1]{index=1}
	local unitNames = {
		"player",
		"pet",
		"pettarget",
		"target",
		"targettarget",
		"targettargettarget",
		"focus",
		"focustarget",
	}

	for _, unitName in ipairs(unitNames) do
		Add(_G["SUFUnit" .. unitName])
	end

	-- Party / Raid header buttons (SUFHeaderpartyUnitButton# / SUFHeaderraidUnitButton#) :contentReference[oaicite:2]{index=2}
	for i = 1, maxParty do
		Add(_G["SUFHeaderpartyUnitButton" .. i])

		-- Some layouts/forks also expose party as SUFUnitparty#
		Add(_G["SUFUnitparty" .. i])
	end

	for i = 1, maxRaid do
		Add(_G["SUFHeaderraidUnitButton" .. i])

		-- Some layouts/forks also expose raid as SUFUnitraid#
		Add(_G["SUFUnitraid" .. i])
	end

	return frames
end

---Retrieves a list of Plexus raid/party unit frames from PlexusLayoutHeader frames only.
---@param visibleOnly boolean
---@return table
function M:PlexusFrames(visibleOnly)
	-- Plexus must be loaded
	if not PlexusLayoutHeader1 then
		return {}
	end

	local frames = {}
	local seen = {}

	local function Add(frame)
		if not frame then
			return
		end
		if seen[frame] then
			return
		end
		if frame.IsForbidden and frame:IsForbidden() then
			return
		end
		if visibleOnly and not frame:IsVisible() then
			return
		end

		seen[frame] = true
		frames[#frames + 1] = frame
	end

	local headerIndex = 1

	while true do
		local header = _G["PlexusLayoutHeader" .. headerIndex]
		if not header then
			break
		end

		-- These are secure header children = actual unit buttons
		for _, child in ipairs({ header:GetChildren() }) do
			local unit = child.unit or (child.GetAttribute and child:GetAttribute("unit"))

			if unit and unit ~= "" then
				Add(child)
			end
		end

		headerIndex = headerIndex + 1
	end

	return frames
end

---Retrieves a list of custom frames from our saved vars.
---@param visibleOnly boolean
---@return table
function M:CustomFrames(visibleOnly)
	local frames = {}
	local i = 1
	local anchor = db["Anchor" .. i]

	while anchor and anchor ~= "" do
		local frame = _G[anchor]

		if not frame then
			mini:Notify("Bad anchor%d: '%s'.", i, anchor)
		elseif frame:IsVisible() or not visibleOnly then
			frames[#frames + 1] = frame
		end

		i = i + 1
		anchor = db["Anchor" .. i]
	end

	return frames
end

function M:GetTestFrameContainer()
	return testFramesContainer
end

function M:GetTestFrames()
	return testPartyFrames
end

---Anchors a frame to a texture region (which can't be anchored to with SetAllPoints()).
function M:AnchorFrameToRegionGeometry(frame, region)
	frame:ClearAllPoints()

	local parent = region:GetParent()
	local num = region:GetNumPoints()

	if num == 0 then
		frame:SetSize(region:GetSize())
		frame:SetPoint("CENTER", parent, "CENTER", 0, 0)
		return
	end

	for i = 1, num do
		local point, relativeTo, relativePoint, xOfs, yOfs = region:GetPoint(i)

		if relativeTo and relativeTo.GetObjectType then
			while relativeTo and relativeTo.GetObjectType and relativeTo:GetObjectType() ~= "Frame" do
				relativeTo = relativeTo:GetParent()
			end
		end

		relativeTo = relativeTo or parent
		frame:SetPoint(point, relativeTo, relativePoint, xOfs or 0, yOfs or 0)
	end

	frame:SetSize(region:GetSize())
end

function M:GetAll(visibleOnly, includeTestFrames)
	local anchors = {}
	local elvui = M:ElvUIFrames(visibleOnly)
	local grid2 = M:Grid2Frames(visibleOnly)
	local danders = M:DandersFrames(visibleOnly)
	local blizzard = M:BlizzardFrames(visibleOnly)
	local suf = M:ShadowedUFFrames(visibleOnly)
	local plexus = M:PlexusFrames(visibleOnly)
	local custom = M:CustomFrames(visibleOnly)

	array:Append(blizzard, anchors)
	array:Append(elvui, anchors)
	array:Append(grid2, anchors)
	array:Append(danders, anchors)
	array:Append(suf, anchors)
	array:Append(plexus, anchors)
	array:Append(custom, anchors)

	if includeTestFrames then
		local testFrames = M:GetTestFrames()
		array:Append(testFrames, anchors)
	end

	return anchors
end

function M:IsFriendlyCuf(frame)
	if frame:IsForbidden() then
		return false
	end

	local name = frame:GetName()
	if not name then
		return false
	end

	return string.find(name, "CompactParty") ~= nil or string.find(name, "CompactRaid") ~= nil
end

---@param header table
---@param anchor table
---@param isTest boolean
---@param options HeaderOptions
function M:ShowHideFrame(header, anchor, isTest, options)
	if not isTest and not options.Enabled then
		header:Hide()
		return
	end

	if anchor:IsForbidden() then
		header:Hide()
		return
	end

	local unit = header:GetAttribute("unit") or anchor.unit or anchor:GetAttribute("unit")

	if unit and unit ~= "" then
		if units:IsPet(unit) then
			header:Hide()
			return
		end

		if not isTest and options.ExcludePlayer and UnitIsUnit(unit, "player") then
			header:Hide()
			return
		end
	end

	local alpha = anchor:GetAlpha()
	if mini:IsSecret(alpha) and anchor:IsVisible() then
		header:SetAlpha(alpha)
		header:Show()
		return
	end

	if anchor:IsVisible() then
		header:SetAlpha(1)
		header:Show()
	else
		header:Hide()
	end
end

function M:Init()
	if initialised then
		return
	end

	db = mini:GetSavedVars()
	CreateTestFrames()

	initialised = true
end
