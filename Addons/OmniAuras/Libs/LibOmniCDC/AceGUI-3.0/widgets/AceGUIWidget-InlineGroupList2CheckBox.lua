---------------------------------------------------------------------------------

-- Customized for OmniCD by permission of the copyright owner.

-- OmniCD: Adds spell to Editor on CTRL + click
-- arg = spellID,

---------------------------------------------------------------------------------

--[[-----------------------------------------------------------------------------
Checkbox Widget
-------------------------------------------------------------------------------]]
local Type, Version = "InlineGroupList2CheckBox-OmniCDC", 1
local AceGUI = LibStub and LibStub("AceGUI-3.0", true)
if not AceGUI or (AceGUI:GetWidgetVersion(Type) or 0) >= Version then return end
local OmniCDC = LibStub("LibOmniCDC", true)

-- Lua APIs
local select, pairs = select, pairs

-- WoW APIs
local PlaySound = PlaySound
local CreateFrame, UIParent = CreateFrame, UIParent

local DEFAULT_ICON_SIZE = 21 -- tree icon: 18
local IMAGED_CHECKBOX_SIZE = 16

--[[-----------------------------------------------------------------------------
Support functions
-------------------------------------------------------------------------------]]
local function AlignImage(self)
	local img = self.image:GetTexture()
	self.text:ClearAllPoints()
	if not img then
		self.text:SetPoint("LEFT", self.checkbg, "RIGHT", 5, 0) -- our box is 10 smaller
		self.text:SetPoint("RIGHT", -10, 0)
	else
		self.text:SetPoint("LEFT", self.image, "RIGHT", 5, 0)
		self.text:SetPoint("RIGHT", -10, 0)
	end
end

--[[-----------------------------------------------------------------------------
Scripts
-------------------------------------------------------------------------------]]
local function Control_OnEnter(frame)
	frame.obj:Fire("OnEnter")
	frame.obj.checkbg.border:SetColorTexture(0.5, 0.5, 0.5)
end

local function Control_OnLeave(frame)
	frame.obj:Fire("OnLeave")
	frame.obj.checkbg.border:SetColorTexture(0.2, 0.2, 0.25)
end

local function CheckBox_OnMouseDown(frame)
	local self = frame.obj
	if not self.disabled then
		if self.image:GetTexture() then
			self.text:SetPoint("LEFT", self.image, "RIGHT", 6, -1)
		else
			self.text:SetPoint("LEFT", self.checkbg, "RIGHT", 6, -1)
		end

		local arg = self.arg
		if arg and arg > 0 and IsControlKeyDown() then
			local app = _G[self.appName]
			app = type(app) == "table" and (app[1] or app)
			if app and type(app.EditSpell) == "function" then
				app.EditSpell(nil, tostring(arg))
			end
		end
	end
	AceGUI:ClearFocus()
end

local function CheckBox_OnMouseUp(frame)
	local self = frame.obj
	if not self.disabled and frame:IsMouseMotionFocus() then
		self:ToggleChecked()

		if self.checked then
			PlaySound(856) -- SOUNDKIT.IG_MAINMENU_OPTION_CHECKBOX_ON
		else -- for both nil and false (tristate)
			PlaySound(857) -- SOUNDKIT.IG_MAINMENU_OPTION_CHECKBOX_OFF
		end

		self:Fire("OnValueChanged", self.checked)
		AlignImage(self)
	end
end

