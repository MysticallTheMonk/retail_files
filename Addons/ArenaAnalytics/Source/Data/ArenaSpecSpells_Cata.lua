local _, ArenaAnalytics = ...; -- Addon Namespace
local SpecSpells = ArenaAnalytics.SpecSpells;

-------------------------------------------------------------------------

local specSpells = {
    --------------------------------------------------------
    -- DRUID

    -- Restoration
    [ 18562 ] = 1, -- Swiftmend
    [ 17116 ] = 1, -- Nature's Swiftness
    [ 48438 ] = 1, -- Wild Growth
    [ 33891 ] = 1, -- Tree of Life

    -- Feral
    [ 33878 ] = 2, -- Mangle (Bear Form)
    [ 33876 ] = 2, -- Mangle (Cat Form)
    [ 16979 ] = 2, -- Feral Charge (Bear Form)
    [ 49376 ] = 2, -- Feral Charge (Cat Form)
    [ 61336 ] = 2, -- Survival Instincts
    [ 80313 ] = 2, -- Pulverize
    [ 33983 ] = 2, -- Berserk
    [ 17007 ] = 2, -- Leader of the Pack
    
    -- Balance
    [ 78674 ] = 3, -- Starsurge
    [ 24858 ] = 3, -- Moonkin Form
    [ 50516 ] = 3, -- Typhoon
    [ 78675 ] = 3, -- Solar Beam
    [ 33831 ] = 3, -- Force of Nature
    [ 48505 ] = 3, -- Starfall

    --------------------------------------------------------
    -- PALADIN

    -- Holy
    [ 20473 ] = 11, -- Holy Shock
    [ 31842 ] = 11, -- Divine Favor
    [ 53563 ] = 11, -- Beacon of Light
    [ 31821 ] = 11, -- Aura Mastery
    [ 85222 ] = 11, -- Light of Dawn

    -- Protection
    [ 31935 ] = 12, -- Avenger's Shield
    [ 53595 ] = 12, -- Hammer of the Righteous
    [ 53600 ] = 12, -- Shield of the Righteous
    [ 20925 ] = 12, -- Holy Shield
    [ 20927 ] = 12, -- Divine Guardian
    [ 20928 ] = 12, -- Ardent Defender
    
    -- Retribution
    [ 85256 ] = 14, -- Templar's Verdict
    [ 53385 ] = 14, -- Divine Storm
    [ 85285 ] = 14, -- Sacred Shield (Passive Trigger)
    [ 20066 ] = 14, -- Repentance
    [ 85696 ] = 14, -- Zealoty
    [ 20424 ] = 14, -- Seals of Command
    [ 59578 ] = 14, -- The Art of War (Aura)

    --------------------------------------------------------
    -- SHAMAN
    
    -- Restoration
    [ 974 ] = 21, -- Earth Shield
    [ 16188 ] = 21, -- Nature's Swiftness
    [ 16190 ] = 21, -- Mana Tide Totem
    [ 61295 ] = 21, -- Riptide

    -- Elemental
    [ 51490 ] = 22, -- Thunderstorm
    [ 16166 ] = 22, -- Elemental Mastery
    [ 61882 ] = 22, -- Earthquake
    
    -- Enhancement
    [ 60103 ] = 23, -- Lava Lash
    [ 17364 ] = 23, -- Stormstrike
    [ 30823 ] = 23, -- Shamanistic Rage
    [ 51533 ] = 23, -- Feral Spirit

    --------------------------------------------------------
    -- DEATHKNIGHT

    -- Unholy
    [ 55090 ] = 31, -- Scourge Strike
    [ 49016 ] = 31, -- Unholy Frenzy
    [ 51052 ] = 31, -- Anti-magic Zone
    [ 63560 ] = 31, -- Dark Transformation
    [ 49206 ] = 31, -- Summon Gargoyle

    -- Frost
    [ 49143 ] = 32, -- Frost Strike
    [ 66196 ] = 32, -- Frost Strike Off-Hand
    [ 51271 ] = 32, -- Pillar of Frost
    [ 49203 ] = 32, -- Hungering Cold
    [ 49184 ] = 32, -- Howling Blast

    -- Blood
    [ 55050 ] = 33, -- Heart Strike
    [ 50034 ] = 33, -- Blood Rites
    [ 49222 ] = 33, -- Bone Shield
    [ 48982 ] = 33, -- Rune Tap
    [ 55233 ] = 33, -- Vampiric Blood
    [ 49028 ] = 33, -- Dancing Rune Weapon

    --------------------------------------------------------
    -- HUNTER

    -- Beast Mastery
    [ 19577 ] = 41, -- Intimidation
    [ 82726 ] = 41, -- Fervor
    [ 82692 ] = 41, -- Focus Fire
    [ 19574 ] = 41, -- Bestial Wrath

    -- Marksmanship
    [ 19434 ] = 42, -- Aimed Shot
    [ 34490 ] = 42, -- Silencing Shot
    [ 23989 ] = 42, -- Readiness
    [ 53209 ] = 42,  -- Chimera Shot

    -- Survival
    [ 53301 ] = 43, -- Explosive Shot
    [ 19306 ] = 43, -- Counterattack
    [ 19386 ] = 43, -- Wyvern Sting
    [ 3674 ] = 43, -- Black Arrow

    --------------------------------------------------------
    -- MAGE

    -- Frost
    [ 31687 ] = 51, -- Summon Water Elemental
    [ 12472 ] = 51, -- Icy Veins
    [ 11958 ] = 51, -- Cold Snap
    [ 11426 ] = 51, -- Ice Barrier
    [ 44572 ] = 51, -- Deep Freeze
   
    -- Fire
    [ 11366 ] = 52, -- Pyroblast
    [ 11113 ] = 52, -- Blast Wave
    [ 11129 ] = 52, -- Combustion
    [ 31661 ] = 52, -- Dragon's Breath
    [ 44457 ] = 52, -- Living Bomb
    [ 44461 ] = 52, -- Living Bomb (Explosion)
    [ 31642 ] = 52, -- Blazing Speed
    [ 44445 ] = 52, -- Hot Streak

    -- Arcane
    [ 44425 ] = 53, -- Arcane Barrage
    [ 12043 ] = 53, -- Presence of Mind
    [ 31589 ] = 53, -- Slow
    [ 54646 ] = 53, -- Focus Magic
    [ 12042 ] = 53, -- Arcane Power

    --------------------------------------------------------
    -- ROGUE

    -- Subtlety
    [ 36554 ] = 61, -- Shadowstep
    [ 16511 ] = 61, -- Hemorrhage
    [ 14183 ] = 61, -- Premeditation
    [ 14185 ] = 61, -- Preparation
    [ 51713 ] = 61, -- Shadow Dance
    [ 31223 ] = 61, -- Master of Subtlety

    -- Assassination
    [ 1329 ] = 62, -- Mutilate
    [ 14177 ] = 62, -- Cold Blood
    [ 79140 ] = 62, -- Vendetta

    -- Combat
    [ 13877 ] = 63, -- Blade Fury
    [ 84617 ] = 63, -- Revealing Strike
    [ 13750 ] = 63, -- Adrenaline Rush
    [ 51690 ] = 63, -- Killing Spree

    --------------------------------------------------------
    -- WARLOCK

    -- Affliction
    [ 30108 ] = 71, -- Unstable Affliction
    [ 18223 ] = 71, -- Curse of Exhaustion
    [ 86121 ] = 71, -- Soul Swap
    [ 48181 ] = 71, -- Haunt

    -- Destruction
    [ 17962 ] = 72, -- Conflagrate
    [ 17877 ] = 72, -- Shadowburn
    [ 30283 ] = 72, -- Shadowfury
    [ 80240 ] = 72, -- Bane of Havoc
    [ 50796 ] = 72, -- Chaos Bolt

    -- Demonology
    [ 30146 ] = 73, -- Summon Felguard
    [ 47193 ] = 73, -- Demonic Empowerment
    [ 71521 ] = 73, -- Hand of Gul'dan
    [ 59672 ] = 73, -- Metamorphosis?
    [ 47241 ] = 73, -- Metamorphosis?
    [ 59673 ] = 73, -- Metamorphosis?

    --------------------------------------------------------
    -- WARRIOR

    -- Protection
    [ 23922 ] = 81, -- Shield Slam
    [ 12975 ] = 81, -- Last Stand
    [ 12809 ] = 81, -- Concussion Blow
    [ 20243 ] = 81, -- Devastate
    [ 50720 ] = 81, -- Vigilance
    [ 46968 ] = 81, -- Shockwave

    -- Arms
    [ 12294 ] = 82, -- Mortal Strike
    [ 12328 ] = 82, -- Sweeping Strikes
    [ 85730 ] = 82, -- Deadly Calm
    [ 85388 ] = 82, -- Throwdown
    [ 46924 ] = 82, -- Bladestorm

    -- Fury
    [ 23881 ] = 83, -- Bloodthirst
    [ 12292 ] = 83, -- Death Wish
    [ 85288 ] = 83, -- Raging Blow
    [ 60970 ] = 83, -- Heroic Fury
    
    --------------------------------------------------------
    -- PRIEST

    -- Discipline
    [ 47540 ] = 91, -- Penance
    [ 47666 ] = 91, -- Penance
    [ 47750 ] = 91, -- Penance
    [ 54518 ] = 91, -- Penance
    [ 10060 ] = 91, -- Power Infusion
    [ 89485 ] = 91, -- Inner Focus
    [ 33206 ] = 91, -- Pain Suppression
    [ 62618 ] = 91, -- Power Word: Barrier

    -- Holy
    [ 88625 ] = 92, -- Holy Word: Chastice
    [ 88684 ] = 92, -- Holy Word: Serenity
    [ 88685 ] = 92, -- Holy Word: Sanctuary
    [ 724 ] = 92, -- Lightwell
    [ 14751 ] = 92, -- Chakra
    [ 34861 ] = 92, -- Circle of Healing
    [ 47788 ] = 92, -- Guardian Spirit

    -- Shadow
    [ 15407 ] = 93, -- Mind Flay
    [ 15473 ] = 93, -- Shadowform
    [ 15487 ] = 93, -- Silence
    [ 15286 ] = 93, -- Vampiric Embrace
    [ 34914 ] = 93, -- Vampiric Touch
    [ 64044 ] = 93, -- Psychic Horror
    [ 47585 ] = 93, -- Dispersion
}

