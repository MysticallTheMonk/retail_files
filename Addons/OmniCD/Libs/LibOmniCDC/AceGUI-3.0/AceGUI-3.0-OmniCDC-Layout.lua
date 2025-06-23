local AceGUI = LibStub("AceGUI-3.0")

local xpcall = xpcall

local function errorhandler(err)
	return geterrorhandler()(err)
end

local function safecall(func, ...)
	if func then
		return xpcall(func, errorhandler, ...)
	end
end

AceGUI:RegisterLayout("Flow-NowrapFix-OmniCDC", -- single row InlineGroupList (no wrap)
	function(content, children)
		local rowheight = 0
		local width = 0

		local n = #children
		for i = 1, n do
			local child = children[i]
			local frame = child.frame
			frame:ClearAllPoints()
			if i == 1 then
				frame:SetPoint("TOPLEFT", content)
				rowheight = frame.height or frame:GetHeight() or 0
			else
				frame:SetPoint("TOPLEFT", content, "TOPLEFT", width, 0)
			end
			local childWidth = frame.width or frame:GetWidth() or 0
			width = width + childWidth
			frame:Show()
		end

		safecall(content.obj.LayoutFinished, content.obj, nil, rowheight + 3) -- set actual row height
	end)

AceGUI:RegisterLayout("Flow-Nopadding-OmniCDC", -- scroll frame container for InlineGroupList rows (no top-bottom padding)
	function(content, children)
		local height = 0
		local rowheight = 0

		local n = #children
		for i = 1, n do
			local child = children[i]
			local frame = child.frame

			frame:ClearAllPoints()
			if i == 1 then
				frame:SetPoint("TOPLEFT", content)
				rowheight = frame.height or frame:GetHeight() or 0
			else
				height = height + rowheight
				frame:SetPoint("TOPLEFT", content, "TOPLEFT", 0, -height)
			end

			frame:SetPoint("RIGHT", content)

			frame:Show()
		end

		height = height + rowheight -- add last rowheight
		safecall(content.obj.LayoutFinished, content.obj, nil, height)
	end)
