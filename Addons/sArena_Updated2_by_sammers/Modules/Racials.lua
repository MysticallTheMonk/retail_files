local GetTime = GetTime

sArenaMixin.defaultSettings.profile.racialCategories = {
    ["Human"] = true,
    ["Scourge"] = true,
    ["Dwarf"] = true,
    ["NightElf"] = true,
    ["Gnome"] = true,
    ["Draenei"] = true,
    ["Worgen"] = true,
    ["Pandaren"] = true,
    ["Orc"] = true,
    ["Tauren"] = true,
    ["Troll"] = true,
    ["BloodElf"] = true,
    ["Goblin"] = true,
    ["LightforgedDraenei"] = true,
    ["HighmountainTauren"] = true,
    ["Nightborne"] = true,
    ["MagharOrc"] = true,
    ["DarkIronDwarf"] = true,
    ["ZandalariTroll"] = true,
    ["VoidElf"] = true,
    ["KulTiran"] = true,
    ["Mechagnome"] = true,
    ["Vulpera"] = true,
    ["Dracthyr"] = true,
    ["EarthenDwarf"] = true
}

local racialSpells = {
    [59752] = 180,  -- Will to Survive
    [7744] = 120,   -- Will of the Forsaken
    [20594] = 120, -- Stoneform
    [58984] = 120,  -- Shadowmeld
    [20589] = 60,   -- Escape Artist
    [59542] = 120,  -- Gift of the Naaru
    [68992] = 120,  -- Darkflight
    [107079] = 120, -- Quaking Palm
    [33697] = 120,  -- Blood Fury
    [20549] = 90,   -- War Stomp
    [26297] = 180,  -- Berserking
    [202719] = 90,  -- Arcane Torrent
    [69070] = 90,   -- Rocket Jump
    [255647] = 150, -- Light's Judgment
    [255654] = 120, -- Bull Rush
    [260364] = 180, -- Arcane Pulse
    [274738] = 120, -- Ancestral Call
    [265221] = 120, -- Fireblood
    [291944] = 160, -- Regeneratin'
    [256948] = 180, -- Spatial Rift
    [287712] = 160, -- Haymaker
    [312924] = 180, -- Hyper Organic Light Originator
    [312411] = 90,  -- Bag of Tricks
    [368970] = 90,  -- Tail Swipe
    [357214] = 90,  -- Wing Buffet
    [436344] = 120 -- Azerite Surge
}

local racialData = {
    ["Human"] = { texture = C_Spell.GetSpellTexture(59752), sharedCD = 90 },
    ["Scourge"] = { texture = C_Spell.GetSpellTexture(7744), sharedCD = 30 },
    ["Dwarf"] = { texture = C_Spell.GetSpellTexture(20594), sharedCD = 30 },
    ["NightElf"] = { texture = C_Spell.GetSpellTexture(58984), sharedCD = 0 },
    ["Gnome"] = { texture = C_Spell.GetSpellTexture(20589), sharedCD = 0 },
    ["Draenei"] = { texture = C_Spell.GetSpellTexture(59542), sharedCD = 0 },
    ["Worgen"] = { texture = C_Spell.GetSpellTexture(68992), sharedCD = 0 },
    ["Pandaren"] = { texture = C_Spell.GetSpellTexture(107079), sharedCD = 0 },
    ["Orc"] = { texture = C_Spell.GetSpellTexture(33697), sharedCD = 0 },
    ["Tauren"] = { texture = C_Spell.GetSpellTexture(20549), sharedCD = 0 },
    ["Troll"] = { texture = C_Spell.GetSpellTexture(26297), sharedCD = 0 },
    ["BloodElf"] = { texture = C_Spell.GetSpellTexture(202719), sharedCD = 0 },
    ["Goblin"] = { texture = C_Spell.GetSpellTexture(69070), sharedCD = 0 },
    ["LightforgedDraenei"] = { texture = C_Spell.GetSpellTexture(255647), sharedCD = 0 },
    ["HighmountainTauren"] = { texture = C_Spell.GetSpellTexture(255654), sharedCD = 0 },
    ["Nightborne"] = { texture = C_Spell.GetSpellTexture(260364), sharedCD = 0 },
    ["MagharOrc"] = { texture = C_Spell.GetSpellTexture(274738), sharedCD = 0 },
    ["DarkIronDwarf"] = { texture = C_Spell.GetSpellTexture(265221), sharedCD = 30 },
    ["ZandalariTroll"] = { texture = C_Spell.GetSpellTexture(291944), sharedCD = 0 },
    ["VoidElf"] = { texture = C_Spell.GetSpellTexture(256948), sharedCD = 0 },
    ["KulTiran"] = { texture = C_Spell.GetSpellTexture(287712), sharedCD = 0 },
    ["Mechagnome"] = { texture = C_Spell.GetSpellTexture(312924), sharedCD = 0 },
    ["Vulpera"] = { texture = C_Spell.GetSpellTexture(312411), sharedCD = 0 },
    ["Dracthyr"] = { texture = C_Spell.GetSpellTexture(368970), sharedCD = 0 },
    ["EarthenDwarf"] = { texture = C_Spell.GetSpellTexture(436344), sharedCD = 0 } -- Update sharedCD if needed
}

