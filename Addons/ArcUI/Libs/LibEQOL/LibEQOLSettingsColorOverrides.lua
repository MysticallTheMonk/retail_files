local MODULE_MAJOR, EXPECTED_MINOR = "LibEQOLSettingsMode-1.0", 6002002
local ok, lib = pcall(LibStub, MODULE_MAJOR)
if not ok or not lib then
	return
end
if lib.MINOR and lib.MINOR > EXPECTED_MINOR then
	return
end

LibEQOL_ColorOverridesMixin = CreateFromMixins(SettingsListElementMixin)

local DEFAULT_ROW_HEIGHT = 20
local DEFAULT_PADDING = 16
local DEFAULT_SPACING = 6

local function wipe(tbl)
	if not tbl then
		return
	end
	for k in pairs(tbl) do
		tbl[k] = nil
	end
end

function LibEQOL_ColorOverridesMixin:OnLoad()
	SettingsListElementMixin.OnLoad(self)
	self.container = self.ItemQualities or self.List or self
	self.ColorOverrideFramePool = CreateFramePool("FRAME", self.container, "ColorOverrideTemplate")
	self.colorOverrideFrames = {}
end

function LibEQOL_ColorOverridesMixin:Init(initializer)
	SettingsListElementMixin.Init(self, initializer)

	self.categoryID = initializer.data.categoryID
	self.entries = initializer.data.entries or {}
	self.getColor = initializer.data.getColor
	self.setColor = initializer.data.setColor
	self.getDefaultColor = initializer.data.getDefaultColor
	self.headerText = initializer.data.headerText or ""
	self.rowHeight = initializer.data.rowHeight or DEFAULT_ROW_HEIGHT
	self.basePadding = initializer.data.basePadding or DEFAULT_PADDING
	self.minHeight = initializer.data.minHeight
	self.fixedHeight = initializer.data.height
	self.fixedSpacing = initializer.data.spacing
	self.parentCheck = initializer.data.parentCheck
	self.colorizeLabel = initializer.data.colorizeLabel or initializer.data.colorizeText

	if self.Header then
		self.Header:SetText(self.headerText)
	end
	if self.NewFeature then
		self.NewFeature:SetShown(false)
	end

	if not self.callbacksRegistered then
		EventRegistry:RegisterCallback("Settings.Defaulted", self.ResetToDefaults, self)
		EventRegistry:RegisterCallback("Settings.CategoryDefaulted", function(_, category)
			if self.categoryID == category:GetID() then
				self:ResetToDefaults()
			end
		end, self)
		self.callbacksRegistered = true
	end

	self:RefreshRows()
end

function LibEQOL_ColorOverridesMixin:GetSpacing()
	local container = self.container
	if container and container.spacing then
		return container.spacing
	end
	return self.fixedSpacing or DEFAULT_SPACING
end

