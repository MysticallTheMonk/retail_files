local addonName, addon = ...
local hbd = LibStub("HereBeDragons-2.0")

if (not addon.WOW_MAINLINE) then
    return
end

-- This function was removed in 11.0.2, so bringing back an implementation
-- thanks to Kaliel in his tracker
local QuestPOIGetIconInfo = QuestPOIGetIconInfo
if not QuestPOIGetIconInfo then
	QuestPOIGetIconInfo = function(questID)
		local x, y
		local completed = C_QuestLog.IsComplete(questID)
		local mapID = GetQuestUiMapID(questID)
		if mapID and mapID > 0 then
			local quests = C_QuestLog.GetQuestsOnMap(mapID)
			if quests then
				for _, info in pairs(quests) do
					if info.questID == questID then
						x = info.x
						y = info.y
						break
					end
				end
			end
		end
		return completed, x, y
	end
end

local enableClicks = false       -- True if waypoint-clicking is enabled to set points
local modifier                  -- A string representing click-modifiers "CAS", etc.

local modTbl = {
    C = IsControlKeyDown,
    A = IsAltKeyDown,
    S = IsShiftKeyDown,
}

local L = TomTomLocals


-- Hello, I am the POI waypoint arbiter, I handle the setting and clearing of
-- temporary waypoints for the POI integration
local lastWaypoint

local function SetPOIWaypoint(map, x, y, title)
    -- Set the new waypoint
    lastWaypoint = TomTom:AddWaypoint(map, x, y, {
        title = title,
        persistent = false,
        arrivaldistance = TomTom.profile.poi.arrival,
    })
end

local function ClearPOIWaypoint()
    TomTom:RemoveWaypoint(lastWaypoint)
end


local function GetQuestIndexForWatch(questWatchIndex)
    local questID = C_QuestLog.GetQuestIDForQuestWatchIndex(questWatchIndex)
    local questIndex = questID and C_QuestLog.GetLogIndexForQuestID(questID)
    return questIndex
end

-- This function and the related events/hooks are used to automatically
-- update the crazy arrow to the closest quest waypoint.
local scanning          -- This function is not re-entrant, stop that
local function ObjectivesChanged()
    local enableClosest = TomTom.profile.poi.setClosest

    -- This function should only run if enableClosest is set
    if not enableClosest then
        return
    end

    -- This function may be called while we are processing this function
    -- so stop that from happening.
    if scanning then
        return
    else
        scanning = true
    end

    local map = C_Map.GetBestMapForUnit("player")
    if not map then
        scanning = false
        return
    end

    local player = C_Map.GetPlayerMapPosition(map, "player")
    if not player then
        scanning = false
        return
    end

    local px, py = player:GetXY()

    -- Bail out if we can't get the player's position
    if not px or not py or px <= 0 or py <= 0 then
        scanning = false
        return
    end

    -- THIS CVAR MUST BE CHANGED BACK!
    local cvar = GetCVarBool("questPOI")
    SetCVar("questPOI", 1)

    local closest
    local closestdist = math.huge

    -- This function relies on the above CVar being set, and updates the icon
    -- position information so it can be queried via the API
    QuestPOIUpdateIcons()

    -- Scan through every quest that is tracked, and find the closest one
    local watchIndex = 1
    while true do
        local questIndex = GetQuestIndexForWatch(watchIndex)

        if not questIndex then
            break
        end

        local qid = C_QuestLog.GetQuestIDForQuestWatchIndex(watchIndex)
        C_QuestLog.SetSelectedQuest(qid)
        C_QuestLog.GetNextWaypoint(qid)

        local completed, x, y, objective = QuestPOIGetIconInfo(qid)
        local qmap = GetQuestUiMapID(qid)

        if x and y then
            local dist = hbd:GetZoneDistance(map, px, py, qmap, x, y)
            if dist and (dist < closestdist) then
                closest = watchIndex
                closestdist = dist
            end
        end
        watchIndex = watchIndex + 1
    end

    if closest then
        local questIndex = GetQuestIndexForWatch(closest)
        local title = C_QuestLog.GetTitleForLogIndex(questIndex)
        local qid = C_QuestLog.GetQuestIDForQuestWatchIndex(closest)
        local completed, x, y, objective = QuestPOIGetIconInfo(qid)
        local map = GetQuestUiMapID(qid)

        if completed then
            title = "Turn in: " .. title
        end

        local setWaypoint = true
        if lastWaypoint then
            -- This is a hack that relies on the UID format, do not use this
            -- in your addons, please.
            if TomTom:WaypointHasSameMapXYTitle(lastWaypoint, map, x, y, title) then
                -- This is the same waypoint, do nothing
                setWaypoint = false
            else
                -- This is a new waypoint, clear the previous one
                ClearPOIWaypoint()
            end
        end

        if setWaypoint then
            SetPOIWaypoint(map, x, y, title)

            -- Check and see if the Crazy arrow is empty, and use it if so
            if TomTom:IsCrazyArrowEmpty() then
                TomTom:SetCrazyArrow(lastWaypoint, TomTom.profile.poi.arrival, title)
            end
        end
    else
        -- No closest waypoint was found, so remove one if its already set
        if lastWaypoint then
            ClearPOIWaypoint()
            lastWaypoint = nil
        end
    end

    SetCVar("questPOI", cvar and 1 or 0)
    scanning = false
end

local eventFrame = CreateFrame("Frame")
eventFrame:RegisterEvent("QUEST_POI_UPDATE")
eventFrame:RegisterEvent("QUEST_LOG_UPDATE")

eventFrame:SetScript("OnEvent", function(self, event, ...)
    if event == "QUEST_POI_UPDATE" then
        ObjectivesChanged()
    elseif event == "QUEST_LOG_UPDATE" then
        ObjectivesChanged()
    end
end)


function TomTom:EnableDisablePOIIntegration()
    local enableClosest = TomTom.profile.poi.setClosest

    if not enableClosest and lastWaypoint then
        TomTom:RemoveWaypoint(lastWaypoint)
        lastWaypoint = nil
    elseif enableClosest then
        ObjectivesChanged()
    end
end