local function GetRemainingCD(frame)
    local startTime, duration = frame:GetCooldownTimes()
    if ( startTime == 0 ) then return 0 end

    local currTime = GetTime()

    return (startTime + duration) / 1000 - currTime
end

function sArenaFrameMixin:FindRacial(event, spellID)
    if ( event ~= "SPELL_CAST_SUCCESS" ) then return end

    local duration = racialSpells[spellID]

    if ( duration ) then
        local currTime = GetTime()

        if ( self.Racial.Texture:GetTexture() ) then
            self.Racial.Cooldown:SetCooldown(currTime, duration)
        end

        if ( self.Trinket.spellID == 336126 or self.Trinket.spellID == 336135 ) then
            local remainingCD = GetRemainingCD(self.Trinket.Cooldown)
            local sharedCD = racialData[self.race].sharedCD

            -- Check if the unit is a healer and if the race is Human and trinket is Medallion
            if ( self.race == "Human" and self:IsHealer(self.unit) and self.Trinket.spellID == 336126 ) then
                sharedCD = 60  -- Set sharedCD to 60
            end

            -- Apply the shared cooldown if remaining time is less than the sharedCD
            if (sharedCD and remainingCD < sharedCD) then
                self.Trinket.Cooldown:SetCooldown(currTime, sharedCD)
            end
        end
    elseif ( (spellID == 336126 or spellID == 336135) and self.Racial.Texture:GetTexture() ) then
        local remainingCD = GetRemainingCD(self.Racial.Cooldown)
        local sharedCD = racialData[self.race].sharedCD

        -- Check if the unit is a healer and if the race is Human and trinket is Medallion
        if ( self.race == "Human" and self:IsHealer(self.unit) and self.Trinket.spellID == 336126 ) then
            sharedCD = 60  -- Set sharedCD to 60 if the unit is a healer
        end

        -- Apply the shared cooldown if remaining time is less than the sharedCD
        if (sharedCD and remainingCD < sharedCD) then
            self.Racial.Cooldown:SetCooldown(GetTime(), sharedCD)
        end
    end
end

function sArenaFrameMixin:UpdateRacial()
    self.race = nil
    self.Racial.Texture:SetTexture(nil)
    if ( not self.race ) then
        self.race = select(2, UnitRace(self.unit))

        if ( self.parent.db.profile.racialCategories[self.race] ) then
            self.Racial.Texture:SetTexture(racialData[self.race].texture)
        end
    end
end

function sArenaFrameMixin:ResetRacial()
    self.race = nil
    self.Racial.Texture:SetTexture(nil)
    self.Racial.Cooldown:Clear()
    self:UpdateRacial()
end
