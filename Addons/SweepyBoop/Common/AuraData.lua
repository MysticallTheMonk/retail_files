local _, addon = ...;

addon.AuraParent = {}; -- For quick look-up on parent aura ID

if addon.PROJECT_MAINLINE then
    addon.DebuffList = { -- Use table with consecutive indexes to preserve the order
        {
            classID = addon.CLASSID.DEATHKNIGHT,
            auras = {
                { spellId = 191587, default = true }, -- Virulent Plague
                { spellId = 194310, default = true }, -- Festering Wound
                { spellId = 55095, default = true }, -- Frost Fever
                { spellId = 55078, default = true }, -- Blood Plague

                { spellId = 45524, default = true }, -- Chains of Ice

                { spellId = 356528 }, -- Necrotic Wound
                { spellId = 390276 }, -- Rotten Touch
            }
        },
        {
            classID = addon.CLASSID.DEMONHUNTER,
            auras = {
                { spellId = 390155, default = true }, -- Serrated Glaive
                { spellId = 391191, default = true }, -- Burning Wound

                { spellId = 390181 }, -- Soulscar
                { spellId = 213405 }, -- Master of the Glaive
            }
        },
        {
            classID = addon.CLASSID.DRUID,
            auras = {
                { spellId = 164812, default = true }, -- Moonfire
                    { spellId = 155625, parent = 164812 }, -- Moonfire (Lunar Inspiration)
                { spellId = 164815, default = true }, -- Sunfire
                { spellId = 155722, default = true }, -- Rake
                { spellId = 1079, default = true }, -- Rip
                { spellId = 391889, default = true }, -- Adaptive Swarm
                { spellId = 405233, default = true}, -- Thrash

                { spellId = 236021 }, -- Ferocious Wound
                { spellId = 274838 }, -- Feral Frenzy
                { spellId = 439531 }, -- Bloodseeker Vines
            }
        },
        {
            classID = addon.CLASSID.EVOKER,
            auras = {
                { spellId = 357209, default = true }, -- Fire Breath
            }
        },
        {
            classID = addon.CLASSID.HUNTER,
            auras = {
                { spellId = 212431, default = true }, -- Explosive Shot
                { spellId = 271788, default = true }, -- Serpent Sting
                { spellId = 5116, default = true }, -- Concussive Shot

                { spellId = 217200 }, -- Barbed Shot
                { spellId = 468572 }, -- Black Arrow
            }
        },
        {
            classID = addon.CLASSID.MAGE,
            auras = {
                { spellId = 210824, default = true }, -- Touch of the Magi
                { spellId = 31589, default = true }, -- Slow

                { spellId = 205708 }, -- Chilled
                { spellId = 228358 }, -- Winter's Chill

                { spellId = 12654 }, -- Ignite
                { spellId = 217694 }, -- Living Bomb
                    { spellId = 244813, parent = 217694 }, -- Living Bomb
            }
        },
        {
            classID = addon.CLASSID.MONK,
            auras = {
                { spellId = 116095, default = true }, -- Disable

                { spellId = 228287 }, -- Mark of the Crane
                { spellId = 451433}, -- Acclamation
                { spellId = 392983 }, -- Strike of the Windlord
                { spellId = 122470 }, -- Touch of Karma
                { spellId = 115804 }, -- Mortal Wounds
            }
        },
        {
            classID = addon.CLASSID.PALADIN,
            auras = {
                { spellId = 343721, default = true }, -- Final Reckoning
                { spellId = 197277, default = true }, -- Judgment
                { spellId = 403695, default = true }, -- Truth's Wake
                { spellId = 383346, default = true }, -- Expurgation

                { spellId = 408383 }, -- Judgment of Justice
            }
        },
        {
            classID = addon.CLASSID.PRIEST,
            auras = {
                { spellId = 589, default = true }, -- Shadow Word: Pain
                { spellId = 34914, default = true }, -- Vampiric Touch
                { spellId = 335467, default = true }, -- Devouring Plague
                { spellId = 214621, default = true }, -- Schism
                { spellId = 375901, default = true }, -- Mindgames
                { spellId = 323716, default = true }, -- Thoughtsteal
            }
        },
        {
            classID = addon.CLASSID.ROGUE,
            auras = {
                { spellId = 703, default = true }, -- Garrote
                { spellId = 1943, default = true }, -- Rupture
                { spellId = 360194, default = true }, -- Deathmark
                { spellId = 121411, default = true }, -- Crimson Tempest
                { spellId = 394036, default = true }, -- Serrated Bone Spike

                { spellId = 381628 }, -- Internal Bleeding
                { spellId = 385627 }, -- Kingsbane
                { spellId = 5760 }, -- Numbing Poison
                { spellId = 3409 }, -- Crippling Poison
                { spellId = 383414 }, -- Amplifying Poison
                { spellId = 2818 }, -- Deadly Poison
                { spellId = 8680 }, -- Wound Poison
            }
        },
        {
            classID = addon.CLASSID.SHAMAN,
            auras = {
                { spellId = 188389, default = true }, -- Flame Shock
                { spellId = 196840, default = true }, -- Frost Shock
                { spellId = 197209, default = true }, -- Lightning Rod

                { spellId = 3600 }, -- Earthbind
                { spellId = 334168 }, -- Lashing Flames
            }
        },
        {
            classID = addon.CLASSID.WARLOCK,
            auras = {
                { spellId = 316099, default = true }, -- Unstable Affliction
                { spellId = 980, default = true }, -- Agony
                { spellId = 146739, default = true }, -- Corruption
                { spellId = 27243, default = true }, -- Seed of Corruption
                { spellId = 48181, default = true }, -- Haunt
                { spellId = 205179, default = true }, -- Phantom Singularity
                { spellId = 702, default = true }, -- Curse of Weakness
                { spellId = 1714, default = true}, -- Curse of Tongues

                { spellId = 157736 }, -- Immolate
                { spellId = 386997 }, -- Soul Rot

                { spellId = 334275 }, -- Curse of Exhaustion
                { spellId = 410598 }, -- Soul Rip
            }
        },
        {
            classID = addon.CLASSID.WARRIOR,
            auras = {
                { spellId = 1715, default = true }, -- Hamstring
                { spellId = 376080, default = true }, -- Champion's Spear
                { spellId = 208086, default = true }, -- Colossus Smash (Warbreaker)
                { spellId = 354788, default = true }, -- Slaughterhouse

                { spellId = 388539 }, -- Rend
                { spellId = 383704 }, -- Fatal Mark
                { spellId = 397364 }, -- Thunderous Roar
            }
        },
    };
