local _, ArenaAnalytics = ...; -- Addon Namespace
local SpecSpells = ArenaAnalytics.SpecSpells;

-------------------------------------------------------------------------

local specSpells = {
    --------------------------------------------------------
    -- DRUID

    -- Restoration
    [ 18562 ] = 1, -- Swiftmend
    [ 17116 ] = 1, -- Nature's Swiftness
    [ 45283 ] = 1, -- Natural Perfection
    [ 33891 ] = 1, -- Tree of Life

    -- Feral
    [ 33876 ] = 2, -- Mangle (Cat)
    [ 33982 ] = 2, -- Mangle (Cat)
    [ 33983 ] = 2, -- Mangle (Cat)
    [ 48565 ] = 2, -- Mangle (Cat)
    [ 48566 ] = 2, -- Mangle (Cat)
    
    [ 33878 ] = 2, -- Mangle (Bear)
    [ 33986 ] = 2, -- Mangle (Bear)
    [ 33987 ] = 2, -- Mangle (Bear)
    [ 48563 ] = 2, -- Mangle (Bear)
    [ 48564 ] = 2, -- Mangle (Bear)

    [ 48483 ] = 3, -- Infected Wounds
    [ 48484 ] = 3, -- Infected Wounds
    [ 48485 ] = 3, -- Infected Wounds

    [ 24932 ] = 2, -- Leader of the Pack
    [ 49376 ] = 2, -- Feral Charge: Cat
    [ 16979 ] = 2, -- Feral Charge: Bear

    [ 50334 ] = 3, -- Berserk

    -- Balance
    [ 33831 ] = 3, -- Force of Nature
    [ 24858 ] = 3, -- Moonkin Form
    [ 24907 ] = 3, -- Moonkin Aura
    [ 50516 ] = 3, -- Typhoon
    [ 48505 ] = 3, -- Starfall (Rank 1)
    [ 53199 ] = 3, -- Starfall (Rank 2)
    [ 53200 ] = 3, -- Starfall (Rank 3)
    [ 53201 ] = 3, -- Starfall (Rank 4)

    --------------------------------------------------------
    -- PALADIN

    -- Holy
    [ 20473 ] = 11, -- Holy Shock (Rank 1)
    [ 20929 ] = 11, -- Holy Shock (Rank 2)
    [ 20930 ] = 11, -- Holy Shock (Rank 3)
    [ 27174 ] = 11, -- Holy Shock (Rank 4)
    [ 33072 ] = 11, -- Holy Shock (Rank 5)
    [ 48824 ] = 11, -- Holy Shock (Rank 6)
    [ 48825 ] = 11, -- Holy Shock (Rank 7)
    [ 53563 ] = 11, -- Beacon of Light
    [ 53652 ] = 11, -- Beacon of Light (Holy Shock)
    [ 53653 ] = 11, -- Beacon of Light (Flash of Light)
    [ 53654 ] = 11, -- Beacon of Light (???)
    [ 20216 ] = 11, -- Divine Favor
    [ 31842 ] = 11, -- Divine Illumination
    [ 31836 ] = 11, -- Light's Grace

    -- Protection
    [ 31935 ] = 12, -- Avenger's Shield (Rank 1)
    [ 32699 ] = 12, -- Avenger's Shield (Rank 2)
    [ 32700 ] = 12, -- Avenger's Shield (Rank 3)
    [ 48826 ] = 12, -- Avenger's Shield (Rank 4)
    [ 48827 ] = 12, -- Avenger's Shield (Rank 5)
    [ 20925 ] = 12, -- Holy Shield (Rank 1)
    [ 20927 ] = 12, -- Holy Shield (Rank 2)
    [ 20928 ] = 12, -- Holy Shield (Rank 3)
    [ 27179 ] = 12, -- Holy Shield (Rank 4)
    [ 48951 ] = 12, -- Holy Shield (Rank 5)
    [ 48952 ] = 12, -- Holy Shield (Rank 6)
    [ 53595 ] = 12, -- Hammer of the Righteous

    -- Preg
    [ 20066 ] = 13, -- Repentance (Ret tree)
    [ 54203 ] = 13, -- Sheath of Light (Ret tree)
    [ 20178 ] = 13, -- Reckoning (Prot tree)
    [ 20911 ] = 13, -- Blessing of Sanctuary (Prot tree)

    -- Retribution
    [ 35395 ] = 14, -- Crusader Strike
    [ 20049 ] = 14, -- Vengeance
    [ 53380 ] = 14, -- Righteous Vengeance (Rank 1)
    [ 53381 ] = 14, -- Righteous Vengeance (Rank 2)
    [ 53382 ] = 14, -- Righteous Vengeance (Rank 3)
    [ 53385 ] = 14, -- Divine Storm

    --------------------------------------------------------
    -- SHAMAN

    -- Restoration
    [ 16188 ] = 21, -- Nature's Swiftness
    [ 974 ] = 21, -- Earth Shield (Rank 1)
    [ 32593 ] = 21, -- Earth Shield (Rank 2)
    [ 32594 ] = 21, -- Earth Shield (Rank 3)
    [ 49283 ] = 21, -- Earth Shield (Rank 4)
    [ 49284 ] = 21, -- Earth Shield (Rank 5)
    [ 16190 ] = 21, -- Mana Tide Totem
    [ 61300 ] = 21, -- Riptide
    [ 51886 ] = 21, -- Cleanse Spirit

    -- Elemental
    [ 16166 ] = 22, -- Elemental Mastery
    [ 30706 ] = 22, -- Totem of Wrath
    [ 59159 ] = 22, -- Thunderstorm

    -- Enhancement
    [ 30823 ] = 23, -- Shamanistic Rage
    [ 17364 ] = 23, -- Stormstrike
    [ 60103 ] = 23, -- Lava Lash
    [ 53817 ] = 23, -- Maelstrom Weapon
    [ 51533 ] = 23, -- Feral Spirit

    --------------------------------------------------------
    -- DEATHKNIGHT

    -- Unholy
    [ 50461 ] = 31, -- Anti-magic Zone
    [ 49222 ] = 31, -- Bone Shield
    [ 71488 ] = 31, -- Scourge Strike
    [ 49206 ] = 31, -- Summon Gargoyle

    -- Frost
    [ 49796 ] = 32, -- Death Chill
    [ 49203 ] = 32, -- Hungering Cold
    [ 51271 ] = 32, -- Unbreakable Armor
    [ 55268 ] = 32, -- Frost Strike
    [ 51411 ] = 32, -- Howling Blast

    -- Blood
    [ 49005 ] = 33, -- Mark of Blood
    [ 49016 ] = 33, -- Unholy Frenzy
    [ 55233 ] = 33, -- Vampiric Blood
    [ 55262 ] = 33, -- Heart Strike
    [ 49028 ] = 33, -- Dancing Rune Weapon
    
    --------------------------------------------------------
    -- HUNTER

    -- Beast Mastery
    [ 19577 ] = 41, -- Intimidation
    [ 34692 ] = 41, -- The Beast Within
    [ 20895 ] = 41, -- Spirit Bond
    [ 34455 ] = 41, -- Ferocious Inspiration

    -- Marksmanship
    [ 34490 ] = 42, -- Silencing Shot
    [ 19506 ] = 42, -- Trueshot Aura
    [ 53209 ] = 42,  -- Chimera Shot

    -- Survival
    [ 27068 ] = 43, -- Wyvern Sting
    [ 19306 ] = 43, -- Counterattack
    [ 60053 ] = 43, -- Explosive Shot

    --------------------------------------------------------
    -- MAGE

    -- Frost
    [ 33405 ] = 51, -- Ice Barrier
    [ 31687 ] = 51, -- Summon Water Elemental
    [ 12472 ] = 51, -- Icy Veins
    [ 11958 ] = 51, -- Cold Snap
    [ 44572 ] = 51, -- Deep Freeze

    -- Fire
    [ 42950 ] = 52, -- Dragon's Breath
    [ 33933 ] = 52, -- Blast Wave
    [ 11129 ] = 52, -- Combustion
    [ 55360 ] = 52, -- Living Bomb
    [ 31642 ] = 52, -- Blazing Speed

    -- Arcane
    [ 12042 ] = 53, -- Arcane Power
    [ 12043 ] = 53, -- Presence of Mind
    [ 44425 ] = 53, -- Arcane Barrage
    [ 31589 ] = 53, -- Slow

    --------------------------------------------------------
    -- ROGUE

    -- Subtlety
    [ 14185 ] = 61, -- Preparation
    [ 16511 ] = 61, -- Hemorrhage
    [ 14278 ] = 61, -- Ghostly Strike
    [ 14183 ] = 61, -- Premeditation
    [ 36554 ] = 61, -- Shadowstep
    [ 44373 ] = 61, -- Shadowstep Speed
    [ 36563 ] = 61, -- Shadowstep DMG
    [ 31665 ] = 61, -- Master of Subtlety
    [ 51713 ] = 61, -- Shadow Dance

    -- Assassination
    [ 14177 ] = 62, -- Cold Blood
    [ 31233 ] = 62, -- Find Weakness
    [ 48666 ] = 62, -- Mutilate
    [ 57993 ] = 62, -- Envenom
    [ 51662 ] = 62, -- Hunger For Blood

    -- Combat
    [ 13750 ] = 63, -- Adrenaline Rush
    [ 51690 ] = 63, -- Killing Spree

    --------------------------------------------------------
    -- WARLOCK

    -- Affliction
    [ 47843 ] = 71, -- Unstable Affliction
    [ 59164 ] = 71, -- Haunt

    -- Destruction
    [ 47847 ] = 72, -- Shadowfury
    [ 30302 ] = 72, -- Nether Protection
    [ 34935 ] = 72, -- Backlash
    [ 17962 ] = 72, -- Conflagrate

    -- Demonology
    [ 59672 ] = 73, -- Metamorphosis

    --------------------------------------------------------
    -- WARRIOR

    -- Protection
    [ 12809 ] = 81, -- Concussion Blow
    [ 47498 ] = 81, -- Devastate

    -- Arms
    [ 56638 ] = 82, -- Taste for Blood
    [ 64976 ] = 82, -- Juggernaut
    [ 47486 ] = 82, -- Mortal Strike
    [ 12292 ] = 82, -- Death Wish
    [ 29834 ] = 82, -- Second Wind (Rank 1)
    [ 29838 ] = 82, -- Second Wind (Rank 2)
    [ 46924 ] = 82, -- Bladestorm
    
    -- Fury
    [ 23881 ] = 83, -- Bloodthirst
    [ 46916 ] = 83, -- Bloodsurge

    --------------------------------------------------------
    -- PRIEST

    -- Discipline
    [ 10060 ] = 91, -- Power Infusion
    [ 33206 ] = 91, -- Pain Suppression
    [ 45234 ] = 91, -- Focused Will
    [ 45242 ] = 91, -- Focused Will
    [ 45243 ] = 91, -- Focused Will
    [ 45244 ] = 91, -- Focused Will
    [ 52800 ] = 91, -- Borrowed Time
    [ 59887 ] = 91, -- Borrowed Time
    [ 59888 ] = 91, -- Borrowed Time
    [ 59890 ] = 91, -- Borrowed Time
    [ 59891 ] = 91, -- Borrowed Time
    [ 47509 ] = 91, -- Divine Aegis
    [ 47511 ] = 91, -- Divine Aegis
    [ 47515 ] = 91, -- Divine Aegis
    [ 47517 ] = 91, -- Grace
    [ 47930 ] = 91, -- Grace
    [ 47508 ] = 91, -- Aspiration
    [ 57470 ] = 91, -- Renewed Hope
    [ 63944 ] = 91, -- Renewed Hope
    [ 47540 ] = 91, -- Penance
    [ 53005 ] = 91, -- Penance
    [ 53006 ] = 91, -- Penance
    [ 53007 ] = 91, -- Penance

    -- Holy
    [ 33143 ] = 92, -- Blessed Resilience
    [ 20711 ] = 92, -- Spirit of Redemption
    [ 724 ] = 92, -- Lightwell
    [ 34861 ] = 92, -- Circle of Healing
    [ 47788 ] = 92, -- Guardian Spirit
    [ 33142 ] = 92, -- Blessed Resilience

    -- Shadow
    [ 15473 ] = 93, -- Shadowform
    [ 34914 ] = 93, -- Vampiric Touch (Rank 1)
    [ 34916 ] = 93, -- Vampiric Touch (Rank 2)
    [ 34917 ] = 93, -- Vampiric Touch (Rank 3)
    [ 48159 ] = 93, -- Vampiric Touch (Rank 4)
    [ 48160 ] = 93, -- Vampiric Touch (Rank 5)
    [ 64044 ] = 93, -- Psychic Horror
    [ 47585 ] = 93, -- Dispersion
};

function SpecSpells:GetSpec(spellID)
    return specSpells[spellID];
end