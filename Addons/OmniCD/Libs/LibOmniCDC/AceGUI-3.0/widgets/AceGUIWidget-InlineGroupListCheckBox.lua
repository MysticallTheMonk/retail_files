---------------------------------------------------------------------------------

-- Customized for OmniCD by permission of the copyright owner.

-- Used by OmniAuras' multiselect aura list (no editor func)
-- no img, label

---------------------------------------------------------------------------------

--[[-----------------------------------------------------------------------------
Checkbox Widget
-------------------------------------------------------------------------------]]
local Type, Version = "InlineGroupListCheckBox-OmniCDC", 1
local AceGUI = LibStub and LibStub("AceGUI-3.0", true)
if not AceGUI or (AceGUI:GetWidgetVersion(Type) or 0) >= Version then return end
local OmniCDC = LibStub("LibOmniCDC", true)

-- Lua APIs
local select, pairs = select, pairs

-- WoW APIs
local PlaySound = PlaySound
local CreateFrame, UIParent = CreateFrame, UIParent

local IMAGED_CHECKBOX_SIZE = 14

--[[-----------------------------------------------------------------------------
Support functions
-------------------------------------------------------------------------------]]

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
		self:SetDisabled(nil)
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

	frame:SetHitRectInsets(0, 10, 0, 0) -- s a (avoid misclicking)

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

	local widget = {
		checkbg	  = checkbg,
		check	  = check,
		text	  = text,
		frame	  = frame,
		type	  = Type
	}

	for method, func in pairs(methods) do
		widget[method] = func
	end

	return AceGUI:RegisterAsWidget(widget)
end

AceGUI:RegisterWidgetType(Type, Constructor, Version)
