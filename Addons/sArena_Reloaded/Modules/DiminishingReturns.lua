local drCategories = sArenaMixin.drCategories

function sArenaFrameMixin:ResetDRCooldownTextColors()
	if not sArenaMixin.isMidnight then
		for i = 1, #drCategories do
			local drFrame = self[drCategories[i]]
			if drFrame and drFrame.Cooldown.sArenaText then
				drFrame.Cooldown.sArenaText:SetTextColor(1, 1, 1, 1)
			end
		end
	else
		if self.drFrames then
			for _, drFrame in ipairs(self.drFrames) do
				if drFrame and drFrame.Cooldown and drFrame.Cooldown.sArenaText then
					drFrame.Cooldown.sArenaText:SetTextColor(1, 1, 1, 1)
				end
			end
		end

		if self.fakeDRFrames then
			for _, fakeDRFrame in ipairs(self.fakeDRFrames) do
				if fakeDRFrame and fakeDRFrame.Cooldown and fakeDRFrame.Cooldown.sArenaText then
					fakeDRFrame.Cooldown.sArenaText:SetTextColor(1, 1, 1, 1)
				end
			end
		end
	end
end

if sArenaMixin.isMidnight then return end

local isRetail = sArenaMixin.isRetail
-- DR's are static 18 seconds on Retail and dynamic 15-20 on MoP.
-- 0.5 leeway is added for Retail
-- Can be changed in gui, /sarena
local drTime = (isRetail and 18.5) or 20 -- ^^^^^^^^^^^^
local drList = sArenaMixin.drList
local severityColor = {
	[1] = { 0, 1, 0, 1 },
	[2] = { 1, 1, 0, 1 },
	[3] = { 1, 0, 0, 1 }
}

local GetTime = GetTime
local GetSpellTexture = GetSpellTexture or C_Spell.GetSpellTexture

function sArenaMixin:UpdateDRTimeSetting()
	if not self.db.profile.drResetTimeFix then
		self.db.profile.drResetTime = (isRetail and 18.5 or 20)
		self.db.profile.drResetTimeFix = true
		self.db.profile.drResetTimeDEL = nil
	end
    drTime = self.db.profile.drResetTime or (isRetail and 18.5 or 20)
end

function sArenaFrameMixin:FindDR(combatEvent, spellID)
	local category = drList[spellID]

	-- Check if this DR category is enabled (considering per-spec, per-class, or global settings)
	local categoryEnabled = false
	local db = self.parent.db.profile

	if db.drCategoriesPerSpec then
		local specKey = sArenaMixin.playerSpecID or 0
		local perSpec = db.drCategoriesSpec or {}
		local specCategories = perSpec[specKey]
		if specCategories ~= nil and specCategories[category] ~= nil then
			categoryEnabled = specCategories[category]
		else
			categoryEnabled = db.drCategories[category]
		end
	elseif db.drCategoriesPerClass then
		local classKey = sArenaMixin.playerClass
		local perClass = db.drCategoriesClass or {}
		local classCategories = perClass[classKey]
		if classCategories ~= nil and classCategories[category] ~= nil then
			categoryEnabled = classCategories[category]
		else
			categoryEnabled = db.drCategories[category]
		end
	else
		categoryEnabled = db.drCategories[category]
	end

	if not categoryEnabled then return end

	local frame = self[category]
	local currTime = GetTime()

	if (combatEvent == "SPELL_AURA_REMOVED" or combatEvent == "SPELL_AURA_BROKEN") then
        local startTime, startDuration = frame.Cooldown:GetCooldownTimes()
        startTime, startDuration = startTime/1000, startDuration/1000

        -- Guard against division by zero
        if startDuration == 0 or (1 - ((currTime - startTime) / startDuration)) == 0 then
            sArenaMixin:Print("|cFFFF0000BUG: DR failed:|r " .. spellID .. ", " .. combatEvent .. ", " .. currTime .. ", " .. startTime .. ", " .. startDuration)
            return
        end

        local newDuration = drTime / (1 - ((currTime - startTime) / startDuration))
        local newStartTime = drTime + currTime - newDuration

        frame:Show()
        frame.Cooldown:SetCooldown(newStartTime, newDuration)

        return
	elseif (combatEvent == "SPELL_AURA_APPLIED" or combatEvent == "SPELL_AURA_REFRESH") then
		local unit = self.unit

		for i = 1, 30 do
			local auraData = C_UnitAuras.GetAuraDataByIndex(unit, i, "HARMFUL")

            if auraData then
                if not auraData.spellId then break end

                if (auraData.duration and spellID == auraData.spellId) then
                    frame:Show()
                    frame.Cooldown:SetCooldown(currTime, auraData.duration + drTime)
                    break
                end
            end
		end
	end
	-- Determine which texture to use for the DR icon.
	local useStatic = self.parent.db.profile.drStaticIcons
	local usePerSpec = self.parent.db.profile.drStaticIconsPerSpec
	local usePerClass = self.parent.db.profile.drStaticIconsPerClass
	local textureID = nil

	if usePerSpec and useStatic then
		local perSpec = self.parent.db.profile.drIconsPerSpec
		local specKey = sArenaMixin.playerSpecID or 0
		if perSpec and perSpec[specKey] and perSpec[specKey][category] then
			textureID = perSpec[specKey][category]
		end
	elseif usePerClass and useStatic then
		local perClass = self.parent.db.profile.drIconsPerClass
		if perClass and perClass[sArenaMixin.playerClass] and perClass[sArenaMixin.playerClass][category] then
			textureID = perClass[sArenaMixin.playerClass][category]
		end
	end

	if not textureID and useStatic then
		textureID = self.parent.db.profile.drIcons[category]
	end

	if not textureID then
		textureID = GetSpellTexture(spellID)
	end

	frame.Icon:SetTexture(textureID)

	-- Check border settings
	local layout = self.parent.db.profile.layoutSettings[self.parent.db.profile.currentLayout]
	local blackDRBorder = layout.dr and layout.dr.blackDRBorder
	local thickPixelBorder = layout.dr and layout.dr.thickPixelBorder

	-- Set border colors
	local borderColor = blackDRBorder and {0, 0, 0, 1} or severityColor[frame.severity]

	frame.Border:SetVertexColor(unpack(borderColor))
    if frame.PixelBorder then
		if thickPixelBorder and blackDRBorder then
			-- Use black for thick pixel borders when blackDRBorder is enabled
			frame.PixelBorder:SetVertexColor(0, 0, 0, 1)
		elseif thickPixelBorder then
			-- Use severity color for thick pixel borders when blackDRBorder is disabled
			frame.PixelBorder:SetVertexColor(unpack(severityColor[frame.severity]))
		else
			-- Use border color for regular pixel borders (fallback)
			frame.PixelBorder:SetVertexColor(unpack(borderColor))
		end
    end
    if frame.__MSQ_New_Normal then
        frame.__MSQ_New_Normal:SetDesaturated(true)
        frame.__MSQ_New_Normal:SetVertexColor(unpack(severityColor[frame.severity]))
    end
	local drText = frame.DRTextFrame.DRText
	if drText then
		if frame.severity == 1 then
			drText:SetText("½")
		elseif frame.severity == 2 then
			drText:SetText("¼")
		else
			drText:SetText("%")
		end
		drText:SetTextColor(unpack(severityColor[frame.severity]))
	end

	if self.parent.db.profile.colorDRCooldownText and frame.Cooldown.sArenaText then
		frame.Cooldown.sArenaText:SetTextColor(unpack(severityColor[frame.severity]))
	end

	frame.severity = frame.severity + 1
	if frame.severity > 3 then
		frame.severity = 3
	end
