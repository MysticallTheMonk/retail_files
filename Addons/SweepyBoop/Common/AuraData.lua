local _, addon = ...;

addon.AuraParent = {}; -- For quick look-up on parent aura ID

if addon.PROJECT_MAINLINE then
    addon.DebuffList = { -- Use table with consecutive indexes to preserve the order
        {
            classID = addon.CLASSID.DEATHKNIGHT,
            auras = {
                -- { spellId = 191587, default = true }, -- Virulent Plague
                -- { spellId = 194310, default = true }, -- Festering Wound
                -- { spellId = 55095, default = true }, -- Frost Fever
                -- { spellId = 55078, default = true }, -- Blood Plague

                -- { spellId = 45524, default = true }, -- Chains of Ice

                -- { spellId = 356528 }, -- Necrotic Wound
                -- { spellId = 390276 }, -- Rotten Touch
            }
        },
        {
            classID = addon.CLASSID.DEMONHUNTER,
            auras = {
                -- { spellId = 390155, default = true }, -- Serrated Glaive
                -- { spellId = 391191, default = true }, -- Burning Wound

                -- { spellId = 390181 }, -- Soulscar
                -- { spellId = 213405 }, -- Master of the Glaive
            }
        },
        {
            classID = addon.CLASSID.DRUID,
            auras = {
                -- { spellId = 164812, default = true }, -- Moonfire
                --     { spellId = 155625, parent = 164812 }, -- Moonfire (Lunar Inspiration)
                -- { spellId = 164815, default = true }, -- Sunfire
                -- { spellId = 155722, default = true }, -- Rake
                -- { spellId = 1079, default = true }, -- Rip
                -- { spellId = 391889, default = true }, -- Adaptive Swarm
                -- { spellId = 405233, default = true}, -- Thrash

                -- { spellId = 236021 }, -- Ferocious Wound
                -- { spellId = 274838 }, -- Feral Frenzy
                -- { spellId = 439531 }, -- Bloodseeker Vines
            }
        },
        {
            classID = addon.CLASSID.EVOKER,
            auras = {
                -- { spellId = 357209, default = true }, -- Fire Breath
            }
        },
        {
            classID = addon.CLASSID.HUNTER,
            auras = {
                -- { spellId = 212431, default = true }, -- Explosive Shot
                -- { spellId = 271788, default = true }, -- Serpent Sting
                -- { spellId = 5116, default = true }, -- Concussive Shot

                -- { spellId = 217200 }, -- Barbed Shot
                -- { spellId = 468572 }, -- Black Arrow
            }
        },
        {
            classID = addon.CLASSID.MAGE,
            auras = {
                -- { spellId = 210824, default = true }, -- Touch of the Magi
                -- { spellId = 31589, default = true }, -- Slow

                -- { spellId = 205708 }, -- Chilled
                -- { spellId = 228358 }, -- Winter's Chill

                -- { spellId = 12654 }, -- Ignite
                -- { spellId = 217694 }, -- Living Bomb
                --     { spellId = 244813, parent = 217694 }, -- Living Bomb
            }
        },
        {
            classID = addon.CLASSID.MONK,
            auras = {
                -- { spellId = 116095, default = true }, -- Disable

                -- { spellId = 228287 }, -- Mark of the Crane
                -- { spellId = 451433}, -- Acclamation
                -- { spellId = 392983 }, -- Strike of the Windlord
                -- { spellId = 122470 }, -- Touch of Karma
                -- { spellId = 115804 }, -- Mortal Wounds
            }
        },
        {
            classID = addon.CLASSID.PALADIN,
            auras = {
                -- { spellId = 343721, default = true }, -- Final Reckoning
                -- { spellId = 197277, default = true }, -- Judgment
                -- { spellId = 403695, default = true }, -- Truth's Wake
                -- { spellId = 383346, default = true }, -- Expurgation

                -- { spellId = 408383 }, -- Judgment of Justice
            }
        },
        {
            classID = addon.CLASSID.PRIEST,
            auras = {
                -- { spellId = 589, default = true }, -- Shadow Word: Pain
                -- { spellId = 34914, default = true }, -- Vampiric Touch
                -- { spellId = 335467, default = true }, -- Devouring Plague
                -- { spellId = 214621, default = true }, -- Schism
                -- { spellId = 375901, default = true }, -- Mindgames
                -- { spellId = 323716, default = true }, -- Thoughtsteal
            }
        },
        {
            classID = addon.CLASSID.ROGUE,
            auras = {
                -- { spellId = 703, default = true }, -- Garrote
                -- { spellId = 1943, default = true }, -- Rupture
                -- { spellId = 360194, default = true }, -- Deathmark
                -- { spellId = 121411, default = true }, -- Crimson Tempest
                -- { spellId = 394036, default = true }, -- Serrated Bone Spike

                -- { spellId = 381628 }, -- Internal Bleeding
                -- { spellId = 385627 }, -- Kingsbane
                -- { spellId = 5760 }, -- Numbing Poison
                -- { spellId = 3409 }, -- Crippling Poison
                -- { spellId = 383414 }, -- Amplifying Poison
                -- { spellId = 2818 }, -- Deadly Poison
                -- { spellId = 8680 }, -- Wound Poison
            }
        },
        {
            classID = addon.CLASSID.SHAMAN,
            auras = {
                -- { spellId = 188389, default = true }, -- Flame Shock
                -- { spellId = 196840, default = true }, -- Frost Shock
                -- { spellId = 197209, default = true }, -- Lightning Rod

                -- { spellId = 3600 }, -- Earthbind
                -- { spellId = 334168 }, -- Lashing Flames
            }
        },
        {
            classID = addon.CLASSID.WARLOCK,
            auras = {
                -- { spellId = 316099, default = true }, -- Unstable Affliction
                -- { spellId = 980, default = true }, -- Agony
                -- { spellId = 146739, default = true }, -- Corruption
                -- { spellId = 27243, default = true }, -- Seed of Corruption
                -- { spellId = 48181, default = true }, -- Haunt
                -- { spellId = 205179, default = true }, -- Phantom Singularity
                -- { spellId = 702, default = true }, -- Curse of Weakness
                -- { spellId = 1714, default = true}, -- Curse of Tongues

                -- { spellId = 157736 }, -- Immolate
                -- { spellId = 386997 }, -- Soul Rot

                -- { spellId = 334275 }, -- Curse of Exhaustion
                -- { spellId = 410598 }, -- Soul Rip
            }
        },
        {
            classID = addon.CLASSID.WARRIOR,
            auras = {
                -- { spellId = 1715, default = true }, -- Hamstring
                -- { spellId = 376080, default = true }, -- Champion's Spear
                -- { spellId = 208086, default = true }, -- Colossus Smash (Warbreaker)
                -- { spellId = 354788, default = true }, -- Slaughterhouse

                -- { spellId = 388539 }, -- Rend
                -- { spellId = 383704 }, -- Fatal Mark
                -- { spellId = 397364 }, -- Thunderous Roar
            }
        },
    };
