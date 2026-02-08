local _, LRP = ...

local gsubPlayerName = {}

local gsubMarkerDisplay = {
    -- Raid Target Icon (ID)
    ["{rt1}"] = "|TInterface\\TargetingFrame\\UI-RaidTargetingIcon_1:0|t",
    ["{rt2}"] = "|TInterface\\TargetingFrame\\UI-RaidTargetingIcon_2:0|t",
    ["{rt3}"] = "|TInterface\\TargetingFrame\\UI-RaidTargetingIcon_3:0|t",
    ["{rt4}"] = "|TInterface\\TargetingFrame\\UI-RaidTargetingIcon_4:0|t",
    ["{rt5}"] = "|TInterface\\TargetingFrame\\UI-RaidTargetingIcon_5:0|t",
    ["{rt6}"] = "|TInterface\\TargetingFrame\\UI-RaidTargetingIcon_6:0|t",
    ["{rt7}"] = "|TInterface\\TargetingFrame\\UI-RaidTargetingIcon_7:0|t",
    ["{rt8}"] = "|TInterface\\TargetingFrame\\UI-RaidTargetingIcon_8:0|t",
    
    -- Raid Target Icon (ENG)
    ["{star}"] = "|TInterface\\TargetingFrame\\UI-RaidTargetingIcon_1:0|t",
    ["{circle}"] = "|TInterface\\TargetingFrame\\UI-RaidTargetingIcon_2:0|t",
    ["{diamond}"] = "|TInterface\\TargetingFrame\\UI-RaidTargetingIcon_3:0|t",
    ["{triangle}"] = "|TInterface\\TargetingFrame\\UI-RaidTargetingIcon_4:0|t",
    ["{moon}"] = "|TInterface\\TargetingFrame\\UI-RaidTargetingIcon_5:0|t",
    ["{square}"] = "|TInterface\\TargetingFrame\\UI-RaidTargetingIcon_6:0|t",
    ["{cross}"] = "|TInterface\\TargetingFrame\\UI-RaidTargetingIcon_7:0|t",
    ["{skull}"] = "|TInterface\\TargetingFrame\\UI-RaidTargetingIcon_8:0|t",
    
    -- Raid Target Icon (DE)
    ["{stern}"] = "|TInterface\\TargetingFrame\\UI-RaidTargetingIcon_1:0|t",
    ["{kreis}"] = "|TInterface\\TargetingFrame\\UI-RaidTargetingIcon_2:0|t",
    ["{diamant}"] = "|TInterface\\TargetingFrame\\UI-RaidTargetingIcon_3:0|t",
    ["{dreieck}"] = "|TInterface\\TargetingFrame\\UI-RaidTargetingIcon_4:0|t",
    ["{mond}"] = "|TInterface\\TargetingFrame\\UI-RaidTargetingIcon_5:0|t",
    ["{quadrat}"] = "|TInterface\\TargetingFrame\\UI-RaidTargetingIcon_6:0|t",
    ["{kreuz}"] = "|TInterface\\TargetingFrame\\UI-RaidTargetingIcon_7:0|t",
    ["{totenschädel}"] = "|TInterface\\TargetingFrame\\UI-RaidTargetingIcon_8:0|t",
    
    -- Raid Target Icon (FR)
    ["{étoile}"] = "|TInterface\\TargetingFrame\\UI-RaidTargetingIcon_1:0|t",
    ["{cercle}"] = "|TInterface\\TargetingFrame\\UI-RaidTargetingIcon_2:0|t",
    ["{losange}"] = "|TInterface\\TargetingFrame\\UI-RaidTargetingIcon_3:0|t",
    ["{lune}"] = "|TInterface\\TargetingFrame\\UI-RaidTargetingIcon_5:0|t",
    ["{carré}"] = "|TInterface\\TargetingFrame\\UI-RaidTargetingIcon_6:0|t",
    ["{croix}"] = "|TInterface\\TargetingFrame\\UI-RaidTargetingIcon_7:0|t",
    ["{crâne}"] = "|TInterface\\TargetingFrame\\UI-RaidTargetingIcon_8:0|t",
    
    -- Raid Target Icon (IT)
    ["{stella}"] = "|TInterface\\TargetingFrame\\UI-RaidTargetingIcon_1:0|t",
    ["{cerchio}"] = "|TInterface\\TargetingFrame\\UI-RaidTargetingIcon_2:0|t",
    ["{rombo}"] = "|TInterface\\TargetingFrame\\UI-RaidTargetingIcon_3:0|t",
    ["{triangolo}"] = "|TInterface\\TargetingFrame\\UI-RaidTargetingIcon_4:0|t",
    ["{luna}"] = "|TInterface\\TargetingFrame\\UI-RaidTargetingIcon_5:0|t",
    ["{quadrato}"] = "|TInterface\\TargetingFrame\\UI-RaidTargetingIcon_6:0|t",
    ["{croce}"] = "|TInterface\\TargetingFrame\\UI-RaidTargetingIcon_7:0|t",
    ["{teschio}"] = "|TInterface\\TargetingFrame\\UI-RaidTargetingIcon_8:0|t",
    
    -- Raid Target Icon (RU)
    ["{звезда}"] = "|TInterface\\TargetingFrame\\UI-RaidTargetingIcon_1:0|t",
    ["{круг}"] = "|TInterface\\TargetingFrame\\UI-RaidTargetingIcon_2:0|t",
    ["{ромб}"] = "|TInterface\\TargetingFrame\\UI-RaidTargetingIcon_3:0|t",
    ["{треугольник}"] = "|TInterface\\TargetingFrame\\UI-RaidTargetingIcon_4:0|t",
    ["{полумесяц}"] = "|TInterface\\TargetingFrame\\UI-RaidTargetingIcon_5:0|t",
    ["{квадрат}"] = "|TInterface\\TargetingFrame\\UI-RaidTargetingIcon_6:0|t",
    ["{крест}"] = "|TInterface\\TargetingFrame\\UI-RaidTargetingIcon_7:0|t",
    ["{череп}"] = "|TInterface\\TargetingFrame\\UI-RaidTargetingIcon_8:0|t",
    
    -- Raid Target Icon (ES)
    ["{dorado}"] = "|TInterface\\TargetingFrame\\UI-RaidTargetingIcon_1:0|t",
    ["{naranja}"] = "|TInterface\\TargetingFrame\\UI-RaidTargetingIcon_2:0|t",
    ["{morado}"] = "|TInterface\\TargetingFrame\\UI-RaidTargetingIcon_3:0|t",
    ["{verde}"] = "|TInterface\\TargetingFrame\\UI-RaidTargetingIcon_4:0|t",
    ["{plateado}"] = "|TInterface\\TargetingFrame\\UI-RaidTargetingIcon_5:0|t",
    ["{azul}"] = "|TInterface\\TargetingFrame\\UI-RaidTargetingIcon_6:0|t",
    ["{rojo}"] = "|TInterface\\TargetingFrame\\UI-RaidTargetingIcon_7:0|t",
    ["{blanco}"] = "|TInterface\\TargetingFrame\\UI-RaidTargetingIcon_8:0|t",
    
    -- Raid Target Icon (PT)
    ["{dourado}"] = "|TInterface\\TargetingFrame\\UI-RaidTargetingIcon_1:0|t",
    ["{laranja}"] = "|TInterface\\TargetingFrame\\UI-RaidTargetingIcon_2:0|t",
    ["{roxo}"] = "|TInterface\\TargetingFrame\\UI-RaidTargetingIcon_3:0|t",
    ["{prateado}"] = "|TInterface\\TargetingFrame\\UI-RaidTargetingIcon_5:0|t",
    ["{vermelho}"] = "|TInterface\\TargetingFrame\\UI-RaidTargetingIcon_7:0|t",
    ["{branco}"] = "|TInterface\\TargetingFrame\\UI-RaidTargetingIcon_8:0|t",
    
    -- Role Icons
    ["{tank}"] = "|A:Adventures-Tank:0:0|a",
    ["{healer}"] = "|A:Adventures-Healer:0:0|a",
    ["{dps}"] = "|A:Adventures-DPS:0:0|a",
    
    -- Class Icons
    ["{" .. GetClassInfo(1) .. "}"] = "|A:classicon-warrior:0:0|a",
    ["{Warrior}"] = "|A:classicon-warrior:0:0|a",
    ["{" .. GetClassInfo(2) .. "}"] = "|A:classicon-paladin:0:0|a",
    ["{Paladin}"] = "|A:classicon-paladin:0:0|a",
    ["{" .. GetClassInfo(3) .. "}"] = "|A:classicon-hunter:0:0|a",
    ["{Hunter}"] = "|A:classicon-hunter:0:0|a",
    ["{" .. GetClassInfo(4) .. "}"] = "|A:classicon-rogue:0:0|a",
    ["{Rogue}"] = "|A:classicon-rogue:0:0|a",
    ["{" .. GetClassInfo(5) .. "}"] = "|A:classicon-priest:0:0|a",
    ["{Priest}"] = "|A:classicon-priest:0:0|a",
    ["{" .. GetClassInfo(6) .. "}"] = "|A:classicon-deathknight:0:0|a",
    ["{Death Knight}"] = "|A:classicon-deathknight:0:0|a",
    ["{" .. GetClassInfo(7) .. "}"] = "|A:classicon-shaman:0:0|a",
    ["{Shaman}"] = "|A:classicon-shaman:0:0|a",
    ["{" .. GetClassInfo(8) .. "}"] = "|A:classicon-mage:0:0|a",
    ["{Mage}"] = "|A:classicon-mage:0:0|a",
    ["{" .. GetClassInfo(9) .. "}"] = "|A:classicon-warlock:0:0|a",
    ["{Warlock}"] = "|A:classicon-warlock:0:0|a",
    ["{" .. GetClassInfo(10) .. "}"] = "|A:classicon-monk:0:0|a",
    ["{Monk}"] = "|A:classicon-monk:0:0|a",
    ["{" .. GetClassInfo(11) .. "}"] = "|A:classicon-druid:0:0|a",
    ["{Druid}"] = "|A:classicon-druid:0:0|a",
}

