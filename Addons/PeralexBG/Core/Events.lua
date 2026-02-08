-- ============================================================================
-- Peralex BG - Events.lua
-- Event handling for battleground detection and scoreboard updates
-- ============================================================================

local PE = _G.PeralexBG

-- Event frame
local eventFrame = CreateFrame("Frame", "PeralexBGEventFrame")
PE.eventFrame = eventFrame

-- Throttle for scoreboard updates
local lastScoreUpdate = 0
local SCORE_UPDATE_THROTTLE = 1.0 -- Update at most once per second

-- ============================================================================
-- EVENT HANDLERS
-- ============================================================================

local function OnEvent(self, event, ...)
    if PE[event] then
        PE[event](PE, ...)
    end
end

eventFrame:SetScript("OnEvent", OnEvent)

-- ============================================================================
-- BATTLEGROUND EVENTS
-- ============================================================================

function PE:PLAYER_ENTERING_WORLD(isInitialLogin, isReloadingUi)
    -- CRITICAL: Check if we just left an arena and cleanup stale data
    C_Timer.After(0.5, function()
        local isArena = (C_PvP.IsArena and C_PvP.IsArena()) or IsActiveBattlefieldArena() or false
        if isArena then
            -- We're in an arena, force cleanup to prevent stale frames
            if self.DB.debug then
                self:Print("PLAYER_ENTERING_WORLD - In arena, forcing cleanup")
            end
            self:OnLeaveBattleground()
            return
        end
    end)

    -- Check if we're in a BG on login/reload
    C_Timer.After(1, function()
        if self:IsInBattleground() then
            local matchState = C_PvP.GetActiveMatchState()

            if self.DB.debug then
                self:Print("PLAYER_ENTERING_WORLD - In BG, matchState: " .. tostring(matchState))
            end

            -- Enum.PvPMatchState: 0=Inactive, 1=Waiting, 2=StartUp, 3=Engaged, 4=Complete
            if matchState and matchState >= Enum.PvPMatchState.Engaged then
                -- Already in an active match (reload/late join)
                self:OnEnterBattleground()
                self:OnMatchActive()

                -- Additional delayed update for reload scenario
                C_Timer.After(1.5, function()
                    if self.states.isInBattleground and not self.states.isTestMode then
                        self:OnScoreboardUpdate()
                    end
                end)
            elseif matchState and matchState >= Enum.PvPMatchState.Waiting then
                -- In staging area waiting for match
                self:OnEnterBattleground()
            end
        else
            -- Not in BG/Arena, ensure cleanup happened
            if self.states.isInBattleground then
                if self.DB.debug then
                    self:Print("PLAYER_ENTERING_WORLD - Left PvP instance, forcing cleanup")
                end
                self:OnLeaveBattleground()
            end
        end
    end)
end

function PE:PLAYER_JOINED_PVP_MATCH()
    -- CRITICAL: Ignore arena matches completely
    local isArena = (C_PvP.IsArena and C_PvP.IsArena()) or IsActiveBattlefieldArena() or false
    if isArena then
        if self.DB.debug then
            self:Print("PLAYER_JOINED_PVP_MATCH fired (Arena - IGNORED)")
        end
        return
    end
    
    if self.DB.debug then
        self:Print("PLAYER_JOINED_PVP_MATCH fired")
    end
    self:OnEnterBattleground()
end

function PE:PVP_MATCH_ACTIVE()
    -- CRITICAL: Ignore arena matches completely
    local isArena = (C_PvP.IsArena and C_PvP.IsArena()) or IsActiveBattlefieldArena() or false
    if isArena then
        if self.DB.debug then
            self:Print("PVP_MATCH_ACTIVE fired (Arena - IGNORED)")
        end
        return
    end
    
    if self.DB.debug then
        self:Print("PVP_MATCH_ACTIVE fired - Match has started!")
    end

    -- Ensure we're marked as in BG
    if not self.states.isInBattleground then
        self:OnEnterBattleground()
    end

    self:OnMatchActive()
end

function PE:UPDATE_BATTLEFIELD_SCORE()
    -- CRITICAL: Ignore arena matches completely - prevents caching arena data
    local isArena = (C_PvP.IsArena and C_PvP.IsArena()) or IsActiveBattlefieldArena() or false
    if isArena then
        return
    end
    
    -- Throttle updates
    local now = GetTime()
    if now - lastScoreUpdate < SCORE_UPDATE_THROTTLE then
        return
    end
    lastScoreUpdate = now

    if self.DB.debug then
        self:Print("UPDATE_BATTLEFIELD_SCORE fired")
    end

    self:OnScoreboardUpdate()
end

function PE:PVP_MATCH_COMPLETE(winner, duration)
    if self.DB.debug then
        self:Print("PVP_MATCH_COMPLETE - Winner: " .. tostring(winner))
    end
    self:OnMatchComplete()
end