elseif addon.PROJECT_CATA then
    addon.DebuffList = {
        {
            classID = addon.CLASSID.DEATHKNIGHT,
            auras = {
                { spellId = 55095, default = true }, -- Frost Fever
                { spellId = 55078, default = true }, -- Blood Plague
                { spellId = 45524, default = true }, -- Chains of Ice
                { spellId = 73975, default = true }, -- Necrotic Strike
            }
        },
        {
            classID = addon.CLASSID.DRUID,
            auras = {
                { spellId = 8921, default = true }, -- Moonfire
                { spellId = 5570, default = true }, -- Insect Swarm
                { spellId = 93402, default = true }, -- Sunfire
                { spellId = 91565, default = true }, -- Faerie Fire
                { spellId = 9007, default = true }, -- Pounce Bleed
                { spellId = 1822, default = true }, -- Rake
                { spellId = 1079, default = true }, -- Rip
                { spellId = 33745, default = true }, -- Lacerate
                { spellId = 33878, default = true }, -- Mangle (Bear)
                { spellId = 33876, default = true }, -- Mangle (Cat)
                { spellId = 77758, default = true }, -- Thrash
                { spellId = 58180, default = true }, -- Infected Wounds
                { spellId = 50259, default = true }, -- Dazed (Feral Charge)
            }
        },
        {
            classID = addon.CLASSID.HUNTER,
            auras = {
                { spellId = 82654, default = true }, -- Widow Venom
                { spellId = 94528, default = true }, -- Flare
                { spellId = 1130, default = true }, -- Hunter's Mark
                { spellId = 13797, default = true }, -- Immolation Trap
                { spellId = 1978, default = true }, -- Serpent Sting
                { spellId = 2974, default = true }, -- Wing Clip
                { spellId = 13812, default = true }, -- Explosive Trap
                { spellId = 13810, default = true }, -- Ice Trap
            }
        },
        {
            classID = addon.CLASSID.MAGE,
            auras = {
                { spellId = 44614, default = true }, -- Frostfire Bolt
                { spellId = 116, default = true }, -- Frostbolt
                { spellId = 11113, default = true }, -- Blast Wave
                { spellId = 11366, default = true }, -- Pyroblast
                { spellId = 92315, default = true }, -- Pyroblast!
                { spellId = 44457, default = true }, -- Living Bomb
                { spellId = 22959, default = true }, -- Critical Mass
                { spellId = 83853, default = true }, -- Combustion
                { spellId = 413841, default = true }, -- Ignite
                { spellId = 12355, default = true }, -- Impact
                { spellId = 64346, default = true }, -- Fiery Payback (Fire Mage Disarm)
            }
        },
        {
            classID = addon.CLASSID.PALADIN,
            auras = {
                { spellId = 31803, default = true }, -- Censure
            }
        },
        {
            classID = addon.CLASSID.PRIEST,
            auras = {
                { spellId = 87178, default = true }, -- Mind Spike
                { spellId = 2944, default = true }, -- Devouring Plague
                { spellId = 34914, default = true }, -- Vampiric Touch
                { spellId = 589, default = true }, -- Shadow Word: Pain
            }
        },
        {
            classID = addon.CLASSID.ROGUE,
            auras = {
                { spellId = 1943, default = true }, -- Rupture
                { spellId = 89775, default = true }, -- Hemorrhage Glyph Bleed
                { spellId = 91021, default = true }, -- Find Weakness
                { spellId = 703, default = true }, -- Garrote (Bleed)
                { spellId = 26679, default = true }, -- Deadly Throw
                { spellId = 8647, default = true }, -- Expose Armor
            }
        },
        {
            classID = addon.CLASSID.SHAMAN,
            auras = {
                { spellId = 8050, default = true }, -- Flame Shock
                { spellId = 8056, default = true }, -- Frost Shock
                { spellId = 8042, default = true }, -- Earth Shock
                { spellId = 3600, default = true }, -- Earth Bind
                { spellId = 39796, default = true }, -- Stoneclaw Totem
            }
        },
        {
            classID = addon.CLASSID.WARLOCK,
            auras = {
                { spellId = 172, default = true }, -- Corruption
                { spellId = 87389, default = true }, -- Corruption (Seed of Corruption version)
                { spellId = 18223, default = true }, -- Curse of Exhaustion
                { spellId = 1490, default = true }, -- Curse of the Elements
                { spellId = 702, default = true }, -- Curse of Exhaustion
                { spellId = 1714, default = true }, -- Curse of Tongues
                { spellId = 980, default = true }, -- Agony
                { spellId = 48181, default = true }, -- Haunt
                { spellId = 27243, default = true }, -- Seed of Corruption
                { spellId = 47960, default = true }, -- Shadowflame
                { spellId = 348, default = true }, -- Immolate
                { spellId = 30108, default = true }, -- Unstable Affliction
                { spellId = 603, default = true }, -- Bane of Doom
                { spellId = 80240, default = true }, -- Bane of Havoc
                { spellId = 85421, default = true }, -- Burning Embers
                { spellId = 43523, default = true }, -- Unstable Affliction
            }
        },
        {
            classID = addon.CLASSID.WARRIOR,
            auras = {
                { spellId = 94009, default = true }, -- Rend
                { spellId = 86346, default = true }, -- Colossus Smash
                { spellId = 12721, default = true }, -- Deep Wounds
                { spellId = 6343, default = true }, -- Thunderclap
                { spellId = 12809, default = true }, -- Concussion Blow
                { spellId = 12294, default = true }, -- Mortal Strike
                { spellId = 413763, default = true }, -- Deep Wounds
            }
        },
    };