--[[-----------------------------------------------------------------------------
Methods
-------------------------------------------------------------------------------]]
local methods = {
	["OnAcquire"] = function(self)
		self:SetValue(false)
		-- height is calculated from the width and required space for the description
		self:SetHeight(24)
		self:SetWidth(200)
		self:SetImage()
		self:SetDisabled(nil)
		self.arg = nil
		self.appName = nil
	end,

	-- ["OnRelease"] = nil,

	["SetDisabled"] = function(self, disabled)
		self.disabled = disabled
		if disabled then
			self.frame:Disable()
			self.text:SetTextColor(0.5, 0.5, 0.5)
			--SetDesaturation(self.check, true)
			self.check:SetAtlas("checkmark-minimal-disabled", true)
			if self.desc then
				self.desc:SetTextColor(0.5, 0.5, 0.5)
			end
			self.checkbg.bg:SetColorTexture(0.5, 0.5, 0.5)
		else
			self.frame:Enable()
			self.text:SetTextColor(1, 1, 1)
			--SetDesaturation(self.check, false)
			self.check:SetAtlas("checkmark-minimal", true)
			if self.desc then
				self.desc:SetTextColor(1, 1, 1)
			end
			self.checkbg.bg:SetColorTexture(0, 0, 0)
		end
	end,

	["SetValue"] = function(self, value)
		self.checked = value
		if value then
			--SetDesaturation(self.check, false)
			self.check:Show()
		else
			--SetDesaturation(self.check, false)
			self.check:Hide()
		end

		self:SetDisabled(self.disabled)
	end,

	["GetValue"] = function(self)
		return self.checked
	end,

	["ToggleChecked"] = function(self)
		self:SetValue(not self:GetValue())
	end,

	["SetLabel"] = function(self, label)
		self.text:SetText(label)
	end,

	["SetImage"] = function(self, path, ...)
		local image = self.image
		image:SetTexture(path)

		if image:GetTexture() then
			local n = select("#", ...)
			if n == 4 or n == 8 then
				image:SetTexCoord(...)
			else
				image:SetTexCoord(0, 1, 0, 1)
			end
		end
		AlignImage(self)
	end,

	["SetArg"] = function(self, arg, appName) -- arg is number
		self.arg = arg
		self.appName = appName
	end
}

--[[-----------------------------------------------------------------------------
Constructor
-------------------------------------------------------------------------------]]
local function Constructor()
	local frame = CreateFrame("Button", nil, UIParent)
	frame:Hide()
	frame:EnableMouse(true)
	frame:SetScript("OnEnter", Control_OnEnter)
	frame:SetScript("OnLeave", Control_OnLeave)
	frame:SetScript("OnMouseDown", CheckBox_OnMouseDown)
	frame:SetScript("OnMouseUp", CheckBox_OnMouseUp)

	local checkbg = CreateFrame("Frame", nil, frame)
	checkbg:SetWidth(IMAGED_CHECKBOX_SIZE)
	checkbg:SetHeight(IMAGED_CHECKBOX_SIZE)
	checkbg:SetPoint("LEFT")
	checkbg.border = checkbg:CreateTexture(nil, "BACKGROUND")
	checkbg.border:SetTexelSnappingBias(0.0)
	checkbg.border:SetSnapToPixelGrid(false)
	checkbg.border:SetAllPoints()
	checkbg.border:SetColorTexture(0.2, 0.2, 0.25)
	checkbg.bg = checkbg:CreateTexture(nil, "BORDER")
	checkbg.bg:SetTexelSnappingBias(0.0)
	checkbg.bg:SetSnapToPixelGrid(false)
	checkbg.bg:SetColorTexture(0, 0, 0)
	local edgeSize = OmniCDC.ACDPixelMult
	checkbg.bg:SetPoint("TOPLEFT", checkbg, "TOPLEFT", edgeSize, -edgeSize)
	checkbg.bg:SetPoint("BOTTOMRIGHT", checkbg, "BOTTOMRIGHT", -edgeSize, edgeSize)

	local check = checkbg:CreateTexture(nil, "OVERLAY")
	check:SetPoint("TOPLEFT", -5, 5)
	check:SetPoint("BOTTOMRIGHT", 5, -5)
	--check:SetTexture(130751) -- Interface\\Buttons\\UI-CheckBox-Check
	--check:SetTexCoord(0, 1, 0, 1)
	check:SetAtlas("checkmark-minimal", true)
	check:SetBlendMode("BLEND")

	local text = frame:CreateFontString(nil, "OVERLAY", "GameFontHighlight-OmniCDC")
	text:SetJustifyH("LEFT")
	text:SetHeight(18)
	text:SetPoint("LEFT", checkbg, "RIGHT")
	text:SetPoint("RIGHT", -10, 0)

	local image = frame:CreateTexture(nil, "OVERLAY")
	image:SetHeight(DEFAULT_ICON_SIZE)
	image:SetWidth(DEFAULT_ICON_SIZE)
	image:SetPoint("LEFT", checkbg, "RIGHT", 5, 0)

	local widget = {
		checkbg	  = checkbg,
		check	  = check,
		text	  = text,
		image	  = image,
		frame	  = frame,
		type	  = Type
	}

	for method, func in pairs(methods) do
		widget[method] = func
	end

	return AceGUI:RegisterAsWidget(widget)
end

AceGUI:RegisterWidgetType(Type, Constructor, Version)
