local AddonName, Addon = ...

Addon.frame = CreateFrame("Frame", nil, SettingsPanel or InterfaceOptionsFrame)
Addon.frame.owner = Addon

function Addon:OnLoad()
	self.frame:SetScript("OnEvent", function(frame, event, ...)
		local func = frame.owner[event]

		if func then
			func(self, event, ...)
		end
	end)

	self.frame:RegisterEvent("ADDON_LOADED")
	self.frame:RegisterEvent("PLAYER_ENTERING_WORLD")
	self.frame:RegisterEvent("UPDATE_BINDINGS")
	self.frame:RegisterEvent("PLAYER_LOGOUT")

	-- Drop this method, as we won't need it again.
	self.OnLoad = nil
	_G[AddonName] = self
end

function Addon:ADDON_LOADED(event, addonName)
	if addonName ~= AddonName then return end

	self.sets = {
		-- Colors used for range indicators. {R, G, B, A}
		IN_RANGE = {1, 1, 1, 1},  -- White
		OUT_OF_RANGE = {1, 0, 0, 1},  -- Red
		HIDDEN = {1, 1, 1, 0}  -- Transparent
	}

	if type(self.Enable) == "function" then
		self:Enable()
	else
		print("The addon", addonName, "can't be enabled for World of Warcraft version", GetBuildInfo() .. ".")
	end

	-- Get rid of the handler, as we don't need it anymore.
	self.frame:UnregisterEvent(event)
	self[event] = nil
end

local action_bars = {
	"Action", -- Action Bar 1
	"MultiBarBottomLeft", -- Action Bar 2
	"MultiBarBottomRight", -- Action Bar 3
	"MultiBarRight", -- Action Bar 4
	"MultiBarLeft", -- Action Bar 5
	"MultiBar5", -- Action Bar 6
	"MultiBar6", -- Action Bar 7
	"MultiBar7" -- Action Bar 8
}

local function HideHotkeys()
	for i = 1, 12 do
		local color = Addon.sets["HIDDEN"]

		for _, action_bar in pairs(action_bars) do
			local hotkey = _G[action_bar .. "Button" .. i .. "HotKey"]

			hotkey:SetVertexColor(color[1], color[2], color[3])
			hotkey:SetText(RANGE_INDICATOR)

			-- Don't use Hide() because, if I'm not wrong, the game uses Show() sometimes.
			hotkey:SetAlpha(0)
		end
	end
end

-- Do stuff right after login or when reloading.
function Addon:PLAYER_ENTERING_WORLD(event)
	HideHotkeys()
end

-- Do stuff when changing hotkeys.
function Addon:UPDATE_BINDINGS(event)
	HideHotkeys()
end

-- Do stuff on logout.
function Addon:PLAYER_LOGOUT(event)
	self.frame:UnregisterEvent(event)
	self[event] = nil
end

Addon:OnLoad()