function PE:PVP_MATCH_INACTIVE()
    -- CRITICAL: Check if this was an arena match - if so, force cleanup
    local isArena = (C_PvP.IsArena and C_PvP.IsArena()) or IsActiveBattlefieldArena() or false

    if self.DB.debug then
        self:Print("PVP_MATCH_INACTIVE fired" .. (isArena and " (Arena - forcing cleanup)" or ""))
    end

    -- Always cleanup on match inactive (BG or Arena)
    self:OnLeaveBattleground()
end

function PE:PLAYER_LEAVING_WORLD()
    -- Don't hide frames on reload, only on actual zone change
end

-- Target/Focus change events for highlight updates
function PE:PLAYER_TARGET_CHANGED()
    if self.states.isInBattleground or self.states.isTestMode or self.states.isEpicBGTestMode then
        self:UpdateTargetHighlight()
        self:UpdateEpicBGTargetHighlight()
    end
end

function PE:PLAYER_FOCUS_CHANGED()
    if self.states.isInBattleground or self.states.isTestMode or self.states.isEpicBGTestMode then
        self:UpdateFocusHighlight()
        self:UpdateEpicBGFocusHighlight()
    end
end

-- Combat ends - process any queued frame updates
function PE:PLAYER_REGEN_ENABLED()
    -- CRITICAL: Ignore arena matches completely
    local isArena = (C_PvP.IsArena and C_PvP.IsArena()) or IsActiveBattlefieldArena() or false
    if isArena then
        return
    end
    
    if self.states.isInBattleground then
        -- Process pending Epic BG updates that were queued during combat
        if self.states.isEpicBG then
            self:ProcessPendingEpicBGUpdate()
        else
            -- For regular BGs, refresh frames with cached enemies
            local enemies = self:GetCachedEnemies()
            if enemies and #enemies > 0 then
                self:UpdateFrames(enemies)
            end
        end
    end
end

-- ============================================================================
-- BATTLEGROUND STATE MANAGEMENT
-- ============================================================================

function PE:OnEnterBattleground()
    if self.states.isTestMode then
        self:ExitTestMode()
    end
    if self.states.isEpicBGTestMode then
        self:ExitEpicBGTestMode()
    end
    
    self.states.isInBattleground = true
    
    local bgType = self:GetBattlegroundType()
    local isEpic = self:IsEpicBattleground()
    self.states.isEpicBG = isEpic
    
    if self.DB.debug then
        local matchState = C_PvP.GetActiveMatchState()
        local isFactional = C_PvP.IsMatchFactional and C_PvP.IsMatchFactional() or "N/A"
        self:Print("Entered battleground: " .. (bgType or "unknown") .. (isEpic and " (Epic)" or ""))
        self:Print("  MatchState: " .. tostring(matchState) .. ", Factional: " .. tostring(isFactional))
    end
    
    -- Check if frames should be shown in Epic BGs
    if isEpic and not self.DB.frames.enableEpicBGFrames then
        if self.DB.debug then
            self:Print("Epic BG frames disabled - not showing frames")
        end
        return
    end
    
    -- Initialize frame manager if needed
    if not self.anchorFrame then
        self:InitializeFrameManager()
    end
    
    -- For Epic BG, don't show regular anchor - Epic BG anchors are shown when enemies are populated
    -- For regular BG, anchor visibility is now controlled globally by showAnchor setting
    -- CRITICAL: Double-check we're not in arena before showing anchor
    local isArena = (C_PvP.IsArena and C_PvP.IsArena()) or IsActiveBattlefieldArena() or false
    if not isEpic and not isArena and self.DB.appearance.showAnchor then
        self:UpdateAnchorPosition()
        -- Note: Anchor visibility is now controlled globally, not auto-shown on BG entry
    end
    
    -- Request initial scoreboard data (may not be available yet)
    self:RequestScoreboardData()
end

function PE:OnMatchActive()
    -- Match has started - scoreboard data should be available now
    if self.DB.debug then
        local numScores = GetNumBattlefieldScores() or 0
        self:Print("OnMatchActive - NumScores: " .. numScores)
    end
    
    -- Request scoreboard data immediately
    self:RequestScoreboardData()
    
    -- Start periodic update ticker
    self:StartScoreboardTicker()
    
    -- Delayed initial update to allow data to populate
    C_Timer.After(0.5, function()
        if self.states.isInBattleground and not self.states.isTestMode then
            self:OnScoreboardUpdate()
        end
    end)
end

