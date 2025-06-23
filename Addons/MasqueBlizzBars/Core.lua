--
-- Masque Blizzard Bars
-- Enables Masque to skin the built-in WoW action bars
--
-- Copyright 2022 - 2024 SimGuy
--
-- Use of this source code is governed by an MIT-style
-- license that can be found in the LICENSE file or at
-- https://opensource.org/licenses/MIT.
--

local Masque = LibStub("Masque")
local ACR = LibStub("AceConfigRegistry-3.0")
local ACD = LibStub("AceConfigDialog-3.0")

local AddonName, Shared = ...

-- From Locales/Locales.lua
local L = Shared.Locale

-- From Metadata.lua
local Metadata = Shared.Metadata
local Groups = Metadata.Groups
local Types = Metadata.Types

-- Push us into shared object
local Core = {}
Shared.Core = Core

local _, _, _, ver = GetBuildInfo()

-- Get an option for the AceConfigDialog
function Core:GetOption(key)
	if not key then
		if self and self[#self] then
			key = self[#self]
		else
			return nil
		end
	end

	local value = false;
	local settings = _G[AddonName]

	if settings and settings[key] ~= nil then
		value = settings[key]
	elseif Metadata.Defaults and Metadata.Defaults[key] ~= nil then
		value = Metadata.Defaults[key]
	end

	--print("GetOption", key, value)
	return value
end

-- Set an option from the AceConfigDialog
function Core:SetOption(...)
	local key = self[#self]
	if not key then	return nil end

	local value = ...
	local settings = _G[AddonName]

	--print("SetOption", key, value)
	if settings and settings[key] ~= value then
		settings[key] = value
	end
	if Metadata.OptionCallbacks and Metadata.OptionCallbacks[key] then
		--print("OptionCallback", key)
		local func = Metadata.OptionCallbacks[key]
		func(key, value)
	end
end

-- Handle the load event to initialize things that require Saved Variables
function Core:HandleEvent(event, target)
	if event == "ADDON_LOADED" and target == AddonName then
		if not  _G[AddonName] then
			_G[AddonName] = {}
		end
		-- Don't register options unless they're defined.
		if Metadata.Options then
			Metadata.Options.get = Core.GetOption
			Metadata.Options.set = Core.SetOption
			ACR:RegisterOptionsTable(AddonName, Metadata.Options)
			ACD:AddToBlizOptions(AddonName, Metadata.FriendlyName)
		end
	end
end

-- Return a regions table based on the information passed for this button.
-- This needs to be called for every individual button being skinned, as
-- it returns actual references to the children of the button instance, not
-- key names.
function Core:MakeRegions(button, map)
	-- If map is empty, then do nothing
	if not map then return nil end

	local regions = {}
	for region, key in pairs(map) do
		local frame = button and button[key]
		if frame then
			-- If this is a function, call it now to get
			-- the object for the Masque region, otherwise
			-- assume the object is literal.
			if type(frame) == "function" then
				--print("regions function:", region, key, frame)
				regions[region] = frame(button)
			else
				--print("regions frame:", region, key, frame)
				regions[region] = frame
			end
		end
	end
	return regions
end

-- Skin any buttons in the table as members of the given Masque group.
-- If parent is set, then the button names are children of the parent
-- table. The buttons value can be a nested table.
--
-- If bclass is specified, limit this pass to a specific button class
-- within the group.  This is used for frames where new buttons get
-- added only as needed.  We assume the current number of slots in the
-- Metadata is how many were already skinned, and we'll just skin the
-- difference up to the total new slots.  If these numbers are equal
-- we won't do anything.
--
-- If this is a nested button structure, the caller needs to pass the
-- buttons subtree containing the button name, the parent frame, and
-- the prefix (parent name) or else this won't correctly find the button.
function Core:Skin(buttons, group, bclass, slots, parent, prefix)
	if not parent then parent = _G end
	if not prefix then prefix = "" end

	-- If button isn't set, we want to skin every class of button we were
	-- given and add it to the group, recursively if needed.
	for button, children in pairs(buttons) do
		-- If children is a table, process the table recursively as a set
		-- of buttons.  If bclass was passed, don't do any recursion.
		if not bclass and type(children) == "table" then
			if parent[button] then
				--print('recurse:', button, parent[button])
				Core:Skin(children, group, nil, nil, parent[button], prefix .. button)
			end
		-- Otherwise, try to skin all the expected buttons at this level.
		-- If bclass was passed, only act on the specific button class.
		-- If children wasn't a number, we shouldn't be here, so skip this button.
		elseif (bclass == button or not bclass) and type(children) == "number" then
			-- Pass the correct type for this button so that Masque
			-- doesn't have to try to figure it out.
			--print("map: type: ", prefix .. button)
			local btype = Types[prefix .. button] or {}
			local dtype = Types['DEFAULT'] or {}
			local type = btype.type or dtype.type or nil
			local map = btype.map or nil

			-- If -1, assume button is the actual button name
			-- If slots was set, we're confused, don't do anything
			if children == -1 and not slots then
				--print("button:", button, children, parent[button])
				local frame = parent[button]
				local regions = Core:MakeRegions(frame, map)
				group:AddButton(frame, regions, type)

			-- If -2, assume button is a function
			-- If slots was set, we're confused, don't do anything
			elseif children == -2 and not slots then
				--print("button:", button, children, parent[button])
				local frames = parent[button](parent)
				for _, frame in ipairs(frames) do
					local regions = Core:MakeRegions(frame, map)
					group:AddButton(frame, regions, type)
				end

			-- Otherwise, append a range of numbers to the name.
			--
			-- If we're not updating total slots, then loop through all
			-- buttons from 1 to the total number of expected children.
			--
			-- If we're update total slots, then start from the number
			-- we already had plus 1, and loop through any additional
			-- slots up to the total expected slots.
			--
			-- If updating total slots, update the new count after we're
			-- finished.
			elseif (not slots and children > 0) or
			       (slots and children >= 0 and children < slots) then
				local min, max = 1, children
				if slots then
					min = children + 1
					max = slots
				end
				--print("button range:", button, min, max)
				for i = min, max do
					--print("button:", button, i, parent[button..i])
					local frame = parent[button..i]
					local regions = Core:MakeRegions(frame, map)
					group:AddButton(frame, regions, type)
				end
				if slots then
					buttons[button] = slots
				end
			end
		end
	end
end

-- In 11.0 Blizzard added an itemButtonPool concept which makes finding all the
-- buttons in a container really easy.
function Core:SkinButtonPool(pools, group)
	for _, frame in ipairs(pools) do
		if frame.itemButtonPool then
			for button in frame.itemButtonPool:EnumerateActive() do
				-- TODO These should always be ItemButtons by
				-- nature of Blizzard code, but support regions
				-- just in case.
				if not button[AddonName.."Skinned"] then
					group:AddButton(button, nil, "Item")
					button[AddonName.."Skinned"] = true
				end
			end
		end
	end
end

-- Check if the current interface version is between the low number (inclusive)
-- and the high number (exclusive) for implementations that are dependent upon
-- client version.
function Core:CheckVersion(versions)
	if not versions or
	   (versions and
	    (not versions[1] or ver >= versions[1]) and
	    (not versions[2] or ver <  versions[2])
	   ) then
		return true
	else
		return false
	end
end

function Core:Init()
	-- Init Custom Options
	Core.Events = CreateFrame("Frame")
	Core.Events:RegisterEvent("ADDON_LOADED")
	Core.Events:SetScript("OnEvent", Core.HandleEvent)

	-- Create groups for each defined button group and add any buttons
	-- that should exist at this point
	for id, cont in pairs(Groups) do
		if Core:CheckVersion(cont.Versions) then
			cont.Group = Masque:Group(Metadata.MasqueFriendlyName, cont.Title, id)
			-- Reset l10n group names after ensuring migration to Static IDs
			cont.Group:SetName(L[cont.Title])
			if cont.Init then
				cont.Init(cont.Buttons)
			end
			if cont.Notes then
				cont.Group.Notes = cont.Notes
			end
			if not cont.Delayed then
				Core:Skin(cont.Buttons, cont.Group)
			end
		end
	end
end