if LRP.isRetail then
	gsubMarkerDisplay["{" .. GetClassInfo(12) .. "}"] = "|A:classicon-demonhunter:0:0|a"
	gsubMarkerDisplay["{Demon Hunter}"] = "|A:classicon-demonhunter:0:0|a"
    gsubMarkerDisplay["{" .. GetClassInfo(13) .. "}"] = "|A:classicon-demonhunter:0:0|a"
    gsubMarkerDisplay["{Evoker}"] = "|A:classicon-demonhunter:0:0|a"
end


local gsubMarkerTTS= {
    ["{rt1}"] = "star",
    ["{rt2}"] = "circle",
    ["{rt3}"] = "diamond",
    ["{rt4}"] = "triangle",
    ["{rt5}"] = "moon",
    ["{rt6}"] = "square",
    ["{rt7}"] = "cross",
    ["{rt8}"] = "skull",
}

local function UpdateGsubPlayerNames()
    for unit in LRP:IterateGroupMembers() do
        local name = UnitName(unit)
        local class = UnitClassBase(unit)
        local colorString = select(4, GetClassColor(class))
            
        gsubPlayerName[name] = string.format("|c%s%s|r", colorString, name)
        
        -- Color nicknames according to the class they are currently playing
        if LiquidAPI and LiquidAPI.GetName then
            local nickname = LiquidAPI:GetName(unit)
            
            if nickname and nickname ~= name then
                gsubPlayerName[nickname] = string.format("|c%s%s|r", colorString, nickname)
            end
        end

        if AuraUpdater and AuraUpdater.GetNickname then
            local nickname = AuraUpdater:GetNickname(unit)
            
            if nickname and nickname ~= name then
                gsubPlayerName[nickname] = string.format("|c%s%s|r", colorString, nickname)
            end
        end
    end