function PE:OnScoreboardUpdate()
    if not self.states.isInBattleground then return end
    if self.states.isTestMode then return end -- Don't override test mode
    if self.states.isEpicBGTestMode then return end -- Don't override Epic BG test mode
    
    -- Re-check Epic BG status (in case initial detection failed due to timing)
    -- This is important because map ID and scoreboard data may not be available immediately
    if not self.states.isEpicBG then
        local isEpic = self:IsEpicBattleground()
        if isEpic then
            self.states.isEpicBG = true
            if self.DB.debug then
                self:Print("Epic BG detected during scoreboard update")
            end
        end
    end
    
    -- Check if Epic BG and frames are disabled
    if self.states.isEpicBG and not self.DB.frames.enableEpicBGFrames then
        return
    end
    
    -- Update enemy cache from scoreboard
    local enemies = self:UpdateEnemyCache()
    
    if self.DB.debug then
        self:Print("OnScoreboardUpdate - Found " .. #enemies .. " enemies" .. (self.states.isEpicBG and " (Epic BG)" or ""))
    end
    
    -- Update frames with new data
    if #enemies > 0 then
        if self.states.isEpicBG then
            -- Epic BG: Use Epic BG frame pools with user's chosen layout
            -- Hide regular anchor/frames (handle combat safely)
            if self.anchorFrame then
                if InCombatLockdown() then
                    -- Queue anchor hide for after combat
                    self:QueueAnchorHideUpdate()
                else
                    self.anchorFrame:Hide()
                end
            end
            self:HideAllFrames()
            
            -- Use Epic BG frame system
            self:UpdateEpicBGFramesWithEnemies(enemies)
        else
            -- Regular BG: Use standard 15-frame pool
            -- Hide Epic BG anchors/frames if any
            self:HideAllEpicBGAnchorsAndFrames()
            
            -- Show anchor when we have enemies (only if showAnchor setting is enabled)
            -- CRITICAL: Double-check we're not in arena before showing anchor
            local isArena = (C_PvP.IsArena and C_PvP.IsArena()) or IsActiveBattlefieldArena() or false
            if self.anchorFrame and not self.anchorFrame:IsShown() and not isArena and self.DB.appearance.showAnchor then
                self:UpdateAnchorPosition()
                if not InCombatLockdown() then
                    self.anchorFrame:Show()
                end
            end
            
            self:UpdateFrames(enemies)
        end
    elseif self.DB.debug then
        -- Debug: show why we might have 0 enemies
        local numScores = GetNumBattlefieldScores() or 0
        local playerFaction = self:GetPlayerFaction()
        self:Print("  NumScores: " .. numScores .. ", PlayerFaction: " .. tostring(playerFaction))
    end
end

function PE:OnMatchComplete()
    -- Match ended, keep frames visible for review
    -- Could add end-game stats display here later
end

function PE:OnLeaveBattleground()
    self.states.isInBattleground = false
    self.states.isEpicBG = false
    
    -- Stop ticker
    self:StopScoreboardTicker()
    
    -- Hide regular frames
    self:HideAllFrames()
    
    -- Hide anchor (handle combat safely)
    if self.anchorFrame then
        if InCombatLockdown() then
            -- Queue anchor hide for after combat
            self:QueueAnchorHideUpdate()
        else
            self.anchorFrame:Hide()
        end
    end
    
    -- Hide Epic BG frames and anchors
    self:HideAllEpicBGAnchorsAndFrames()
    
    -- Clear cache
    self.enemyCache = {}
    
    if self.DB.debug then
        self:Print("Left battleground")
    end
end

-- ============================================================================
-- SCOREBOARD TICKER
-- ============================================================================

function PE:StartScoreboardTicker()
    if self.scoreboardTicker then return end
    
    self.scoreboardTicker = C_Timer.NewTicker(2, function()
        if self.states.isInBattleground and not self.states.isTestMode then
            self:RequestScoreboardData()
        else
            self:StopScoreboardTicker()
        end
    end)
end

function PE:StopScoreboardTicker()
    if self.scoreboardTicker then
        self.scoreboardTicker:Cancel()
        self.scoreboardTicker = nil
    end
end

-- ============================================================================
-- EVENT REGISTRATION
-- ============================================================================

function PE:RegisterBattlegroundEvents()
    local events = {
        "PLAYER_ENTERING_WORLD",
        "PLAYER_JOINED_PVP_MATCH",
        "PVP_MATCH_ACTIVE",
        "UPDATE_BATTLEFIELD_SCORE",
        "PVP_MATCH_COMPLETE",
        "PVP_MATCH_INACTIVE",
        "PLAYER_LEAVING_WORLD",
        "PLAYER_TARGET_CHANGED",
        "PLAYER_FOCUS_CHANGED",
        "PLAYER_REGEN_ENABLED", -- Combat ends - process queued macro updates
    }
    
    for _, event in ipairs(events) do
        eventFrame:RegisterEvent(event)
    end
end

function PE:UnregisterBattlegroundEvents()
    eventFrame:UnregisterAllEvents()
end

-- ============================================================================
-- DEBUG COMMANDS
-- ============================================================================

function PE:ToggleDebug()
    self.DB.debug = not self.DB.debug
    self:Print("Debug mode: " .. (self.DB.debug and "ON" or "OFF"))
end
