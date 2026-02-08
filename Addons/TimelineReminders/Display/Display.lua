local _, LRP = ...

local CombatLogGetCurrentEventInfo = CombatLogGetCurrentEventInfo

local L = LRP.L
local eventFrame = CreateFrame("Frame")

-- Difficulty ID (payload for ENCOUNTER_START) to internal difficulty ID
local difficultyIDs

-- [difficultyID = {internalDifficultyID, instanceType}]
if LRP.isRetail then
	difficultyIDs = {
		[8] = {2, 2},  -- Mythic Keystone (party)
		[14] = {1, 1}, -- Normal (raid)
 		[15] = {1, 1}, -- Heroic (raid)
		[16] = {2, 1}, -- Mythic (raid)
		[23] = {2, 2}, -- Mythic (party)
	}
else
	difficultyIDs = {
		[3] = {1, 1}, -- 10 player raid
		[4] = {1, 1}, -- 25 player raid
		[5] = {2, 1}, -- 10 player raid (heroic)
		[6] = {2, 1}, -- 25 player raid (heroic)
		[175] = {1, 1}, -- 10 player raid
		[176] = {1, 1}, -- 25 player raid
		[193] = {2, 1}, -- 10 player raid (heroic)
		[194] = {2, 1}, -- 25 player raid (heroic)
	}
end

-- Used to record death data
local encounterStart, phaseStart, currentEncounter, currentPhase
local phaseEvents = {
	SPELL_CAST_START = {},
	SPELL_CAST_SUCCESS = {},
	SPELL_AURA_APPLIED = {},
	SPELL_AURA_REMOVED = {},
	UNIT_SPELLCAST_START = {},
	UNIT_SPELLCAST_SUCCEEDED = {},
	UNIT_DIED = {},
	CHAT_MSG_MONSTER_YELL = {},
}

local simulationTimers = {}
local queuedReminders = {}
local reminderEvents = {
	SPELL_CAST_START = {},
	SPELL_CAST_SUCCESS = {},
	SPELL_AURA_APPLIED = {},
	SPELL_AURA_REMOVED = {},
	UNIT_SPELLCAST_START = {},
	UNIT_SPELLCAST_SUCCEEDED = {},
	UNIT_DIED = {},
	CHAT_MSG_MONSTER_YELL = {},
}

function LRP:InitializeDisplay()
	LRP.anchors = {
		TEXT = LRP:CreateReminderAnchor("TEXT"),
		SPELL = LRP:CreateReminderAnchor("SPELL")
	}
end

-- Returns encounter info for an encounter ID
-- Can also be used to check if an encounter still exists in data
-- It's possible that there's still reminder data from raids that are not current
-- We don't want to delete that data (safety precaution), but we also do not want to display the reminders
local function GetEncounterInfo(encounterID, difficulty)
	for _, instanceTypeInfo in pairs(LRP.timelineData) do
		for _, instanceInfo in ipairs(instanceTypeInfo) do
			for _, encounterInfo in ipairs(instanceInfo.encounters) do
				if encounterInfo.id == encounterID and encounterInfo[difficulty] and encounterInfo[difficulty].events and next(encounterInfo[difficulty].events) then
					return encounterInfo
				end
			end
		end
	end
end

local function DequeueAllReminders()
	for id, timer in pairs(queuedReminders) do
		timer:Cancel()

		queuedReminders[id] = nil
	end
end

-- Hides all active reminders and dequeues all upcoming reminders
local function CleanUp()
	eventFrame:UnregisterEvent("COMBAT_LOG_EVENT_UNFILTERED")
	eventFrame:UnregisterEvent("UNIT_SPELLCAST_START")
	eventFrame:UnregisterEvent("UNIT_SPELLCAST_SUCCEEDED")
	eventFrame:UnregisterEvent("CHAT_MSG_MONSTER_YELL")

	LRP.anchors.TEXT:HideAllReminders()
	LRP.anchors.SPELL:HideAllReminders()

	DequeueAllReminders()
end

local function OnEncounterEnd()
	currentEncounter = nil

	CleanUp()
end

local function QueueReminder(id, reminderData, simulationOffset, simulationEventTime)
	local encounterTime = reminderData.trigger.time
	local duration = reminderData.trigger.duration

	-- Don't show reminders that will have already run out (only relevant for simulations)
	if simulationEventTime + encounterTime <= simulationOffset then return end

	-- Don't queue reminders with negative time. This usually means the duration is longer than the relative time to phase change
	local queueTime = math.max(simulationEventTime + encounterTime - simulationOffset - duration, 0)

	queuedReminders[id] = C_Timer.NewTimer(
		queueTime,
		function()
			LRP.anchors[reminderData.display.type]:ShowReminder(id, reminderData, simulationOffset - simulationEventTime)

			queuedReminders[id] = nil
		end
	)
end

