---------------------------------------------------------------------------------

-- Customized for OmniCD by permission of the copyright owner.

-- <spell list>
-- Parameters for spell list layout with multiselect checkboxes
-- name = '',  -- checkbox names are shown if '', else hidden (use this for header w/ grey bg)
-- type = "multiselect",
-- dialogControl = "InlineGroupList-OmniCDC",
-- image (optional)
-- imageCoords (optional)
-- arg = classFileName (optional -  display class color on bg)

---------------------------------------------------------------------------------

-- Widgets backdrop

--[[-----------------------------------------------------------------------------
InlineGroup Container
Simple container widget that creates a visible "box" with an optional title.
-------------------------------------------------------------------------------]]
local Type, Version = "InlineGroupList-OmniCDC", 1
local AceGUI = LibStub and LibStub("AceGUI-3.0", true)
if not AceGUI or (AceGUI:GetWidgetVersion(Type) or 0) >= Version then return end
local OmniCDC = LibStub("LibOmniCDC", true)

-- Lua APIs
local pairs = pairs

-- WoW APIs
local CreateFrame, UIParent = CreateFrame, UIParent

-- s b <spell list>
local DEFAULT_ICON_SIZE = 21
local USE_ICON_BACKDROP = nil --WOW_PROJECT_ID ~= WOW_PROJECT_CLASSIC -- really need to reduce frame counts
local TITLE_WIDTH = 170 -- Aceconfig width_multiplier = 170
--[[-----------------------------------------------------------------------------
Support functions
-------------------------------------------------------------------------------]]
local function AlignImage(self)
	local img = self.image:GetTexture()
	self.titletext:ClearAllPoints()
	self.titletext:SetPoint("BOTTOMRIGHT")
	if img then
		if USE_ICON_BACKDROP then
			self.imagebg:Show()
		else
			self.image:Show()
		end
		self.titletext:SetPoint("TOPLEFT", 10 + DEFAULT_ICON_SIZE, 0)
	else
		if USE_ICON_BACKDROP then
			self.imagebg:Hide()
		else
			self.image:Hide()
		end
		self.titletext:SetPoint("TOPLEFT", 10, 0)
	end
end

-- tooltip on imagebg
local function OptionOnMouseOver(title) -- frame = title frame
	local desc = title.desc;
	if ( not desc ) then
		return;
	end

	local AceConfigDialog = LibStub("AceConfigDialog-3.0-OmniCDC")
	local tooltip = AceConfigDialog.tooltip;
	tooltip:SetOwner(title, "ANCHOR_TOPRIGHT");
	if ( type(desc) == "string" ) then
		local linktype = desc:match(".*|H(%a+):.+|h.+|h.*");
		if ( linktype ) then
			tooltip:SetHyperlink(desc);
			local spellID = strmatch(desc, "spell:(%d+):")
			if spellID then
				tooltip:AddLine("\nID: " .. spellID, 1, 1, 1, true)
			end
		else
			local frame = title:GetParent()
			local name = frame.obj.titletext:GetText();
			tooltip:SetText(name, 1, .82, 0, true);
			tooltip:AddLine(desc, 1, 1, 1, true);
		end
	end
	tooltip:Show();
end
local function OptionOnMouseLeave(frame)
	local AceConfigDialog = LibStub("AceConfigDialog-3.0-OmniCDC")
	AceConfigDialog.tooltip:Hide();
end

-- e

