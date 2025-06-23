local _, ArenaAnalytics = ...; -- Addon Namespace
local Export = ArenaAnalytics.Export;

-- Local module aliases
local AAtable = ArenaAnalytics.AAtable;

-------------------------------------------------------------------------

-- ArenaAnalytics export

-- TODO: Improve the export format
--[[
    New line (\n) for separating matches.
    Comma (;) for separating value types (Date,Bracket,Teams,etc).
    Slash (,) for separating player entries (Player1/Player2/... etc).
    Pipe (|) for separating specific player values (Zeetrax-Ravencrest|NightElf|91|... etc).

    NOTE: Assume any value may be nil, when unknown or non-applicable!

    Format:
        Date
        Season
        Session
        Map             (English Token?)
        Bracket         ("2s", "3s", "5s", "shuffle")
        MatchType       ("rated", "skirm", "wg")
        Duration        (Number)
        Outcome         ("W", "L", "D")
        Team            (Team structure)
        EnemyTeam       (Team structure)
        RatedInfo       (RatedInfo structure)
        Rounds          (List of Round structures)

    Structures:
        Teams:  List of / separated players
            Player: (| separated values)
                FullName    (name-realm)
                bitmask     (1=isFirstDeath, 2=isEnemy, 4=isSelf)
                Race        (English Token)
                SpecID      (Addon spec_id, see addonSpecializationIDs table in Data/ArenaInternalIDs.lua)
                RoleBitmap  (1=tank, 2=dps, 4=healer, 8=melee, 16=ranged, 32=caster)
                Kills       (Number)
                Deaths      (Number)
                Damage      (Number)
                Healing     (Number)
                Wins        (Number)
                Rating      (Number)
                RatingDelta (Number)
                Mmr         (Number)
                MmrDelta    (Number)
        RatedInfo:  List of / separated rating values   [Rated only!]
            Rating
            RatingDelta
            Mmr
            EnemyRating
            EnemyRatingDelta
            EnemyMMR
        Rounds  List of / separated round structures    [Shuffles only!]
            Round:  (| separated round values)
                Team        (Index string, e.g., "35" = enemy index 3 and 5 are on your team. Self is implicit.)
                Enemy       (Index string, e.g., "124" = enemy index 1, 2 and 4 are on your team.)
                FirstDeath  (Enemy index of the first death. 0 = self)
                Duration    (Number)
                isWin       (1 = true, 0=loss, nil=unknown)
            
--]]

local exportPrefix = "date,season,map,bracket,matchType,duration,outcome,"



local exportPrefix = "ArenaAnalytics_v2:" ..
-- Match data
"date,season,bracket,map,duration,won,isRated,rating,ratingDelta,mmr,enemyRating,enemyRatingDelta,enemyMMR,firstDeath,player,"..

-- Team data
"party1Name,party2Name,party3Name,party4Name,party5Name,"..
"party1Race,party2Race,party3Race,party4Race,party5Race,"..
"party1Class,party2Class,party3Class,party4Class,party5Class,"..
"party1Spec,party2Spec,party3Spec,party4Spec,party5Spec,"..
"party1Kills,party2Kills,party3Kills,party4Kills,party5Kills,"..
"party1Deaths,party2Deaths,party3Deaths,party4Deaths,party5Deaths,"..
"party1Damage,party2Damage,party3Damage,party4Damage,party5Damage,"..
"party1Healing,party2Healing,party3Healing,party4Healing,party5Healing,"..

-- Enemy Team Data
"enemy1Name,enemy2Name,enemy3Name,enemy4Name,enemy5Name,"..
"enemy1Race,enemy2Race,enemy3Race,enemy4Race,enemy5Race,"..
"enemy1Class,enemy2Class,enemy3Class,enemy4Class,enemy5Class,"..
"enemy1Spec,enemy2Spec,enemy3Spec,enemy4Spec,enemy5Spec,"..
"enemy1Kills,enemy2Kills,enemy3Kills,enemy4Kills,enemy5Kills,"..
"enemy1Deaths,enemy2Deaths,enemy3Deaths,enemy4Deaths,enemy5Deaths,"..
"enemy1Damage,enemy2Damage,enemy3Damage,enemy4Damage,enemy5Damage,"..
"enemy1Healing,enemy2Healing,enemy3Healing,enemy4Healing,enemy5Healing";

