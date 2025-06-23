---------------------------------------------------------------------------------

-- Customized for OmniCD by permission of the copyright owner.

---------------------------------------------------------------------------------

--[[-----------------------------------------------------------------------------
Slider Widget
Graphical Slider, like, for Range values.
-------------------------------------------------------------------------------]]
local Type, Version = "InlineGroupList2Slider-OmniCDC", 1
local AceGUI = LibStub and LibStub("AceGUI-3.0", true)
if not AceGUI or (AceGUI:GetWidgetVersion(Type) or 0) >= Version then return end
local OmniCDC = LibStub("LibOmniCDC", true)

-- Lua APIs
local min, max, floor = math.min, math.max, math.floor
local tonumber, pairs = tonumber, pairs

-- WoW APIs
local PlaySound = PlaySound
local CreateFrame, UIParent = CreateFrame, UIParent

--[[-----------------------------------------------------------------------------
Support functions
-------------------------------------------------------------------------------]]
local function UpdateText(self)
	local value = self.value or 0
	self.label:SetText(floor(value * 100 + 0.5) / 100)
end

--[[-----------------------------------------------------------------------------
Scripts
-------------------------------------------------------------------------------]]
local function Control_OnEnter(frame)
	frame.obj:Fire("OnEnter")
	frame.handleRight:Show()
	frame.Thumb:SetColorTexture(1, 1, 1)
end

local function Control_OnLeave(frame)
	frame.obj:Fire("OnLeave")
	frame.handleRight:Hide()
	frame.Thumb:SetColorTexture(0.8, 0.624, 0)
end

local function Slider_OnValueChanged(frame, newvalue)
	local self = frame.obj
	if not frame.setup then
		if self.step and self.step > 0 then
			local min_value = self.min or 0
			newvalue = floor((newvalue - min_value) / self.step + 0.5) * self.step + min_value
		end
		if newvalue ~= self.value and not self.disabled then
			self.value = newvalue
			self:Fire("OnValueChanged", newvalue)
		end
		if self.value then
			UpdateText(self)
		end
	end
end

local function Slider_OnMouseUp(frame)
	local self = frame.obj
	self:Fire("OnMouseUp", self.value)
	-- s b update thumb position to the adjusted 'step' value here as this control is noRefresh
	self.slider:SetValue(self.value)
end

local function Slider_OnMouseWheel(frame, v)
	local self = frame.obj
	if not self.disabled then
		local value = self.value
		if v > 0 then
			value = min(value + (self.step or 1), self.max)
		else
			value = max(value - (self.step or 1), self.min)
		end
		self.slider:SetValue(value)
	end
end

--[[-----------------------------------------------------------------------------
Methods
-------------------------------------------------------------------------------]]
local methods = {
	["OnAcquire"] = function(self)
		self:SetWidth(200)
		self:SetHeight(24)
		self:SetDisabled(false)
		self:SetSliderValues(0,100,1)
		self:SetValue(0)
	end,

	-- ["OnRelease"] = nil,

	["SetDisabled"] = function(self, disabled)
		self.disabled = disabled
		if disabled then
			self.slider:EnableMouse(false)
			self.label:SetTextColor(.5, .5, .5)
			self.slider.Thumb:SetColorTexture(.5, .5, .5)
			self.slider.handleLeft:SetColorTexture(.5, .5, .5)
		else
			self.slider:EnableMouse(true)
			self.label:SetTextColor(1, .82, 0)
			self.slider.Thumb:SetColorTexture(0.8, 0.624, 0)
			self.slider.handleLeft:SetColorTexture(0.8, 0.624, 0)
		end
	end,

	["SetValue"] = function(self, value)
		self.slider.setup = true
		self.slider:SetValue(value)
		self.value = value
		UpdateText(self)
		self.slider.setup = nil
	end,

	["GetValue"] = function(self)
		return self.value
	end,

	["SetSliderValues"] = function(self, min_value, max_value, step)
		local frame = self.slider
		frame.setup = true
		self.min = min_value
		self.max = max_value
		self.step = step
		frame:SetMinMaxValues(min_value or 0,max_value or 100)
		frame:SetValueStep(step or 1)
		if self.value then
			frame:SetValue(self.value)
		end
		frame.setup = nil
	end,
}

