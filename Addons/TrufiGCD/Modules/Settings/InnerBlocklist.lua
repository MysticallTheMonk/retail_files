---@type string, Namespace
local _, ns = ...

local blocklistArray = {
    61391, -- Typhoon x2
    5374, -- Mutilate х3
    27576, -- Mutilate (off-hand) х3
    88263, -- Hammer of the Righteous х3
    32175, -- Stormstrike
    32176, -- Stormstrike (off-hand)
    96103, -- Raging Blow
    85384, -- Raging Blow (off-hand)
    57794, -- Heroic Leap
    52174, -- Heroic Leap
    135299, -- Tar Trap
    121473, -- Shadow Blade
    121474, -- Shadow Blade Off-hand
    114093, -- Windlash Off-Hand
    114089, -- Windlash
    115357, -- Windstrike
    115360, -- Windstrike Off-Hand
    127797, -- Ursol's Vortex
    102794, -- Ursol's Vortex
    50622, -- Bladestorm
    122128, -- Divine Star (Shadow Priest)
    110745, -- Divine Star
    120696, -- Halo (Shadow Priest)
    120692, -- Halo
    115464, -- Healing Sphere
    126526, -- Healing Sphere
    132951, -- Flare
    107270, -- Spinning Crane Kick
    198928, -- Cinderstorm shards (Fire Mage verified fix)
    84721, -- Frozen Orb shards (Frost Mage verified fix)
    222031, -- Chaos Strike 1 (DemonHunter unverified fix)
    197125, -- Chaos Strike 2 (DemonHunter unverified fix)
    199547, -- Chaos Strike 3 (DemonHunter unverified fix)
    227255, -- Spirit Bomb periodical
    225919, -- Fracture double hit
    225921, -- Fracture part 2
    228478, -- Soul Cleave part 2
    346665, -- Master of the Glaive (DH Class Tree Talent)
    370966, -- The Hunt Impact (DH Class Tree Talent)
    394007, -- Ready to Build (DF Engineering Accessoire)
    391775, -- What's Cookin', Good Lookin'? (DF Cooking Accessoire)
    384341, -- Critical Failure Prevention Unit (DF Engineering Item)
    7268, -- Arcane Missiles (Arcane Mage while channeling)
    7270, -- Arcane Missiles (Arcane Mage while channeling)
    37506, -- Scatter Shot (Hunt) x2
    228354, -- Flurry
    399960, -- Mutilate (SoD rune)
    399961, -- Mutilate (SoD rune)
    384338, -- Tinker Safety Fuses (DF Engineering Item)
    384489, -- Spring-Loaded Capacitor Casing (DF Engineering Item)
    146739, -- Corruption (Warlock Affliction)
    148187, -- Rushing Jade Wind (Monk)
    126664, -- Charge (second)
    408385, -- Crusader Strikes (Paladin talent that replaces auto-attack)
    214968, -- Necrotic Aura (Death Knight)
    400698, -- Griftah's All-Purpose Embellishing Powder
    307005, -- Arena Inbounds Marker
    363922, -- Dream Breath (Evoker)
    362019, -- Deep Breath (Evoker)
    403758, -- Breath of Eons (Evoker)
    362362, -- Dream Flight (Evoker)
    358733, -- Glide (Evoker)
    397374, -- [DNT] Clear Empower Cooldown (Evoker)
    367230, -- Spiritbloom (Evoker)
    371817, -- Recall (Evoker)
    396557, -- Verdan Embrace (Evoker)
    47666, -- Penance (Priest)
    47750, -- Penance (Priest)
    373130, -- Dark Reprimand (Priest)
    81782, -- Power Word: Barrier (Priest)
    185313, -- Shadow Dance (Rogue buff)
    221771, -- Storm, Earth, and Fire: Fixate (Monk buff)
    361652, -- Demonic Gateway
    228212, -- Arena Starting Area Marker
    463429, -- Griftah's All-Purpose Embellishing Powder
    421177, -- Disable ALL Mounts
    454455, -- Complicated Fuse Box
    467718, -- Bleak Arrows (Hunter)
    431398, -- Empyrean Hammer
    461867, -- Sacrosanct Crusade

    -- Unverified - from GCD History
    184707, -- Rampage
    184709, -- Rampage
    199672, -- Rupture
    201363, -- Rampage
    201364, -- Rampage
    204255, -- Soul Fragments
    213241, -- Felblade
    213243, -- Felblade
    218617, -- Rampage
    228597, -- Frostbolt
    272790, -- Frenzy; BM hunter buff
    276245, -- Env; envenom buff
    361195, -- Verdant Embrace friendly heal
    361509, -- Living Flame friendly heal
    383313, -- Abomination Limb periodical
    385060, -- Odyn's Fury
    385061, -- Odyn's Fury
    385062, -- Odyn's Fury
    385954 -- Shield Charge
}

local iconsBlocklistArray = {
    136243, -- Gear icon
}

ns.innerBlockList = {}
for _, spellId in ipairs(blocklistArray) do
    ns.innerBlockList[spellId] = true
end


ns.innerIconsBlocklist = {}
for _, spellId in ipairs(iconsBlocklistArray) do
    ns.innerIconsBlocklist[spellId] = true
end
