----------------------------------------------
-- infDampening
----------------------------------------------

local infDampening = CreateFrame("Frame", "infDampening")
infDampening:SetScript("OnEvent", function(self, event, ...) self[event](self, event, ...) end)
infDampening:RegisterEvent("PLAYER_ENTERING_WORLD")

local dampening
local dampening_frame

--Upvalues.
local _ = _
local _G = _G
local IsShown = IsShown
local UnitDebuff = UnitDebuff

local function create()
	local anchorPoint = NUM_ALWAYS_UP_UI_FRAMES

	dampening_frame = CreateFrame("Frame", nil, UIParent)
	dampening_frame:SetSize(45, 24)
	dampening_frame:SetPoint("TOP", _G["AlwaysUpFrame"..anchorPoint], "BOTTOM")
	dampening_frame:Hide()

	--Dummy texture, doing this to mimic the default WorldState format.
	--Basically it is so it always lines up perfectly, regardless of UIScale, custom fonts etc.
	dampening_frame.texture = dampening_frame:CreateTexture(nil, "BACKGROUND")
	dampening_frame.texture:SetSize(42, 42)
	dampening_frame.texture:SetPoint("LEFT", -6, 0)

	dampening_frame.text = dampening_frame:CreateFontString(nil, "BACKGROUND")
	dampening_frame.text:SetPoint("LEFT", dampening_frame.texture, "RIGHT", -12, 10)
	dampening_frame.text:SetFontObject(GameFontNormalSmall)
end

--Hide the frame when we enter as well since with 6.0 you can queue for arena without leaving your current one.
function infDampening:PLAYER_ENTERING_WORLD()
	local _, instanceType = IsInInstance()
	if instanceType == "arena" then
		dampening = nil
		self:RegisterUnitEvent("UNIT_AURA", "player")
		if dampening_frame and dampening_frame:IsShown() then
			dampening_frame:Hide()
		end
	else
		self:UnregisterEvent("UNIT_AURA")
		if dampening_frame and dampening_frame:IsShown() then
			dampening_frame:Hide()
		end
	end
end

--Do our frame on UNIT_AURA when dampening is applied as occasionally NUM_ALWAYS_UP_UI_FRAMES is not ready even as late as when ARENA_OPPONENT_UPDATE[seen] fires.
--The other way would be to do a scheduled check, could work as well.
--Only create the frame once, always re-use afterwards.
function infDampening:UNIT_AURA(_, unit)
	local _, _, _, _, _, _, _, _, _, _, _, _, _, _, _, _, perc = UnitDebuff(unit, "Dampening")
	if perc then
		if not dampening then
			if dampening_frame then
				local anchorPoint = NUM_ALWAYS_UP_UI_FRAMES
				dampening_frame:SetPoint("TOP", _G["AlwaysUpFrame"..anchorPoint], "BOTTOM")
			else
				create()
			end
		end

		if dampening ~= perc then
			dampening = perc
			dampening_frame.text:SetText("Dampening: "..perc.."%")
			if not dampening_frame:IsShown() then
				dampening_frame:Show()
			end
		end
	end
end