--[[-----------------------------------------------------------------------------
Constructor
-------------------------------------------------------------------------------]]
local function Constructor()
	local frame = CreateFrame("Frame", nil, UIParent)
	frame:EnableMouse(true)

	local slider = CreateFrame("Slider", nil, frame)
	slider:SetOrientation("HORIZONTAL")
	slider:SetHeight(10)
	slider:SetHitRectInsets(0, 0, -8, -8)
	slider:SetPoint("LEFT")
	slider:SetPoint("RIGHT", -20, 0)

	slider.bg = slider:CreateTexture(nil, "BACKGROUND")
	slider.bg:SetTexelSnappingBias(0.0)
	slider.bg:SetSnapToPixelGrid(false)
	slider.bg:SetColorTexture(0.2, 0.2, 0.25)
	slider.bg:SetHeight(2 * OmniCDC.ACDPixelMult)
	slider.bg:SetPoint("LEFT")
	slider.bg:SetPoint("RIGHT")

	slider.Thumb = slider:CreateTexture(nil, "Artwork")
	slider.Thumb:SetSize(4 * OmniCDC.ACDPixelMult, 8 * OmniCDC.ACDPixelMult)
	slider.Thumb:SetTexelSnappingBias(0.0)
	slider.Thumb:SetSnapToPixelGrid(false)
	slider.Thumb:SetColorTexture(0.8, 0.624, 0)
	slider:SetThumbTexture(slider.Thumb)
	slider.handleLeft = slider:CreateTexture(nil, "Artwork")
	slider.handleLeft:SetTexelSnappingBias(0.0)
	slider.handleLeft:SetSnapToPixelGrid(false)
	slider.handleLeft:SetColorTexture(0.8, 0.624, 0)
	slider.handleLeft:SetPoint("TOPLEFT", slider.bg)
	slider.handleLeft:SetPoint("BOTTOMLEFT", slider.bg)
	slider.handleLeft:SetPoint("RIGHT", slider.Thumb, "LEFT")
	slider.handleRight = slider:CreateTexture(nil, "Artwork")
	slider.handleRight:SetTexelSnappingBias(0.0)
	slider.handleRight:SetSnapToPixelGrid(false)
	slider.handleRight:SetColorTexture(0.5, 0.5, 0.5)
	slider.handleRight:SetPoint("TOPRIGHT", slider.bg)
	slider.handleRight:SetPoint("BOTTOMRIGHT", slider.bg)
	slider.handleRight:SetPoint("LEFT", slider.Thumb, "RIGHT")
	slider.handleRight:Hide()
	slider:SetValue(0)
	slider:SetScript("OnValueChanged",Slider_OnValueChanged)
	slider:SetScript("OnEnter", Control_OnEnter)
	slider:SetScript("OnLeave", Control_OnLeave)
	slider:SetScript("OnMouseUp", Slider_OnMouseUp)
	--slider:SetScript("OnMouseWheel", Slider_OnMouseWheel) -- scroll content on mousewheel instead

	local label = frame:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall-OmniCDC")
	label:SetHeight(15)
	label:SetPoint("LEFT", slider, "RIGHT", 2, 0)

	local widget = {
		label	    = label,
		slider	    = slider,
		alignoffset = 25,
		frame	    = frame,
		type	    = Type
	}
	for method, func in pairs(methods) do
		widget[method] = func
	end
	slider.obj = widget

	return AceGUI:RegisterAsWidget(widget)
end

AceGUI:RegisterWidgetType(Type,Constructor,Version)