else
    addon.DebuffList = {
        {
            classID = addon.CLASSID.DEATHKNIGHT,
            auras = {
                { spellId = 55078, default = true }, -- Blood Plague
                { spellId = 55095, default = true }, -- Frost Fever
                { spellId = 73975, default = true }, -- Necrotic Strike

                { spellId = 45524, default = true }, -- Chains of Ice
            }
        },
        {
            classID = addon.CLASSID.DRUID,
            auras = {
                { spellId = 6795, default = true }, -- Growl
                { spellId = 770, default = true }, -- Faerie Fire
                { spellId = 33745, default = true }, -- Lacerate
                { spellId = 8921, default = true }, -- Moonfire
                { spellId = 1822, default = true }, -- Rake
                { spellId = 1079, default = true }, -- Rip
                { spellId = 77758, default = true}, -- Thrash (Bear Form)
                { spellId = 106830, default = true }, -- Thrash (Cat Form)
                { spellId = 58180, default = true }, -- Infected Wounds
                { spellId = 93402, default = true }, -- Sunfire
            },
        },
        {
            classID = addon.CLASSID.HUNTER,
            auras = {
                { spellId = 5116, default = true }, -- Concussive Shot
                { spellId = 1130, default = true }, -- Hunter's Mark
                { spellId = 118253, default = true }, -- Serpent Sting
                { spellId = 82654, default = true }, -- Widow Venom
                { spellId = 53301, default = true }, -- Explosive Shot
            },
        },
        {
            classID = addon.CLASSID.MAGE,
            auras = {
                { spellId = 120, default = true }, -- Cone of Cold
                { spellId = 44614, default = true }, -- Frostfire Bolt
                { spellId = 31589, default = true }, -- Slow
                { spellId = 113092, default = true }, -- Frost Bomb (Slow)
                { spellId = 116, default = true }, -- Frostbolt

                { spellId = 114923 }, -- Nether Tempest
                { spellId = 44457 }, -- Living Bomb
                { spellId = 112948 }, -- Frost Bomb
                { spellId = 413841 }, -- Ignite
                { spellId = 11366 }, -- Pyroblast

                { spellId = 2120 }, -- Flamestrike
            }
        },
        {
            classID = addon.CLASSID.MONK,
            auras = {
                { spellId = 116095, default = true }, -- Disable
                { spellId = 116189, default = true }, -- Provoke

                { spellId = 122470 }, -- Touch of Karma
            },
        },
        {
            classID = addon.CLASSID.PALADIN,
            auras = {
                { spellId = 62124, default = true }, -- Hand of Reckoning
                { spellId = 20170, default = true }, -- Seal of Justice
            },
        },
        {
            classID = addon.CLASSID.PRIEST,
            auras = {
                { spellId = 14914, default = true }, -- Holy Fire
                { spellId = 589, default = true }, -- Shadow Word: Pain

                { spellId = 2944, default = true }, -- Devouring Plague
                { spellId = 34914, default = true }, -- Vampiric Touch
            },
        },
        {
            classID = addon.CLASSID.ROGUE,
            auras = {
                { spellId = 1943, default = true }, -- Rupture
                { spellId = 703, default = true }, -- Garrote
                { spellId = 122233, default = true }, -- Crimson Tempest
                { spellId = 89775, default = true }, -- Hemmorrhage
                { spellId = 137619, default = true }, -- Marked for Death
                { spellId = 79140, default = true }, -- Vendetta

                { spellId = 84617 }, -- Revealing Strike
                { spellId = 113746 }, -- Weakened Armor

                { spellId = 2818 }, -- Deadly Poison
                { spellId = 8680 }, -- Wound Poison
                { spellId = 5760 }, -- Numbing Poison
                { spellId = 3409 }, -- Crippling Poison
            },
        },
        {
            classID = addon.CLASSID.SHAMAN,
            auras = {
                { spellId = 8050, default = true }, -- Flame Shock
                { spellId = 8056, default = true }, -- Frost Shock

                { spellId = 61882 }, -- Earthquake
                { spellId = 51490 }, -- Thunderstorm
                { spellId = 17364 }, -- Stormstrike
            },
        },
        {
            classID = addon.CLASSID.WARLOCK,
            auras = {
                { spellId = 348, default = true }, -- Immolate
                { spellId = 80240, default = true }, -- Havoc
                { spellId = 980, default = true }, -- Agony
                { spellId = 146739, default = true }, -- Corruption
                { spellId = 48181, default = true }, -- Haunt
                { spellId = 27243, default = true }, -- Seed of Corruption
                { spellId = 30108, default = true }, -- Unstable Affliction
                { spellId = 47960, default = true }, -- Shadowflame


                -- Curses
                { spellId = 109466 }, -- Curse of Enfeeblement
                { spellId = 1490 }, -- Curse of the Elements
                { spellId = 18223 }, -- Curse of Exhaustion
            },
        },
        {
            classID = addon.CLASSID.WARRIOR,
            auras = {
                { spellId = 1715, default = true }, -- Hamstring
                { spellId = 86346, default = true }, -- Colossus Smash
                { spellId = 355, default = true }, -- Taunt

                { spellId = 115767 }, -- Deep Wounds
                { spellId = 7922 }, -- Charge Stun
                { spellId = 113344 }, -- Bloodbath
                { spellId = 147531 }, -- Bloodbath
                { spellId = 64382 }, -- Shattering Throw
                { spellId = 113746 }, -- Weakened Armor
            },
        },
    };
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
else
    addon.BuffList = {
        {
            classID = addon.CLASSID.DEATHKNIGHT,
            auras = {
                { spellId = 48707, default = true }, -- Anti-Magic Shell
                { spellId = 48792, default = true }, -- Icebound Fortitude
                { spellId = 49039, default = true }, -- Lichborne
            },
        },
        {
            classID = addon.CLASSID.DRUID,
            auras = {
                { spellId = 22812, default = true }, -- Barkskin
                { spellId = 102342, default = true }, -- Ironbark
                { spellId = 61336, default = true }, -- Survival Instincts

                -- Symbiosis
                { spellId = 110570, default = true }, -- Anti-Magic Shell
                { spellId = 110788, default = true }, -- Cloak of Shadows
                { spellId = 122291, default = true }, -- Unending Resolve
                { spellId = 110700, default = true }, -- Divine Shield
                { spellId = 110715, default = true }, -- Dispersion
                { spellId = 110575, default = true }, -- Icebound Fortitude
                { spellId = 110617, default = true }, -- Deterrence
                { spellId = 110696, default = true }, -- Ice Block
                { spellId = 126456, default = true }, -- Fortifying Brew
                { spellId = 110791, default = true }, -- Evasion
            },
        },
        {
            classID = addon.CLASSID.HUNTER,
            auras = {
                { spellId = 19263, default = true }, -- Deterrence
                { spellId = 54216, default = true }, -- Master's Call
                { spellId = 53480, default = true }, -- Roar of Sacrifice
            },
        },
        {
            classID = addon.CLASSID.MAGE,
            auras = {
                { spellId = 45438, default = true }, -- Ice Block
                { spellId = 110909, default = true }, -- Alter Time
                { spellId = 115610, default = true }, -- Temporal Shield
            },
        },
        {
            classID = addon.CLASSID.MONK,
            auras = {
                { spellId = 120954, default = true }, -- Fortifying Brew
                { spellId = 125174, default = true }, -- Touch of Karma
                { spellId = 116849, default = true }, -- Life Cocoon
                { spellId = 137562, default = true }, -- Nimble Brew

                { spellId = 122278 }, -- Dampen Harm
            },
        },
        {
            classID = addon.CLASSID.PALADIN,
            auras = {
                { spellId = 31821, default = true }, -- Devotion Aura
                { spellId = 642, default = true }, -- Divine Shield
                { spellId = 498, default = true }, -- Divine Protection
                { spellId = 1044, default = true }, -- Blessing of Freedom
                { spellId = 1022, default = true }, -- Blessing of Protection
                { spellId = 6940, default = true }, -- Blessing of Sacrifice

                { spellId = 86669 }, -- Guardian of Ancient Kings
                { spellId = 31842 }, -- Divine Favor
            },
        },
        {
            classID = addon.CLASSID.PRIEST,
            auras = {
                { spellId = 6346, default = true }, -- Fear Ward
                { spellId = 33206, default = true }, -- Pain Suppression
                { spellId = 47788, default = true }, -- Guardian Spirit
                { spellId = 47585, default = true }, -- Dispersion

                { spellId = 15286 }, -- Vampiric Embrace
            },
        },
        {
            classID = addon.CLASSID.ROGUE,
            auras = {
                { spellId = 31224, default = true }, -- Cloak of Shadows
                { spellId = 5277, default = true }, -- Evasion
                { spellId = 1966, default = true }, -- Feint
            },
        },
        {
            classID = addon.CLASSID.SHAMAN,
            auras = {
                { spellId = 108271, default = true }, -- Astral Shift
            },
        },
        {
            classID = addon.CLASSID.WARLOCK,
            auras = {
                { spellId = 104773, default = true }, -- Unending Resolve
                { spellId = 110913, default = true }, -- Dark Bargain
            },
        },
        {
            classID = addon.CLASSID.WARRIOR,
            auras = {
                { spellId = 18499, default = true }, -- Berserker Rage
                { spellId = 118038, default = true }, -- Die by the Sword
                { spellId = 55694, default = true }, -- Enraged Regeneration
                { spellId = 114028, default = true }, -- Mass Spell Reflection
                { spellId = 23920, default = true }, -- Spell Reflection
                { spellId = 871, default = true }, -- Shield Wall

                { spellId = 97463 }, -- Rallying Cry
            },
        },
    };
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

                local texture = addon.GetSpellTexture(auraEntry.spellId);
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
