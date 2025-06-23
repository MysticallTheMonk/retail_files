---------------------------------------------------------------------------------

-- Customized for OmniCD by permission of the copyright owner.

-- <spell list>
-- type = "group",
-- dialogControl = "InlineGroupList2-OmniCDC",
-- arg = classFileName (optional -  display class color on bg)

---------------------------------------------------------------------------------

--[[-----------------------------------------------------------------------------
InlineGroup Container
Simple container widget that creates a visible "box" with an optional title.
-------------------------------------------------------------------------------]]
local Type, Version = "InlineGroupList2-OmniCDC", 1
local AceGUI = LibStub and LibStub("AceGUI-3.0", true)
if not AceGUI or (AceGUI:GetWidgetVersion(Type) or 0) >= Version then return end
local OmniCDC = LibStub("LibOmniCDC", true)

-- Lua APIs
local pairs = pairs

-- WoW APIs
local CreateFrame, UIParent = CreateFrame, UIParent

--[[-----------------------------------------------------------------------------
Methods
-------------------------------------------------------------------------------]]
local methods = {
	["OnAcquire"] = function(self)
		self:SetWidth(300)
		self:SetHeight(100)
		self:SetTitle("")
	end,

	-- ["OnRelease"] = nil,

	["SetTitle"] = function(self, class) -- set spell name, mo tooltip, class bg
		local c = class and RAID_CLASS_COLORS[class]
		if c then
			self.frame.framebg:SetColorTexture(c.r, c.g, c.b, 1)
			self.frame.framebg:SetGradient("HORIZONTAL", CreateColor(1, 1, 1, 0.5), CreateColor(1, 1, 1, 0))
			self.frame.framebg:Show()
		else
			self.frame.framebg:Hide()
		end
	end,

	["LayoutFinished"] = function(self, width, height)
		if self.noAutoHeight then return end
		self:SetHeight((height or 0))
	end,

	["OnWidthSet"] = function(self, width)
		local content = self.content
		local contentwidth = width - 20
		if contentwidth < 0 then
			contentwidth = 0
		end
		content:SetWidth(contentwidth)
		content.width = contentwidth
	end,

	["OnHeightSet"] = function(self, height)
		local content = self.content
		local contentheight = height - 20
		if contentheight < 0 then
			contentheight = 0
		end
		content:SetHeight(contentheight)
		content.height = contentheight
	end
}

--[[-----------------------------------------------------------------------------
Constructor
-------------------------------------------------------------------------------]]
local function Constructor()
	local frame = CreateFrame("Frame", nil, UIParent)
	frame:SetFrameStrata("FULLSCREEN_DIALOG")
	frame.framebg = frame:CreateTexture(nil, "BACKGROUND")
	frame.framebg:SetTexelSnappingBias(0.0)
	frame.framebg:SetSnapToPixelGrid(false)
	frame.framebg:SetPoint("TOPLEFT")
	frame.framebg:SetPoint("BOTTOMLEFT")
	frame.framebg:SetWidth(170) -- classcolor
	local frameBottomBorder = frame:CreateTexture(nil, "BORDER")
	frameBottomBorder:SetPoint("BOTTOMLEFT")
	frameBottomBorder:SetPoint("TOPRIGHT", frame, "BOTTOMRIGHT", 0, OmniCDC.ACDPixelMult)
	frameBottomBorder:SetColorTexture(0, 0, 0)
	frameBottomBorder:SetTexelSnappingBias(0.0)
	frameBottomBorder:SetSnapToPixelGrid(false)

	--Container Support
	local content = CreateFrame("Frame", nil, frame)
	content:SetPoint("TOPLEFT", 5, -2)
	content:SetPoint("BOTTOMRIGHT")

	local widget = {
		frame	  = frame,
		content	  = content,
		type	  = Type
	}
	for method, func in pairs(methods) do
		widget[method] = func
	end

	return AceGUI:RegisterAsContainer(widget)
end

AceGUI:RegisterWidgetType(Type, Constructor, Version)