else
    addon.DebuffList = {};
end

for _, classEntry in ipairs(addon.DebuffList) do
    for _, auraEntry in ipairs(classEntry.auras) do
        if auraEntry.parent then
            addon.AuraParent[auraEntry.spellId] = auraEntry.parent;
        end
    end
end

if addon.PROJECT_MAINLINE then
    addon.BuffList = {
        {
            classID = addon.CLASSID.DEATHKNIGHT,
            auras = {
                { spellId = 48707, default = true }, -- Anti-Magic Shell
                    { spellId = 410358, parent = 48707 }, -- Anti-Magic Shell (Spellwarden)
                    { spellId = 444741, parent = 48707 }, -- Anti-Magic Shell (Horsemen's Aid)
                { spellId = 48792, default = true }, -- Icebound Fortitude
                { spellId = 49039, default = true }, -- Lichborne
            }
        },
        {
            classID = addon.CLASSID.DEMONHUNTER,
            auras = {
                { spellId = 354610, default = true }, -- Glimpse (Vengeful Retreat)
                { spellId = 196555, default = true }, -- Netherwalk
                { spellId = 212800, default = true }, -- Blur
                { spellId = 188501, default = true }, -- Spectral Sight
            }
        },
        {
            classID = addon.CLASSID.DRUID,
            auras = {
                { spellId = 473909, default = true }, -- Ancient of Lore
                { spellId = 61336, default = true }, -- Survival Instincts
                { spellId = 102342, default = true }, -- Ironbark
                { spellId = 22812, default = true }, -- Barkskin
    
                { spellId = 102352 }, -- Cenarion Ward
                { spellId = 33763 }, -- Lifebloom
                    { spellId = 188550, parent = 33763 }, -- Lifebloom (Undergrowth)
            }
        },
        {
            classID = addon.CLASSID.EVOKER,
            auras = {
                { spellId = 378464, default = true }, -- Nullifying Shroud
                { spellId = 378441, default = true }, -- Time Stop
                { spellId = 363916, default = true }, -- Obsidian Scales
            }
        },
        {
            classID = addon.CLASSID.HUNTER,
            auras = {
                { spellId = 186265, default = true }, -- Aspect of the Turtle
                { spellId = 53480, default = true }, -- Roar of Sacrifice
                { spellId = 54216, default = true }, -- Master's Call
                { spellId = 264735, default = true }, -- Survival of the Fittest
            }
        },
        {
            classID = addon.CLASSID.MAGE,
            auras = {
                { spellId = 45438, default = true }, -- Ice Block
                { spellId = 110909, default = true }, -- Alter Time
                    { spellId = 342246, parent = 110909 }, -- Alter Time
                { spellId = 198144, default = true }, -- Ice Form (immune to stuns)
    
                --{ spellId = 12544, parent = 45438 }, -- Frost Armor (For testing, mobs near Stone Cairn Lake in Elywnn Forest)
            }
        },
        {
            classID = addon.CLASSID.MONK,
            auras = {
                { spellId = 353319, default = true }, -- PeaceWeaver
                { spellId = 456499, default = true }, -- Absolute Serenity
                { spellId = 209584, default = true }, -- Zen Focus Tea
                { spellId = 116849, default = true }, -- Life Cocoon
                { spellId = 125174, default = true }, -- Touch of Karma
                { spellId = 122783 }, -- Diffuse Magic
            }
        },
        {
            classID = addon.CLASSID.PALADIN,
            auras = {
                { spellId = 642, default = true }, -- Divine Shield
                { spellId = 1022, default = true }, -- Blessing of Protection
                { spellId = 204018, default = true }, -- Blessing of Spellwarding
                { spellId = 6940, default = true }, -- Blessing of Sacrifice
                { spellId = 86659, default = true }, -- Guardian of Ancient Kings
                { spellId = 1044, default = true }, -- Blessing of Freedom
                    { spellId = 305395, parent = 1044 }, -- Blessing of Freedom (Unbound Freedom)
                { spellId = 184662 }, -- Shield of Vengeance
                { spellId = 498 }, -- Divine Protection
            }
        },
        {
            classID = addon.CLASSID.PRIEST,
            auras = {
                { spellId = 408558, default = true }, -- Phase Shift
                { spellId = 213610, default = true }, -- Holy Ward
                { spellId = 421453, default = true }, -- Ultimate Penitence
                { spellId = 33206, default = true }, -- Pain Suppression
                { spellId = 47788, default = true }, -- Guardian Spirit
                { spellId = 47585, default = true }, -- Dispersion
            }
        },
        {
            classID = addon.CLASSID.ROGUE,
            auras = {
                { spellId = 31224, default = true }, -- Cloak of Shadows
                { spellId = 5277, default = true }, -- Evasion
            }
        },
        {
            classID = addon.CLASSID.SHAMAN,
            auras = {
                { spellId = 409293, default = true }, -- Burrow
                { spellId = 108271, default = true }, -- Astral Shift
            }
        },
        {
            classID = addon.CLASSID.WARLOCK,
            auras = {
                { spellId = 104773, default = true }, -- Unending Resolve
                { spellId = 212295, default = true }, -- Nether Ward
            }
        },
        {
            classID = addon.CLASSID.WARRIOR,
            auras = {
                { spellId = 118038, default = true }, -- Die by the Sword
                { spellId = 184364, default = true }, -- Enraged Regeneration
                { spellId = 23920, default = true }, -- Spell Reflection
                { spellId = 227847, default = true }, -- Bladestorm
                    { spellId = 446035, parent = 227847 }, -- Bladestorm
            }
        },
        {
            name = "General",
            icon = "spell_nature_focusedmind",
            auras = {
                { spellId = 377362, default = true }, -- Precognition
            }
        }
    };
elseif addon.PROJECT_CATA then
    addon.BuffList = {
        {
            classID = addon.CLASSID.DEATHKNIGHT,
            auras = {
                { spellId = 48707, default = true }, -- Anti-Magic Shell
                { spellId = 48792, default = true }, -- Icebound Fortitude
                { spellId = 49039, default = true }, -- Lichborne
            }
        },
        {
            classID = addon.CLASSID.DRUID,
            auras = {
                { spellId = 61336, default = true }, -- Survival Instincts
                { spellId = 22812, default = true }, -- Barkskin

                --{ spellId = 61574, default = true }, -- Banner of the Horde (for testing)
            }
        },
        {
            classID = addon.CLASSID.HUNTER,
            auras = {
                { spellId = 19263, default = true }, -- Deterrence
            }
        },
        {
            classID = addon.CLASSID.MAGE,
            auras = {
                { spellId = 45438, default = true }, -- Ice Block
            }
        },
        {
            classID = addon.CLASSID.PALADIN,
            auras = {
                { spellId = 642, default = true }, -- Divine Shield
                { spellId = 1022, default = true }, -- Hand of Protection
            }
        },
        {
            classID = addon.CLASSID.PRIEST,
            auras = {
                { spellId = 33206, default = true }, -- Pain Suppression
                { spellId = 47585, default = true }, -- Dispersion
            }
        },
        {
            classID = addon.CLASSID.ROGUE,
            auras = {
                { spellId = 31224, default = true }, -- Cloak of Shadows
                { spellId = 5277, default = true }, -- Evasion
            }
        },
        -- {
        --     classID = addon.CLASSID.SHAMAN,
        --     auras = {

        --     }
        -- },
        -- {
        --     classID = addon.CLASSID.WARLOCK,
        --     auras = {

        --     }
        -- },
        -- {
        --     classID = addon.CLASSID.WARRIOR,
        --     auras = {

        --     }
        -- }
    };
else
    addon.BuffList = {};
end

for _, classEntry in ipairs(addon.BuffList) do
    for _, auraEntry in ipairs(classEntry.auras) do
        if auraEntry.parent then
            addon.AuraParent[auraEntry.spellId] = auraEntry.parent;
        end
    end
end

addon.FillDefaultToAuraOptions = function(profile, auraList)
    for _, classEntry in ipairs(auraList) do
        for _, auraEntry in ipairs(classEntry.auras) do
            profile[tostring(auraEntry.spellId)] = auraEntry.default;
        end
    end
end

addon.AppendAuraOptionsToGroup = function(group, auraList, profileName)
    group.args = {};

    group.args.reset = {
        order = 1,
        type = "execute",
        name = "Reset to default",
        func = function()
            local profile = SweepyBoop.db.profile.nameplatesEnemy[profileName];
            addon.FillDefaultToAuraOptions(profile, auraList);
        end,
    };

    local index = 2;
    for _, classEntry in ipairs(auraList) do
        local classGroup;
        if classEntry.classID then
            local classInfo = C_CreatureInfo.GetClassInfo(classEntry.classID);
            classGroup = {
                order = index,
                type = "group",
                icon = addon.ICON_ID_CLASSES,
                iconCoords = CLASS_ICON_TCOORDS[classInfo.classFile],
                name = classInfo.className,
                args = {},
            };
        else
            classGroup = {
                order = index,
                type = "group",
                icon = addon.ICON_PATH(classEntry.icon),
                name = classEntry.name,
                args = {},
            };
        end

        local auraIdx = 1;
        for _, auraEntry in ipairs(classEntry.auras) do
            if ( not auraEntry.parent ) then

                -- https://warcraft.wiki.gg/wiki/SpellMixin
                local spell = Spell:CreateFromSpellID(auraEntry.spellId);
                spell:ContinueOnSpellLoad(function()
                    addon.SPELL_DESCRIPTION[auraEntry.spellId] = spell:GetSpellDescription();
                end)

                local texture = C_Spell.GetSpellTexture(auraEntry.spellId);
                classGroup.args[tostring(auraEntry.spellId)] = {
                    order = auraIdx,
                    type = "toggle",
                    width = "full",
                    name = addon.FORMAT_TEXTURE(texture) .. " " .. C_Spell.GetSpellName(auraEntry.spellId),
                    desc = function ()
                        return addon.SPELL_DESCRIPTION[auraEntry.spellId] or "";
                    end
                };
                auraIdx = auraIdx + 1;

            end
        end

        group.args[tostring(classEntry.classID)] = classGroup;
        index = index + 1;
    end
end