--[[-----------------------------------------------------------------------------
Methods
-------------------------------------------------------------------------------]]
local methods = {
	["OnAcquire"] = function(self)
		self:SetWidth(300)
		self:SetHeight(100)
		self:SetTitle("") -- makes desc class nil
		self:SetImage()
	end,

	-- s b <spell list>
	["SetImage"] = function(self, path,  ...)
		local image = self.image
		image:SetTexture(path)

		if image:GetTexture() then
			local n = select("#", ...)
			if n == 4 or n == 8 then
				if USE_ICON_BACKDROP then -- override
					self.imagebg:SetHeight(DEFAULT_ICON_SIZE)
					image:SetTexCoord(0.07, 0.93, 0.07, 0.93)
				else
					image:SetHeight(DEFAULT_ICON_SIZE)
					image:SetTexCoord(...)
				end
			else
				image:SetTexCoord(0, 1, 0, 1)
			end
		end
		AlignImage(self)
	end,
	-- e

	-- ["OnRelease"] = nil,

	["SetTitle"] = function(self, name, desc, class) -- set spell name, mo tooltip, class bg
		self.titletext:SetText(name)
		self.title.desc = desc
		if class then
			self.arg = class
			local classColor = RAID_CLASS_COLORS[class]
			local r, g, b = classColor.r, classColor.g, classColor.b
			self.frame.framebg:SetColorTexture(r, g, b, .4)
			--self.frame.framebg:SetGradient("HORIZONTAL", CreateColor(1, 1, 1, 0.5), CreateColor(1, 1, 1, 0.05)) -- v24
			self.frame.framebg:Show()
		else
			self.frame.framebg:Hide()
		end
	end,

	["LayoutFinished"] = function(self, width, height) -- from Flow-Nopadding-OmniCDC
		if self.noAutoHeight then return end
		self:SetHeight(height or 0)
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
	frame.framebg:SetAllPoints()
	local frameBottomBorder = frame:CreateTexture(nil, "BORDER")
	frameBottomBorder:SetPoint("BOTTOMLEFT")
	frameBottomBorder:SetPoint("TOPRIGHT", frame, "BOTTOMRIGHT", 0, OmniCDC.ACDPixelMult)
	frameBottomBorder:SetColorTexture(0, 0, 0)
	frameBottomBorder:SetTexelSnappingBias(0.0)
	frameBottomBorder:SetSnapToPixelGrid(false)

	local title = CreateFrame("Frame", nil, frame)
	title:SetPoint("TOPLEFT")
	title:SetPoint("BOTTOMLEFT")
	title:SetWidth(TITLE_WIDTH)
	title:SetScript("OnEnter", OptionOnMouseOver)
	title:SetScript("OnLeave", OptionOnMouseLeave)

	local image, imagebg
	if USE_ICON_BACKDROP then
		imagebg = CreateFrame("Frame", nil, title)
		imagebg:SetHeight(DEFAULT_ICON_SIZE) -- 24 is frames full height
		imagebg:SetWidth(DEFAULT_ICON_SIZE)
		imagebg:SetPoint("LEFT", title, "LEFT", 2, 0)

		imagebg.border = imagebg:CreateTexture(nil, "BORDER")
		imagebg.border:SetTexelSnappingBias(0.0)
		imagebg.border:SetSnapToPixelGrid(false)
		imagebg.border:SetAllPoints()
		imagebg.border:SetColorTexture(0.2, 0.2, 0.05)

		image = imagebg:CreateTexture(nil, "OVERLAY")
		image:SetTexelSnappingBias(0.0)
		image:SetSnapToPixelGrid(false)
		local edgeSize = OmniCDC.PixelMult
		image:SetPoint("TOPLEFT", imagebg, "TOPLEFT", edgeSize, -edgeSize)
		image:SetPoint("BOTTOMRIGHT", imagebg, "BOTTOMRIGHT", -edgeSize, edgeSize)
	else
		image = title:CreateTexture(nil, "OVERLAY")
		image:SetHeight(DEFAULT_ICON_SIZE)
		image:SetWidth(DEFAULT_ICON_SIZE)
		image:SetPoint("LEFT", title, "LEFT", 2, 0)
	end

	local titletext = title:CreateFontString(nil, "OVERLAY", "GameFontHighlight-OmniCDC")
	titletext:SetPoint("TOPLEFT", 10, 0)
	titletext:SetPoint("TOPRIGHT", -10, 0)
	titletext:SetJustifyH("LEFT")
	titletext:SetHeight(18)

	--Container Support
	local content = CreateFrame("Frame", nil, frame)
	content:SetPoint("TOPLEFT", title, "TOPRIGHT", 2, 0) -- 5 align with header (InlineGroupList2 content)
	content:SetPoint("BOTTOMRIGHT")

	local widget = {
		frame	    = frame,
		content	    = content,
		image	    = image,
		title	    = title,
		titletext   = titletext,
		type	    = Type,
	}

	if USE_ICON_BACKDROP then
		widget.imagebg = imagebg
	end

	for method, func in pairs(methods) do
		widget[method] = func
	end

	return AceGUI:RegisterAsContainer(widget)
end

AceGUI:RegisterWidgetType(Type, Constructor, Version)