end


function sArenaFrameMixin:UpdateDRCooldownReverse()
    local reverse = self.parent.db.profile.invertDRCooldown
    for i = 1, #sArenaMixin.drCategories do
        local category = sArenaMixin.drCategories[i]
        local frame = self[category]
        if frame and frame.Cooldown then
            frame.Cooldown:SetReverse(reverse)
        end
    end
end

function sArenaFrameMixin:UpdateDRPositions()
	local layoutdb = self.parent.layoutdb
	local numActive = 0
	local frame, prevFrame
	local spacing = layoutdb.dr.spacing
	local growthDirection = layoutdb.dr.growthDirection

	for i = 1, #drCategories do
		frame = self[drCategories[i]]

		if (frame:IsShown()) then
			frame:ClearAllPoints()
			if (numActive == 0) then
				-- First frame, offset due to unique DR sizes
				local offset = (sArenaMixin.drBaseSize or 28) / 2
				if (growthDirection == 4) then
					frame:SetPoint("RIGHT", self, "CENTER", layoutdb.dr.posX + offset, layoutdb.dr.posY)
				elseif (growthDirection == 3) then
					frame:SetPoint("LEFT", self, "CENTER", layoutdb.dr.posX - offset, layoutdb.dr.posY)
				elseif (growthDirection == 1) then
					frame:SetPoint("TOP", self, "CENTER", layoutdb.dr.posX, layoutdb.dr.posY + offset)
				elseif (growthDirection == 2) then
					frame:SetPoint("BOTTOM", self, "CENTER", layoutdb.dr.posX, layoutdb.dr.posY - offset)
				end
			else
				if (growthDirection == 4) then
					frame:SetPoint("RIGHT", prevFrame, "LEFT", -spacing, 0)
				elseif (growthDirection == 3) then
					frame:SetPoint("LEFT", prevFrame, "RIGHT", spacing, 0)
				elseif (growthDirection == 1) then
					frame:SetPoint("TOP", prevFrame, "BOTTOM", 0, -spacing)
				elseif (growthDirection == 2) then
					frame:SetPoint("BOTTOM", prevFrame, "TOP", 0, spacing)
				end
			end
			numActive = numActive + 1
			prevFrame = frame
		end
	end
end

function sArenaFrameMixin:ResetDR()
	for i = 1, #drCategories do
		self[drCategories[i]].Cooldown:Clear()
	end
end