function LibEQOL_ColorOverridesMixin:RefreshRows()
	if not self.ColorOverrideFramePool then
		return
	end
	self.ColorOverrideFramePool:ReleaseAll()
	wipe(self.colorOverrideFrames)
	self.colorOverrideFrames = self.colorOverrideFrames or {}

	for index, entry in ipairs(self.entries or {}) do
		local frame = self.ColorOverrideFramePool:Acquire()
		frame.layoutIndex = index
		self:SetupRow(frame, entry)
		if self.rowHeight then
			frame:SetHeight(self.rowHeight)
		end
		frame:Show()
		self.colorOverrideFrames[#self.colorOverrideFrames + 1] = frame
	end

	if self.container and self.container.MarkDirty then
		self.container:MarkDirty()
	end
	self:RefreshAll()
	self:EvaluateState()
end

function LibEQOL_ColorOverridesMixin:SetupRow(frame, entry)
	frame.data = entry
	if frame.Text then
		local r, g, b = frame.Text:GetTextColor()
		frame._defaultTextColor = { r, g, b }
		frame.Text:SetText(entry.label or entry.key or "?")
	end
	frame.colorizeLabel = self.colorizeLabel
	if frame.ColorSwatch then
		frame.ColorSwatch:SetScript("OnClick", function()
			self:OpenColorPicker(frame)
		end)
	end
	self:ApplyTextColor(frame)
end

function LibEQOL_ColorOverridesMixin:ApplyTextColor(frame)
	if not frame or not frame.Text then
		return
	end
	local shouldColorize = frame.colorizeLabel
	if shouldColorize == nil then
		shouldColorize = self.colorizeLabel
	end
	if not shouldColorize then
		if frame._defaultTextColor then
			frame.Text:SetTextColor(frame._defaultTextColor[1], frame._defaultTextColor[2], frame._defaultTextColor[3], 1)
		end
		return
	end
		local r, g, b = 0, 0, 0
		if self.getColor then
			r, g, b = self.getColor(frame.data.key)
		end
		if not (r and g and b) and frame.ColorSwatch and frame.ColorSwatch.Color then
			r, g, b = frame.ColorSwatch.Color:GetVertexColor()
		end
		r, g, b = r or 1, g or 1, b or 1
		frame.Text:SetTextColor(r, g, b, 1)
	end

function LibEQOL_ColorOverridesMixin:RefreshRow(frame)
	if not (self.getColor and frame.ColorSwatch and frame.ColorSwatch.Color) then
		return
	end
	local r, g, b = self.getColor(frame.data.key)
	r, g, b = r or 1, g or 1, b or 1
	frame.ColorSwatch.Color:SetVertexColor(r, g, b)
	self:ApplyTextColor(frame)
end

function LibEQOL_ColorOverridesMixin:RefreshAll()
	for _, frame in ipairs(self.colorOverrideFrames or {}) do
		self:RefreshRow(frame)
	end
end

function LibEQOL_ColorOverridesMixin:ResetToDefaults()
	if not (self.getDefaultColor and self.setColor) then
		return
	end
	for _, entry in ipairs(self.entries or {}) do
		local r, g, b = self.getDefaultColor(entry.key)
		r, g, b = r or 1, g or 1, b or 1
		self.setColor(entry.key, r, g, b)
	end
	self:RefreshAll()
end

function LibEQOL_ColorOverridesMixin:OpenColorPicker(frame)
	if not self.setColor then
		return
	end
	local currentR, currentG, currentB = self.getColor(frame.data.key)
	currentR, currentG, currentB = currentR or 1, currentG or 1, currentB or 1

	ColorPickerFrame:SetupColorPickerAndShow({
		r = currentR,
		g = currentG,
		b = currentB,
		hasOpacity = false,
		swatchFunc = function()
			local r, g, b = ColorPickerFrame:GetColorRGB()
			self.setColor(frame.data.key, r, g, b)
			self:RefreshRow(frame)
		end,
		cancelFunc = function()
			local r, g, b = ColorPickerFrame:GetPreviousValues()
			r, g, b = r or currentR, g or currentG, b or currentB
			self.setColor(frame.data.key, r, g, b)
			self:RefreshRow(frame)
		end,
	})
end

function LibEQOL_ColorOverridesMixin:Release()
	if self.ColorOverrideFramePool then
		self.ColorOverrideFramePool:ReleaseAll()
	end
	SettingsListElementMixin.Release(self)
end

function LibEQOL_ColorOverridesMixin:EvaluateState()
	SettingsListElementMixin.EvaluateState(self)

	local enabled = true
	if self.parentCheck then
		enabled = self.parentCheck()
	end

	for _, frame in ipairs(self.colorOverrideFrames or {}) do
		if frame.ColorSwatch then
			frame.ColorSwatch:SetEnabled(enabled)
		end
		if frame.Text then
			frame.Text:SetFontObject(enabled and GameFontNormalSmall or GameFontDisableSmall)
		end
		self:ApplyTextColor(frame)
	end
end
