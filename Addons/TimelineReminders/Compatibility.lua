local addOnName, LRP = ...

local flavorToNumber = {
    Cata = 4,
    Mainline = 10
}

local flavor = C_AddOns.GetAddOnMetadata(addOnName, "X-Flavor")
local flavorNumber = flavorToNumber[flavor]

LRP.isCata = flavorNumber == 4
LRP.isRetail = flavorNumber == 10
LRP.flavorNumber = flavorNumber

function LRP.GetSpellInfo(spell)
	if C_Spell and C_Spell.GetSpellInfo then
		return C_Spell.GetSpellInfo(spell)
	else
		local name, rank, iconID, castTime, minRange, maxRange, spellID, originalIconID = GetSpellInfo(spell)

		if name then
			return {
				name = name,
				iconID = iconID,
				originalIconID = originalIconID,
				castTime = castTime,
				minRange = minRange,
				maxRange = maxRange,
				spellID = spellID,
				rank = rank
			}
		end
	end
end

-- Sometimes the addon seems to load before info from GetSpecializationInfoForClassID is available
-- Cache the info, so that we can reuse it when this is the case
function LRP.GetSpecializationInfoForClassID(classID, specIndex)
	if not LiquidRemindersSaved.specializationInfoCache[classID] then
		LiquidRemindersSaved.specializationInfoCache[classID] = {}
	end

	local id, name, description, icon, role = GetSpecializationInfoForClassID(classID, specIndex)
	
	if name then
		LiquidRemindersSaved.specializationInfoCache[classID][specIndex] = { -- Update cached info
			id = id,
			name = name,
			description = description,
			icon = icon,
			role = role
		}

		return id, name, description, icon, role
	else
		local cachedInfo = LiquidRemindersSaved.specializationInfoCache[classID][specIndex]

		if not cachedInfo then return end

		return cachedInfo.id, cachedInfo.name, cachedInfo.description, cachedInfo.icon, cachedInfo.role
	end
end