end

local function gsubSpellIconDisplay(spellID)
    spellID = tonumber(spellID)

    local spellInfo = spellID and LRP.GetSpellInfo(spellID)

    if spellInfo then
        return CreateTextureMarkup(spellInfo.iconID, 64, 64, 0, 0, 5/64, 59/64, 5/64, 59/64)
    else
        return CreateTextureMarkup("Interface\\Icons\\INV_MISC_QUESTIONMARK", 64, 64, 0, 0, 5/64, 59/64, 5/64, 59/64)
    end
end

local function gsubSpellIconTTS(spellID)
    spellID = tonumber(spellID)

    local spellInfo = spellID and LRP.GetSpellInfo(spellID)

    return spellInfo and spellInfo.name or ""
end

function LRP:FormatForDisplay(text)
    text = text:gsub("||", "|") -- Make sure escape sequences work correctly
    text = text:gsub("{.-}", gsubMarkerDisplay) -- Replace raid/class markers by icons
    text = text:gsub("{spell:(%d+)}", gsubSpellIconDisplay) -- Replace {spell:123456} by icon
    text = text:gsub("[^ \n,%(%)%[%]_%$#@!&]+", gsubPlayerName) -- Color player names

    return text
end

function LRP:FormatForTTS(text)
    text = text:gsub("{.-}", gsubMarkerTTS) -- Replace raid markers with text
    text = text:gsub("{spell:(%d+)}", gsubSpellIconTTS) -- Replace {spell:123456} by icon

    return text
end

function LRP:InitializeTextFormatter()
    UpdateGsubPlayerNames()
end

-- Keep gsubPlayerNames updated
local eventFrame = CreateFrame("Frame")

eventFrame:RegisterEvent("GROUP_ROSTER_UPDATE")
eventFrame:SetScript("OnEvent", UpdateGsubPlayerNames)