-- Returns a CSV-formatted string using ArenaAnalyticsDB info
function Export:combineExportCSV()
    if(not ArenaAnalytics:HasStoredMatches()) then
        ArenaAnalytics:Log("Export: No games to export!");
        return "No games to export!";
    end

    if(ArenaAnalyticsScrollFrame.exportDialogFrame) then
        ArenaAnalyticsScrollFrame.exportDialogFrame:Hide();
    end

    local exportTable = {}
    tinsert(exportTable, exportPrefix);

    Export:addMatchesToExport(exportTable)
end

function Export:addMatchesToExport(exportTable, nextIndex)
    ArenaAnalytics:Log("Attempting export.. addMatchesToExport", nextIndex);

    nextIndex = nextIndex or 1;
    
    local playerData = {"name", "race", "class", "spec", "kills", "deaths", "damage", "healing"};
    
    local arenasAddedThisFrame = 0;
    for i = nextIndex, #ArenaAnalyticsDB do
        local match = ArenaAnalyticsDB[i];
        
        local victory = match["won"] ~= nil and (match["won"] and "1" or "0") or "";
        
        -- Add match data
        local matchCSV = match["date"] .. ","
        .. (match["season"] or "") .. ","
        .. (match["bracket"] or "") .. ","
        .. (match["map"] or "") .. ","
        .. (match["duration"] or "") .. ","
        .. victory .. ","
        .. (match["isRated"] and "1" or "0") .. ","
        .. (match["rating"] or "").. ","
        .. (match["ratingDelta"] or "").. ","
        .. (match["mmr"] or "") .. ","
        .. (match["enemyRating"] or "") .. ","
        .. (match["enemyRatingDelta"] or "").. ","
        .. (match["enemyMmr"] or "") .. ","
        .. (match["firstDeath"] or "") .. ","
        .. (match["player"] or "") .. ","
        
        -- Add team data 
        local teams = {"team", "enemyTeam"};
        for _,teamKey in ipairs(teams) do
            local team = match[teamKey];
            
            for _,dataKey in ipairs(playerData) do
                for i=1, 5 do
                    local player = team and team[i] or nil;
                    if(player ~= nil) then
                        matchCSV = matchCSV .. (player[dataKey] or "");
                    end

                    matchCSV = matchCSV .. ",";
                end
            end
        end
        
        tinsert(exportTable, matchCSV);

        arenasAddedThisFrame = arenasAddedThisFrame + 1;

        if(arenasAddedThisFrame >= 10000 and i < #ArenaAnalyticsDB) then
            C_Timer.After(0, function() Export:addMatchesToExport(exportTable, i + 1) end);
            return;
        end
    end

    Export:FinalizeExportCSV(exportTable);
end

local function formatNumber(num)
    assert(num ~= nil);
    local left,num,right = string.match(num,'^([^%d]*%d)(%d*)(.-)')
    return left..(num:reverse():gsub('(%d%d%d)','%1,'):reverse())..right
end

function Export:FinalizeExportCSV(exportTable)
    ArenaAnalytics:Log("Attempting export.. FinalizeExportCSV");

    -- Show export with the new CSV string
    if (ArenaAnalytics:HasStoredMatches()) then
        AAtable:CreateExportDialogFrame();
        ArenaAnalyticsScrollFrame.exportDialogFrame.exportFrame:SetText(table.concat(exportTable, "\n"));
	    ArenaAnalyticsScrollFrame.exportDialogFrame.exportFrame:HighlightText();
        
        ArenaAnalyticsScrollFrame.exportDialogFrame.totalText:SetText("Total arenas: " .. formatNumber(#exportTable - 1));
        ArenaAnalyticsScrollFrame.exportDialogFrame.lengthText:SetText("Export length: " .. formatNumber(#ArenaAnalyticsScrollFrame.exportDialogFrame.exportFrame:GetText()));
        ArenaAnalyticsScrollFrame.exportDialogFrame:Show();
    elseif(ArenaAnalyticsScrollFrame.exportDialogFrame) then
        ArenaAnalyticsScrollFrame.exportDialogFrame:Hide();
    end

    exportTable = nil;
    collectgarbage("collect");
    ArenaAnalytics:Log("Garbage Collection forced by Export finalize.");
end