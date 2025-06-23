local _, ArenaAnalytics = ...; -- Addon Namespace
local Inspection = ArenaAnalytics.Inspection;

-- Local module aliases
local API = ArenaAnalytics.API;
local ArenaTracker = ArenaAnalytics.ArenaTracker;
local Internal = ArenaAnalytics.Internal;

-------------------------------------------------------------------------

-- The timer interval to use
local interval = 5;

local queue = {}
local currentInspectGUID = nil;
local timer = nil;

local lastNotifyInspect = 0;

local function isInQueue(GUID)
    for _,guid in ipairs(queue) do
        if(guid == GUID) then
            return true;
        end
    end
    return false;
end

local function addToQueue(GUID)
    if(GUID and not isInQueue(GUID)) then
        tinsert(queue, GUID);
    end
end

local function removeFromQueue(GUID)
    if(GUID) then
        for i,guid in ipairs(queue) do
            if(guid == GUID) then
                table.remove(queue, i);
                return;
            end
        end
    end
end

local function getPartyUnitToken(GUID)
    if(not GUID) then
        return nil;
    end

    for i=1, 4 do
        local unitToken = "party"..i;
        if(UnitGUID(unitToken) == GUID) then
            ArenaAnalytics:Log("getPartyUnitToken", unitToken);
            return unitToken;
        end
    end

    ArenaAnalytics:Log("getPartyUnitToken invalid.", GUID == nil);
    return nil;
end

function Inspection:RequestSpec(unitToken)
    if(not API.enableInspection or not unitToken or not API:IsInArena()) then
        return;
    end

    ArenaAnalytics:Log("RequestSpec:", unitToken, CanInspect(unitToken));

    if(not CanInspect(unitToken)) then
        return;
    end

    local GUID = UnitGUID(unitToken);
    if(not isInQueue(GUID)) then
        addToQueue(GUID);
    end

    Inspection:TryStartTimer();
end

function Inspection:TryInspectNext()
    if(not API.enableInspection) then
        return;
    end

    if(currentInspectGUID or (time() - lastNotifyInspect) < 3) then
        --ArenaAnalytics:Log("Skipping inspect attempt: Already/still inspecting!");
        return;
    end

    for _,GUID in pairs(queue) do
        if(not ArenaTracker:HasSpec(GUID)) then
            local unitToken = getPartyUnitToken(GUID);
            if(unitToken and CanInspect(unitToken)) then
                ArenaAnalytics:Log("NotifyInspect:", unitToken, time());
                currentInspectGUID = GUID;
                NotifyInspect(unitToken);
                lastNotifyInspect = time();
                return;
            end
        end
    end
end

local function HandleInspect_Internal(GUID)
    if(not API.enableInspection) then
        return;
    end

    if(not API:IsInArena()) then
        return;
    end

    ArenaAnalytics:Log("HandleInspect_Internal");

    local foundSpec = false;

    local unitToken = getPartyUnitToken(GUID);
    if(unitToken) then
        local spec_id = API:GetSpecialization(unitToken, true);
        ArenaAnalytics:Log("HandleInspect_Internal", unitToken, spec_id, Internal:GetClassAndSpec(spec_id));
        if(spec_id) then
            foundSpec = true;
            ArenaTracker:OnSpecDetected(GUID, spec_id);
        end
    end

    if(isInQueue(GUID)) then
        if(foundSpec) then
            removeFromQueue(GUID);
        end
    end
end

function Inspection:HandleInspectReady(GUID)
    if(not API.enableInspection) then
        return;
    end

    ArenaAnalytics:Log("HandleInspectReady");

    HandleInspect_Internal(GUID);

    if(currentInspectGUID) then
        if(GUID == currentInspectGUID) then
            ClearInspectPlayer();
        else
            ArenaAnalytics:Log("WARNING: Inspection:HandleInspectReady with different GUID from valid currentInspectGUID! May fail to clean up?");
        end

        currentInspectGUID = nil;
    end
end

-------------------------------------------------------------------------

function Inspection:TryStartTimer()
    if(not API.enableInspection) then
        return;
    end

    if(not API:IsInArena()) then
        ArenaAnalytics:Log("Inspection Timer rejected start: Not in arena!");
        Inspection:CancelTimer();
        return;
    end

    if(timer) then
        return;
    end

    ArenaAnalytics:Log("Starting new inspection ticker!");
    timer = C_Timer.NewTicker(interval, function()
        if(#queue == 0 or not API:IsInArena()) then
            ArenaAnalytics:Log("Inspection Timer shutting down!", #queue, API:IsInArena());
            Inspection:CancelTimer();
            return;
        end

        -- Begin inspecting next player in the queue
        Inspection:TryInspectNext();
    end)
end

function Inspection:CancelTimer()
    if(timer) then
        timer:Cancel();
        timer = nil;
        ArenaAnalytics:Log("Inspection Timer cancelled!");
    end
end

function Inspection:Clear()
    Inspection:CancelTimer();
    queue = {};
    
    if(currentInspectGUID) then
        ClearInspectPlayer();
    end
    currentInspectGUID = nil;

    ArenaAnalytics:Log("Inspection Cleared!");
end