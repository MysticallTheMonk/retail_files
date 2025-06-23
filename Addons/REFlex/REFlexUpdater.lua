local _, RE = ...

local mfloor = math.floor
local tinsert = table.insert

function RE:UpdateSettings()
  if RE.Settings.ConfigVersion < 260 then
    if RE.Settings.ConfigVersion < 220 then
      RE.Settings.CurrentTab = 1
      RE.Settings.Filters = {["Spec"] = ALL, ["Map"] = 1, ["Bracket"] = 1, ["Date"] = {0, 0}, ["DateMode"] = 1}
      RE.Settings.ConfigVersion = 220
    end

    if RE.Settings.ConfigVersion < 234 then
      RE.Settings.Filters.Season = 0
      RE.Settings.ConfigVersion = 234
    end

    if RE.Settings.ConfigVersion < 240 then
      RE.Settings.LDBMode = 2
      RE.Settings.LDBSide = "A"
      RE.Settings.ConfigVersion = 240
    end

    if RE.Settings.ConfigVersion < 250 then
      if not RE.Settings.Filters.DateMode then
        RE.Settings.Filters.DateMode = 1
      end
      RE.Settings.ConfigVersion = 250
    end

    if RE.Settings.ConfigVersion < 260 then
      RE.Settings.ArenaStatsLimit = 3
      RE.Settings.ConfigVersion = 260
    end

    if RE.Settings.Filters.DateMode > 1 then
      RE.Settings.Filters.DateMode = RE.Settings.Filters.DateMode + 1
    end
    RE.Settings.ConfigVersion = 310
  end
end

function RE:UpdateDatabase()
  for i=1, #RE.Database do
    if RE.Database[i].Version < 3300 then
      if RE.Database[i].Version < 224 then
        if RE.Database[i].Map == 1681 then
          RE.Database[i].Map = 2107
          RE.Database[i].isBrawl = true
        else
          RE.Database[i].isBrawl = false
        end
        RE.Database[i].Version = 224
      end

      if RE.Database[i].Version < 225 then
        if RE.Database[i].Map == 562 then
          RE.Database[i].Map = 1672
        end
        if RE.Database[i].Map == 559 then
          RE.Database[i].Map = 1505
        end
        RE.Database[i].Version = 225
      end

      if RE.Database[i].Version < 230 then
        if not RE.Database[i].PlayerNum or RE.Database[i].Map == 1170 then
          RE.Database[i].Hidden = true
        else
          RE.Database[i].Hidden = false
        end
        RE.Database[i].Version = 230
      end

      if RE.Database[i].Version < 235 then
        if RE.Database[i].isArena and RE.Database[i].isRated and RE.Database[i].isBrawl then
          RE.Database[i].Hidden = true
        end
        RE.Database[i].Version = 235
      end

      if RE.Database[i].Version < 260 then
        RE.Database[i].Time = RE.Database[i].Time - (RE.PlayerTimezone * 3600)
        RE.Database[i].Version = 260
      end

      if RE.Database[i].Version < 265 then
        if RE.Database[i].Map == 489 then
          RE.Database[i].Map = 2106
        elseif RE.Database[i].Map == 529 then
          RE.Database[i].Map = 2107
        end
        RE.Database[i].Version = 265
      end

      if RE.Database[i].Version < 266 then
        if RE.Database[i].Map == 998 then
          RE.Database[i].Map = 1035
        end
        RE.Database[i].Version = 266
      end

      if RE.Database[i].Version < 268 then
        if RE.Database[i].Map == 2177 then
          RE.Database[i].Hidden = true
        end
        RE.Database[i].Version = 268
      end

      if RE.Database[i].Version < 274 then
        if RE.Database[i].Map == 2197 then
          RE.Database[i].Map = 30
        end
        RE.Database[i].Version = 274
      end

      if RE.Database[i].Version < 300 then
        RE.Database[i].StatsNum = nil
        if not RE.Database[i].Hidden and RE.Database[i].PlayersStats then
          local tmp = RE.Database[i].PlayersStats[RE.Database[i].PlayerNum]
          RE.Database[i].PlayerStats = {}
          for _, v in pairs(tmp) do
            tinsert(RE.Database[i].PlayerStats, v[1])
          end
          RE.Database[i].PlayersStats = nil
        end
        if not RE.Database[i].Hidden and not RE.Database[i].isArena then
          RE.Database[i].BGPlace = {}
          tinsert(RE.Database[i].BGPlace, {RE:GetBGPlace(RE.Database[i], true)})
          tinsert(RE.Database[i].BGPlace, {RE:GetBGPlace(RE.Database[i], false)})
          RE.Database[i].BGComposition = {}
          tinsert(RE.Database[i].BGComposition, {RE:GetBGComposition(RE.Database[i], true)})
          tinsert(RE.Database[i].BGComposition, {RE:GetBGComposition(RE.Database[i], false)})
          if not RE.Database[i].isRated then
            RE.Database[i].Players = {RE.Database[i].Players[RE.Database[i].PlayerNum]}
            RE.Database[i].PlayerNum = 1
          end
        end
        RE.Database[i].Version = 300
      end

      RE.Database[i].isSoloShuffle = false
      RE.Database[i].Version = 3300
    end
  end
end

function RE:UpdateHDatabase()
  for i=1, #REFlexDatabase do
    local date = mfloor(REFlexDatabase[i].Time / 86400) * 86400
    local playerData = RE:GetPlayerData(i)
    if playerData[5] > 0 then
      if not REFlexHonorDatabase[date] then
        REFlexHonorDatabase[date] = 0
      end
      REFlexHonorDatabase[date] = REFlexHonorDatabase[date] + playerData[5]
    end
  end
end