-- Offset is used for starting a simulation at arbitrary times in the fight
-- e.g. if the simulation is started at 1:20, then simulation offset is 80
local function OnEncounterStart(encounterID, difficulty, instanceType, simulationOffset)
	if not encounterID then return end
	if not difficulty then return end
	
	local encounterInfo = GetEncounterInfo(encounterID, difficulty)

	if not encounterInfo then return end

	CleanUp() -- Safety precaution

	eventFrame:RegisterEvent("COMBAT_LOG_EVENT_UNFILTERED")
	eventFrame:RegisterEvent("UNIT_SPELLCAST_START")
	eventFrame:RegisterEvent("UNIT_SPELLCAST_SUCCEEDED")
	eventFrame:RegisterEvent("CHAT_MSG_MONSTER_YELL")

	-- These variables are used to save death data
	encounterStart = GetTime()
	phaseStart = encounterStart
	currentEncounter = encounterID
	currentPhase = 0
	phaseEvents = {
		SPELL_CAST_START = {},
		SPELL_CAST_SUCCESS = {},
		SPELL_AURA_APPLIED = {},
		SPELL_AURA_REMOVED = {},
		UNIT_SPELLCAST_START = {},
		UNIT_SPELLCAST_SUCCEEDED = {},
		UNIT_DIED = {},
		CHAT_MSG_MONSTER_YELL = {}
	}

	reminderEvents = {
		SPELL_CAST_START = {},
		SPELL_CAST_SUCCESS = {},
		SPELL_AURA_APPLIED = {},
		SPELL_AURA_REMOVED = {},
		UNIT_SPELLCAST_START = {},
		UNIT_SPELLCAST_SUCCEEDED = {},
		UNIT_DIED = {},
		CHAT_MSG_MONSTER_YELL = {}
	}

	local profile = LiquidRemindersSaved.settings.timeline.selectedProfiles[encounterID][difficulty]
	local addOnReminders = LiquidRemindersSaved.reminders[encounterID] and LiquidRemindersSaved.reminders[encounterID][difficulty] and LiquidRemindersSaved.reminders[encounterID][difficulty][profile] or {}
	local combinedReminders = {addOnReminders} -- Addon reminders are always displayed

	-- MRT note reminders
	if LRP.MRTReminders and (instanceType == 1 or not LiquidRemindersSaved.settings.timeline.ignoreNoteInDungeon) then
		-- Personal note
		if LiquidRemindersSaved.settings.timeline.personalNoteReminders then
			table.insert(combinedReminders, LRP.MRTReminders.personal.ALL or {})
			table.insert(combinedReminders, LRP.MRTReminders.personal[encounterID] or {})
		end

		-- Public note
		if LiquidRemindersSaved.settings.timeline.publicNoteReminders then
			table.insert(combinedReminders, LRP.MRTReminders.public.ALL or {})
			table.insert(combinedReminders, LRP.MRTReminders.public[encounterID] or {})
		end
	end

	-- Fill the reminderEvents table
	-- This table contains the events that have at least one reminder relative to them
	-- When events happen during the fight, they are checked against this table and reminders are queued as needed
	for _, reminders in ipairs(combinedReminders) do
		for id, reminderData in pairs(reminders) do
			if LRP:IsRelevantReminder(reminderData) then
				local relativeTo = reminderData.trigger.relativeTo

				if relativeTo then
					local event = relativeTo.event
					local value = relativeTo.value
					local count = relativeTo.count

					if not reminderEvents[event][value] then
						reminderEvents[event][value] = {
							count = 0
						}
					end

					if not reminderEvents[event][value][count] then
						reminderEvents[event][value][count] = {}
					end

					reminderEvents[event][value][count][id] = reminderData
				else
					QueueReminder(id, reminderData, simulationOffset or 0, 0)
				end
			end
		end
	end

	-- Fill the phaseEvents table
	-- This table is used to keep track of what phase we are in
	-- This is used to record the timing of the player's death
	for phaseCount, phaseInfo in ipairs(encounterInfo[difficulty].phases) do
		local event = phaseInfo.event
		local value = phaseInfo.value
		local count = phaseInfo.count

		if not phaseEvents[event][value] then
			phaseEvents[event][value] = {
				count = 0
			}
		end

		phaseEvents[event][value][count] = phaseCount
	end

	-- Clear death data 10s into an encounter
	-- We don't want to clear it on a boss reset, so 15s is just an arbitrary fight length that we consider not a reset
	C_Timer.After(
		15,
		function()
			if currentEncounter then
				LiquidRemindersSaved.deathData[currentEncounter] = nil
			end
		end
	)
end

local function OnDeath(destGUID)
	if not currentEncounter then return end
	if destGUID ~= UnitGUID("player") then return end

	LiquidRemindersSaved.deathData[currentEncounter] = {
		phase = currentPhase,
		time = GetTime() - phaseStart
	}

	LRP:BuildDeathLine()
end

