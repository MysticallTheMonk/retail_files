local E = unpack(select(2, ...))

local unpack = unpack
local tinsert = table.insert
local tremove = table.remove

function E:DeepCopy(source, blackList)
	local copy = {}
	if type(source) == "table" then
		for k, v in pairs(source) do
			if not blackList or not blackList[k] then
				copy[k] = self:DeepCopy(v)
			end
		end
	else
		copy = source
	end
	return copy
end

function E:RemoveEmptyDuplicateTables(dest, src)
	local copy = {}
	for k, v in pairs(dest) do
		local srcV = src[k]
		if type(v) == "table" and type(srcV) == "table" then
			copy[k] = self:RemoveEmptyDuplicateTables(v, srcV)
		elseif v ~= srcV then
			copy[k] = v
		end
	end
	return next(copy) and copy
end

local function SavePosition(f)
	local x = f:GetLeft()
	local y = f:GetTop()
	local s = f:GetEffectiveScale()
	x = x * s
	y = y * s

	local db = f.db
	db = db.manualPos[f.key]
	db.x = x
	db.y = y
end

E.LoadPosition = function(f, key)
	key = key or f.key
	local db = f.db
	db.manualPos[key] = db.manualPos[key] or {}
	db = db.manualPos[key]
	local x = db.x
	local y = db.y

	f:ClearAllPoints()
	if not x then
		f:SetPoint("CENTER", f.unit == "player" and UIParent or f.portrait, 0, key == "OmniAurasPlayerFrameHARMFUL" and 60 or 0)
		--SavePosition(f) -- don't save
	else
		local s = f:GetEffectiveScale()
		x = x / s
		y = y / s
		f:SetPoint("TOPLEFT", UIParent, "BOTTOMLEFT", x, y)
	end
end

E.OmniAurasAnchor_OnMouseDown = function(self, button)
	local bar = self:GetParent()
	bar = bar == UIParent and self or bar
	if button == "LeftButton" and not bar.isMoving then
		bar:StartMoving()
		bar.isMoving = true

	end
end

E.OmniAurasAnchor_OnMouseUp = function(self, button)
	local bar = self:GetParent()
	bar = bar == UIParent and self or bar
	if button == "LeftButton" and bar.isMoving then
		bar:StopMovingOrSizing()
		bar.isMoving = false
		SavePosition(bar)
	end
--	E:ACR_NotifyChange() -- udpate X/Y coordinates in option
end

do
	local Timers = CreateFrame("Frame")
	local unusedTimers = {}

	local Timer_OnFinished = function(self)
		self.func(unpack(self.args))
		tinsert(unusedTimers, self)
	end

	local TimerCancelled = function(self)
		if self.TimerAnim:IsPlaying() then
			self.TimerAnim:Stop()
			tinsert(unusedTimers, self)
		end
	end

	local function CreateTimer()
		local TimerAnim = Timers:CreateAnimationGroup()
		local Timer = TimerAnim:CreateAnimation("Alpha")
		Timer:SetScript("OnFinished", Timer_OnFinished)
		Timer.TimerAnim = TimerAnim
		Timer.Cancel = TimerCancelled
		return Timer
	end

	E.TimerAfter = function(delay, func, ...)
		if delay <= 0 then
			error("Timer requires a non-negative duration")
		end
		local Timer = tremove(unusedTimers)
		if not Timer then
			Timer = CreateTimer()
		end
		Timer.args = {...}
		Timer.func = func
		Timer:SetDuration(delay)
		Timer.TimerAnim:Play()
		return Timer
	end
end

E.BackdropTemplate = E.Libs.OmniCDC.SetBackdrop

E.Noop = function() end

E.write = function(...)
	print(format("%s%s|r: %s", E.userClassHexColor, E.AddOn, ...))
end

E.BLANK = {}

function E:CopyAdjustedColors(source, alpha)
	local copy = {}
	if type(source) == "table" then
		for k, v in pairs(source) do
			copy[k] = self:CopyAdjustedColors(v, alpha)
		end
	elseif alpha then
		copy = source * alpha
	else
		copy = source
	end
	return copy
end
