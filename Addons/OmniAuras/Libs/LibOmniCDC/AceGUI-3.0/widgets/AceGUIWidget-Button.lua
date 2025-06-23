---------------------------------------------------------------------------------

-- Customized for OmniCD by permission of the copyright owner.

---------------------------------------------------------------------------------

--[[-----------------------------------------------------------------------------
Button Widget
Graphical Button.
-------------------------------------------------------------------------------]]
--[[ s r
local Type, Version = "Button", 24
]]
local Type, Version = "Button-OmniCDC", 1
-- e
local AceGUI = LibStub and LibStub("AceGUI-3.0", true)
if not AceGUI or (AceGUI:GetWidgetVersion(Type) or 0) >= Version then return end
local OmniCDC = LibStub("LibOmniCDC", true)

-- Lua APIs
local pairs = pairs

-- WoW APIs
--local _G = _G -- s r
local PlaySound, CreateFrame, UIParent = PlaySound, CreateFrame, UIParent

--[[-----------------------------------------------------------------------------
Scripts
-------------------------------------------------------------------------------]]
local function Button_OnClick(frame, ...)
	AceGUI:ClearFocus()
	PlaySound(852) -- SOUNDKIT.IG_MAINMENU_OPTION
	frame.obj:Fire("OnClick", ...)
end

local function Control_OnEnter(frame)
	frame.obj:Fire("OnEnter")

	-- s b
	PlaySound(1217)
	local fadeOut = frame.fadeOut -- frame == inner
	if fadeOut:IsPlaying() then
		fadeOut:Stop()
	end
	frame.fadeIn:Play()
end

local function Control_OnLeave(frame)
	frame.obj:Fire("OnLeave")

	-- s b
	local fadeIn = frame.fadeIn
	if fadeIn:IsPlaying() then
		fadeIn:Stop()
	end
	frame.fadeOut:Play()
end

--[[-----------------------------------------------------------------------------
Methods
-------------------------------------------------------------------------------]]
local methods = {
	["OnAcquire"] = function(self)
		-- restore default values
		--[[ s r
		self:SetHeight(24)
		self:SetWidth(200)
		]]
		self:SetHeight(22)
		self:SetWidth(200) -- this does nothing with ACD fixed at width_multiplier: 170
		-- e
		self:SetDisabled(false)
		self:SetAutoWidth(false)
		self:SetText()
	end,

	-- ["OnRelease"] = nil,

	["SetText"] = function(self, text)
		self.text:SetText(text)
		if self.autoWidth then
			self:SetWidth(self.text:GetStringWidth() + 30)
		end
	end,

	["SetAutoWidth"] = function(self, autoWidth)
		self.autoWidth = autoWidth
		if self.autoWidth then
			self:SetWidth(self.text:GetStringWidth() + 30)
		end
	end,

	["SetDisabled"] = function(self, disabled)
		self.disabled = disabled
		if disabled then
			--[[ s r
			self.frame:Disable()
			]]
			self.inner:Disable()
			self.inner:SetBackdropColor(0.2, 0.2, 0.2) -- s a
		else
			--[[ s r
			self.frame:Enable()
			]]
			self.inner:Enable()
			self.inner:SetBackdropColor(0.725, 0.008, 0.008) -- s a
		end
	end
}

--[[-----------------------------------------------------------------------------
Constructor
-------------------------------------------------------------------------------]]
local function Constructor()
	--[[ s r
	local name = "AceGUI30Button" .. AceGUI:GetNextWidgetNum(Type)
	local frame = CreateFrame("Button", name, UIParent, "UIPanelButtonTemplate")
	frame:Hide()

	frame:EnableMouse(true)
	frame:SetScript("OnClick", Button_OnClick)
	frame:SetScript("OnEnter", Control_OnEnter)
	frame:SetScript("OnLeave", Control_OnLeave)

	local text = frame:GetFontString()
	text:ClearAllPoints()
	text:SetPoint("TOPLEFT", 15, -1)
	text:SetPoint("BOTTOMRIGHT", -15, 1)
	text:SetJustifyV("MIDDLE")
	]]
	local frame = CreateFrame("Frame", nil, UIParent)
	local name = "AceGUI30Button-OmniCDC" .. AceGUI:GetNextWidgetNum(Type)
	local inner = CreateFrame("Button", name, frame, "UIPanelButtonTemplate, BackdropTemplate")
	inner:SetPoint("TOPLEFT")
	inner:SetPoint("BOTTOMRIGHT", -10, 0)
	frame:Hide()

	inner:EnableMouse(true)
	inner:SetScript("OnClick", Button_OnClick)
	inner:SetScript("OnEnter", Control_OnEnter)
	inner:SetScript("OnLeave", Control_OnLeave)

	local text = inner:GetFontString()
	text:ClearAllPoints()
	text:SetPoint("TOPLEFT", 15, -1)
	text:SetPoint("BOTTOMRIGHT", -15, 1)
	text:SetJustifyV("MIDDLE")
	-- e

	-- s b
	-- inherits UIPanelButtonNoTooltipTemplate
	inner.Left:Hide() -- SetTexture is called repeatedly on disable etc, only Hide will work
	inner.Right:Hide()
	inner.Middle:Hide()
	inner:SetHighlightTexture(0) -- DF: nil throws error (Classic too), "" doesn't work (shows highlight texture)
	OmniCDC.SetBackdrop(inner, "ACD")
	inner:SetBackdropColor(0.725, 0.008, 0.008)
	inner:SetBackdropBorderColor(0, 0, 0)
	inner:SetNormalFontObject("GameFontHighlight-OmniCDC")
	inner:SetHighlightFontObject("GameFontHighlight-OmniCDC")
	inner:SetDisabledFontObject("GameFontDisable-OmniCDC")
	inner.bg = inner:CreateTexture(nil, "BORDER")
	if WOW_PROJECT_ID == WOW_PROJECT_CLASSIC then
		inner.bg:SetAllPoints()
	else
		inner.bg:SetTexelSnappingBias(0.0)
		inner.bg:SetSnapToPixelGrid(false)
		inner.bg:SetPoint("TOPLEFT", inner.TopEdge, "BOTTOMLEFT")
		inner.bg:SetPoint("BOTTOMRIGHT", inner.BottomEdge, "TOPRIGHT")
	end
	inner.bg:SetColorTexture(0.0, 0.6, 0.4)
	inner.bg:Hide()

	inner.fadeIn = inner.bg:CreateAnimationGroup()
	inner.fadeIn:SetScript("OnPlay", function() inner.bg:Show() end)
	local fadeIn = inner.fadeIn:CreateAnimation("Alpha")
	fadeIn:SetFromAlpha(0)
	fadeIn:SetToAlpha(1)
	fadeIn:SetDuration(0.4)
	fadeIn:SetSmoothing("OUT")

	inner.fadeOut = inner.bg:CreateAnimationGroup()
	inner.fadeOut:SetScript("OnFinished", function() inner.bg:Hide() end)
	local fadeOut = inner.fadeOut:CreateAnimation("Alpha")
	fadeOut:SetFromAlpha(1)
	fadeOut:SetToAlpha(0)
	fadeOut:SetDuration(0.3)
	fadeOut:SetSmoothing("OUT")
	-- e

	local widget = {
		text  = text,
		frame = frame,
		type  = Type,
		inner = inner -- s a
	}
	for method, func in pairs(methods) do
		widget[method] = func
	end
	inner.obj = widget -- s a

	return AceGUI:RegisterAsWidget(widget)
end

AceGUI:RegisterWidgetType(Type, Constructor, Version)