local function OnEvent(event, value, simulationOffset, simulationEventTime)
	local eventTable = reminderEvents[event]
	local phaseTable = phaseEvents[event]

	if not eventTable then return end
	if not value then return end

	-- For CHAT_MSG_MONSTER_YELL, we match() the values rather than use them as indices directly
	if event == "CHAT_MSG_MONSTER_YELL" then
		-- Ragnaros
		if value:match(L.ragnaros_intermission_end2) or value:match(L.ragnaros_intermission_end3) then
			value = L.ragnaros_intermission_end1
		end

		for v in pairs(eventTable) do
			if v ~= "" then -- Don't match with empty string (in case user forgot to enter something)
				if value:match(v) then
					value = v

					break
				end
			end
		end
	else
		-- Ragnaros
		if value == 98952 or value == 98953 then
			value = 98951
		end
	end

	-- Check if any reminders are relative to this event
	-- If so, queue them
	if eventTable[value] then
		eventTable[value].count = eventTable[value].count + 1

		local reminders = eventTable[value][eventTable[value].count]

		if reminders then
			for id, reminderData in pairs(reminders) do
				QueueReminder(id, reminderData, simulationOffset or 0, simulationEventTime or 0)
			end
		end
	end
	
	-- Check if this event starts a new phase (for use in death data)
	if phaseTable[value] then
		phaseTable[value].count = phaseTable[value].count + 1

		local newPhase = phaseTable[value][phaseTable[value].count]

		-- If this event starts a new phase
		if newPhase then
			currentPhase = newPhase
			phaseStart = GetTime()
		end
	end	
end

function LRP:StartSimulation(totalDuration, simulationOffset)
	LRP.simulation = true

	LRP.anchors.TEXT:Hide()
	LRP.anchors.SPELL:Hide()

	local timelineInfo = LRP:GetCurrentTimelineInfo()
	local timelineData = timelineInfo.timelineData
	local instanceType = timelineInfo.instanceType
	local encounterID = timelineInfo.encounterID
	local difficulty = timelineInfo.difficulty

	OnEncounterStart(encounterID, difficulty, instanceType, simulationOffset)

	-- Queue all encounter events
	-- If the events happen before the simulation offset, fire them immediately and pass the offset
	for _, eventInfo in ipairs(timelineData.events) do
		if eventInfo.event then
			for _, entry in ipairs(eventInfo.entries) do
				local encounterTime = entry[1]
				local eventBeforeOffset = encounterTime - simulationOffset < 0

				table.insert(
					simulationTimers,
					C_Timer.NewTimer(
						math.max(encounterTime - simulationOffset, 0),
						function()
							OnEvent(eventInfo.event, eventInfo.value, eventBeforeOffset and simulationOffset, eventBeforeOffset and encounterTime)
						end
					)
				)
			end
		end
	end

	-- Queue end of encounter
	table.insert(
		simulationTimers,
		C_Timer.NewTimer(
			totalDuration - simulationOffset,
			function()
				LRP:StopSimulation()
			end
		)
	)

	LRP:StartSimulateLine(simulationOffset)
end

function LRP:StopSimulation()
	LRP.simulation = false

	-- Dequeue all timers
	for _, timer in pairs(simulationTimers) do
		timer:Cancel()
	end

	simulationTimers = {}

	OnEncounterEnd()
	LRP:StopSimulateLine()
end

eventFrame:RegisterEvent("ENCOUNTER_START")
eventFrame:RegisterEvent("ENCOUNTER_END")

eventFrame:SetScript(
    "OnEvent",
    function(_, event, ...)
		if event == "ENCOUNTER_START" then
			local encounterID, _, difficultyID = ...

			local internalDifficultyID = difficultyIDs[difficultyID] and difficultyIDs[difficultyID][1]
			local instanceType = difficultyIDs[difficultyID] and difficultyIDs[difficultyID][2]

			LRP.window:Hide() -- This also stops any simulation that is running

			if not (internalDifficultyID and instanceType) then
				return
			end

			OnEncounterStart(encounterID, internalDifficultyID, instanceType)
		elseif event == "ENCOUNTER_END" then
			OnEncounterEnd()
		elseif event == "COMBAT_LOG_EVENT_UNFILTERED" then
			local _, subEvent, _, _, _, _, _, destGUID, _, _, _, spellID = CombatLogGetCurrentEventInfo()

			if subEvent == "UNIT_DIED" then
				-- If the player died, record the death time for the death lines
				if destGUID == UnitGUID("player") then
					OnDeath(destGUID)
				else
					-- If a creature died, use their npc ID as the spell ID for OnEvent()
					local npcID = LRP:NpcID(destGUID)

					if npcID then
						OnEvent(subEvent, npcID)
					end
				end
			else
				OnEvent(subEvent, spellID)
			end
		elseif event == "UNIT_SPELLCAST_START" or event == "UNIT_SPELLCAST_SUCCEEDED" then
			local _, castGUID, spellID = ...

			if not castGUID then return end

			OnEvent(event, spellID)
		elseif event == "CHAT_MSG_MONSTER_YELL" then
			local text = ...

			OnEvent(event, text)
		end
    end
)