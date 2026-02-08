-- ============================================================================
-- Peralex BG - Core.lua
-- Clean slate - UI shell only
-- ============================================================================

local addonName, addon = ...

-- Global namespace
local PE = {}
_G.PeralexBG = PE

-- Addon metadata
PE.AddonName = addonName
PE.Version = "0.2.4"

-- Media paths (PeralexBG assets)
PE.MEDIA_PATH = "Interface\\AddOns\\PeralexBG\\Media\\"
PE.TEXTURES_PATH = PE.MEDIA_PATH .. "Textures\\"
PE.FONT_PATH = PE.MEDIA_PATH .. "Fonts\\arenacore.ttf"
PE.FALLBACK_FONT = "Fonts\\FRIZQT__.TTF"

-- State tracking
PE.states = {
    isTestMode = false,
    isEpicBGTestMode = false,
    isInBattleground = false,
    isEpicBG = false,
}

-- ============================================================================
-- UTILITY FUNCTIONS
-- ============================================================================

function PE:GetFont()
    local font = self.FONT_PATH
    local testFont = CreateFont("PE_TestFont")
    testFont:SetFont(font, 12, "")
    local name = testFont:GetFont()
    if not name then
        font = self.FALLBACK_FONT
    end
    return font
end

function PE:Print(msg)
    print("|cff8B45FFPeralex BG:|r " .. tostring(msg))
end

function PE:Debug(msg)
    if self.DB and self.DB.debug then
        print("|cff8B45FFPeralex BG|r |cffFFFF00[DEBUG]|r " .. tostring(msg))
    end
end

-- ============================================================================
-- INITIALIZATION
-- ============================================================================

PE._loginTicker = C_Timer.NewTicker(0.5, function()
    if PE._initialized then
        PE._loginTicker:Cancel()
        PE._loginTicker = nil
        return
    end

    if IsLoggedIn() then
        PE._initialized = true
        PE._loginTicker:Cancel()
        PE._loginTicker = nil

        -- Initialize database
        PE:InitializeDatabase()
        
        -- Check for version update and show changelog if needed
        PE:CheckVersionUpdate()
        
        -- Initialize frame manager
        PE:InitializeFrameManager()
        
        -- Register BG events
        PE:RegisterBattlegroundEvents()
        
        -- Initialize minimap button
        if not PE.DB.minimap.hide then
            PE:CreateMinimapButton()
        end
        
        -- Initialize Capping skin module
        if PE.CappingSkin then
            PE.CappingSkin:Initialize()
        end
        
        PE:Print("v" .. PE.Version .. " loaded. Type /pbg for options.")
        
        -- Check if we're already in a BG (reload scenario)
        C_Timer.After(1, function()
            if PE:IsInBattleground() then
                local matchState = C_PvP.GetActiveMatchState()
                
                if PE.DB.debug then
                    PE:Print("INIT: In BG after load, matchState: " .. tostring(matchState))
                end
                
                if matchState and matchState >= Enum.PvPMatchState.Engaged then
                    PE:OnEnterBattleground()
                    PE:OnMatchActive()
                    
                    -- Force update after data loads
                    C_Timer.After(1.5, function()
                        if PE.states.isInBattleground and not PE.states.isTestMode then
                            PE:OnScoreboardUpdate()
                        end
                    end)
                end
            end
        end)
    end
end)

-- ============================================================================
-- SLASH COMMANDS
-- ============================================================================

SLASH_PERALEXBG1 = "/pbg"
SLASH_PERALEXBG2 = "/peralexbg"

SlashCmdList["PERALEXBG"] = function(msg)
    local cmd = msg:lower():trim()
    
    if cmd == "config" or cmd == "options" or cmd == "" then
        PE:OpenConfig()
    elseif cmd == "test" then
        PE:ToggleTestMode()
    elseif cmd == "debug" then
        PE:ToggleDebug()
    elseif cmd == "anchor" then
        PE:ToggleEnemyAnchor()
    elseif cmd == "specs" then
        PE:DebugDumpAllSpecs()
    elseif cmd:find("testicon") then
        local iconID = cmd:match("testicon%s+(.+)")
        PE:TestIcon(iconID)
    elseif cmd == "hideicon" then
        PE:HideTestIcon()
    else
        PE:Print("Commands: /pbg, /pbg test, /pbg debug, /pbg anchor, /pbg specs, /pbg testicon <id>, /pbg hideicon")
    end
end

-- ============================================================================
-- STUB FUNCTIONS (placeholders for UI callbacks not yet implemented)
-- ============================================================================

function PE:OpenConfig()
    -- Implemented in Config.lua
end

function PE:UpdateHealthBarWidth() end
function PE:UpdateTrinketSizes() end
function PE:UpdateFlagSizes() end
function PE:UpdateHealerSizes() end
function PE:UpdateHealerPositions() end
function PE:UpdateSpecIconSizes() end
function PE:UpdateSpecIconPositions() end

function PE:ResetPosition()
    if self.DB then
        self.DB.position = {
            point = "RIGHT",
            relativePoint = "RIGHT",
            x = -100,
            y = 0,
        }
        self:UpdateAnchorPosition()
        self:Print("Position reset to default")
    end
end

function PE:ShowMidnightNoticeWindow()
    self:Print("Midnight 12.0 changes: Health tracking disabled in BGs. Using scoreboard data only.")
end

function PE:ShowDiscordPopup()
    self:Print("Join our Discord for support!")
end

-- ============================================================================
-- VERSION TRACKING
-- ============================================================================

function PE:CheckVersionUpdate()
    local currentVersion = self.Version
    local lastSeenVersion = self.DB.lastSeenVersion
    
    -- First time install (no version stored)
    if not lastSeenVersion then
        self.DB.lastSeenVersion = currentVersion
        self:Print("Welcome! Type /pbg to configure or click the minimap button.")
        return
    end
    
    -- Version changed - show changelog
    if lastSeenVersion ~= currentVersion then
        self:Debug("Version update detected: " .. tostring(lastSeenVersion) .. " -> " .. currentVersion)
        
        -- Delay changelog window slightly to avoid UI load conflicts
        C_Timer.After(1.5, function()
            self:ShowChangelogWindow()
        end)
        
        -- Update stored version
        self.DB.lastSeenVersion = currentVersion
    end
end