local debugSpells = {
    -- Feral
    [ 17007 ] = 2, -- Leader of the Pack
    
    -- Subtlety
    [ 51698 ] = 61, -- Honor Among Thieves

    -- Demonology
    [ 59672 ] = 73, -- Metamorphosis?
    [ 47241 ] = 73, -- Metamorphosis?
    [ 59673 ] = 73, -- Metamorphosis?

    -- Retribution
    [59578] = 14, -- Art of War?

    --------------------------------------------------------
    -- HUNTER

    -- Beast Mastery
    [ 19577 ] = 41, -- Intimidation
    [ 82726 ] = 41, -- Fervor
    [ 82692 ] = 41, -- Focus Fire
    [ 19574 ] = 41, -- Bestial Wrath

    -- Marksmanship
    [ 19434 ] = 42, -- Aimed Shot
    [ 34490 ] = 42, -- Silencing Shot
    [ 23989 ] = 42, -- Readiness
    [ 53209 ] = 42,  -- Chimera Shot

    -- Survival
    [ 53301 ] = 43, -- Explosive Shot
    [ 19306 ] = 43, -- Counterattack
    [ 19386 ] = 43, -- Wyvern Sting
    [ 3674 ] = 43, -- Black Arrow
};

function SpecSpells:GetSpec(spellID)
    if(debugSpells[spellID]) then
        ArenaAnalytics:Log("SpecSpells:GetSpec identified debug spell:", spellID, "for spec:", debugSpells[spellID]);
    end

    return specSpells[spellID];
end