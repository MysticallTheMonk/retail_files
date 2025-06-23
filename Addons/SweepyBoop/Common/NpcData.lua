local _, addon = ...;

addon.NpcOption = {
    Hide = 0,
    Show = 1,
    ShowWithIcon = 2, -- Units we should be aware (but might be hard to kill)
    Highlight = 3, -- For units that should be killed instantly or avoided at any cost :) (e.g., DK Reanimation)
};

addon.HUNTERPET = 165189;

-- Have to use NpcID because non-US locales can return different names for totems, minions, etc.
-- To find the NpcID of a unit, target it and type:
-- /run npcID = select(6, strsplit("-", UnitGUID("target"))); print(npcID)
if addon.PROJECT_MAINLINE then
    addon.importantNpcList = { -- Use table with consecutive indexes to preserve the order
        {
            classID = addon.CLASSID.DEATHKNIGHT,
            npcs = {
                { npcID = 106041, name = "Reanimation", icon = 210128, default = addon.NpcOption.Highlight }, -- stuns for 3s and takes 10% HP
                { npcID = 149555, name = "Raise Abomination", icon = 455395, default = addon.NpcOption.Show },
                { npcID = 26125, name = "Raise Dead", icon = 46585, default = addon.NpcOption.Hide, isCritter = true },
                { npcID = 24207, name = "Army of the Dead", icon = 220143, default = addon.NpcOption.Hide, isCritter = true },
            }
        },
        {
            classID = addon.CLASSID.DRUID,
            npcs = {
                { npcID = 54983, name = "Treant", icon = 102693, default = addon.NpcOption.Hide },
            }
        },
        {
            classID = addon.CLASSID.EVOKER,
            npcs = {
                { npcID = 185800, name = "Past Self", icon = 371869, default = addon.NpcOption.Show },
            }
        },
        {
            classID = addon.CLASSID.HUNTER,
            npcs = {
                { npcID = 105419, name = "Dire Beast: Basilisk", icon = 205691, default = addon.NpcOption.Show },

                -- Hunter pets all have the same npcID, add here so they don't get hidden in battlegrounds
                { npcID = addon.HUNTERPET, name = "Pet", icon = 267116, default = addon.NpcOption.Show, isCritter = true },
            }
        },
        {
            classID = addon.CLASSID.MAGE,
            npcs = {
                { npcID = 178819, name = "Ice Wall", icon = 352278, default = addon.NpcOption.Show },
                { npcID = 208441, name = "Water Elemental", icon = 12472, default = addon.NpcOption.Hide, isCritter = true },
                { npcID = 31216, name = "Mirror Image", icon = 55342, default = addon.NpcOption.Hide },
            }
        },
        {
            classID = addon.CLASSID.MONK,
            npcs = {
                { npcID = 63508, name = "Xuen", icon = 123904, default = addon.NpcOption.Hide, isCritter = true },
                { npcID = 69791, name = "Storm, Earth and Fire (Red)", icon = 137639, default = addon.NpcOption.Hide, isCritter = true },
                { npcID = 69792, name = "Storm, Earth and Fire (Green)", icon = 137639, default = addon.NpcOption.Hide, isCritter = true },
            }
        },
        {
            classID = addon.CLASSID.PALADIN,
            npcs = {
                { npcID = 114565, name = "Guardian of the Forgotten Queen", icon = 228049, default = addon.NpcOption.Highlight },
            }
        },
        {
            classID = addon.CLASSID.PRIEST,
            npcs = {
                { npcID = 101398, name = "Psyfiend", icon = 199824, default = addon.NpcOption.Highlight },
                { npcID = 225672, name = "Shadow", icon = 8122, default = addon.NpcOption.Highlight }, -- casts fear
                { npcID = 224466, name = "Voidwraith", icon = 451234, default = addon.NpcOption.Show },
                { npcID = 62982, name = "Mindbender", icon = 123040, default = addon.NpcOption.Show },
                { npcID = 19668, name = "Shadowfiend", icon = 34433, default = addon.NpcOption.Show },
                { npcID = 65282, name = "Void Tendrils", icon = 108920, default = addon.NpcOption.Show },
            }
        },
        {
            classID = addon.CLASSID.SHAMAN,
            npcs = {
                { npcID = 5925, name = "Grounding Totem", icon = 204336, default = addon.NpcOption.Highlight },
                { npcID = 53006, name = "Spirit Link Totem", icon = 98008, default = addon.NpcOption.Highlight },
                { npcID = 5913, name = "Tremor Totem", icon = 8143, default = addon.NpcOption.Highlight },
                { npcID = 104818, name = "Ancestral Protection Totem", icon = 207399, default = addon.NpcOption.Highlight },
                { npcID = 61245, name = "Capacitor Totem", icon = 192058, default = addon.NpcOption.Highlight },
                { npcID = 105451, name = "Counterstrike Totem", icon = 204331, default = addon.NpcOption.Highlight },
                { npcID = 59764, name = "Healing Tide Totem", icon = 108280, default = addon.NpcOption.Highlight },
                { npcID = 179867, name = "Static Field Totem", icon = 355580, default = addon.NpcOption.Highlight },

                { npcID = 59712, name = "Stone Bulwark Totem", icon = 108270, default = addon.NpcOption.Show }, -- hard to kill
                { npcID = 100943, name = "Earthen Wall Totem", icon = 198838, default = addon.NpcOption.Show }, -- hard to kill, just try to fight outside of its range
                { npcID = 60561, name = "Earthgrab Totem", icon = 51485, default = addon.NpcOption.Show }, -- gets players out of stealth
                { npcID = 105427, name = "Totem of Wrath", icon = 204330, default = addon.NpcOption.Show },
                { npcID = 194117, name = "Stoneskin Totem", icon = 383017, default = addon.NpcOption.Show },
                { npcID = 5923, name = "Poison Cleansing Totem", icon = 383013, default = addon.NpcOption.Show },
                { npcID = 194118, name = "Tranquil Air Totem", icon = 383019, default = addon.NpcOption.Show },
                { npcID = 225409, name = "Surging Totem", icon = 444995, default = addon.NpcOption.Show },
                { npcID = 95061, name = "Greater Fire Elemental", icon = 198067, default = addon.NpcOption.Show },
                { npcID = 61029, name = "Primal Fire Elemental", icon = 198067, default = addon.NpcOption.Show },
                { npcID = 95072, name = "Greater Earth Elemental", icon = 19704, default = addon.NpcOption.Show },
                { npcID = 61056, name = "Primal Earth Elemental", icon = 19704, default = addon.NpcOption.Show },

                { npcID = 3527, name = "Healing Stream Totem", icon = 5394, default = addon.NpcOption.Hide },
                { npcID = 78001, name = "Cloudburst Totem", icon = 157153, default = addon.NpcOption.Hide },
                { npcID = 97285, name = "Wind Rush Totem", icon = 192077, default = addon.NpcOption.Hide },
                { npcID = 2630, name = "Earthbind Totem", icon = 2484, default = addon.NpcOption.Hide },
                { npcID = 97369, name = "Liquid Magma Totem", icon = 192222, default = addon.NpcOption.Hide },
            }
        },
        {
            classID = addon.CLASSID.WARLOCK,
            npcs = {
                { npcID = 135002, name = "Demonic Tyrant", icon = 265187, default = addon.NpcOption.Show },
                { npcID = 107024, name = "Fel Lord", icon = 212459, default = addon.NpcOption.Show },
                { npcID = 196111, name = "Pit Lord", icon = 138789, default = addon.NpcOption.Show },
                { npcID = 89, name = "Infernal", icon = 1122, default = addon.NpcOption.Show },

                -- Primary pets (so they don't get hidden in battlegrounds)
                { npcID = 103673, name = "Darkglare", icon = 205180, default = addon.NpcOption.Show },
                { npcID = 416, name = "Imp", icon = 688, default = addon.NpcOption.Show },
                { npcID = 1860, name = "Voidwalker", icon = 697, default = addon.NpcOption.Show },
                { npcID = 417, name = "Felhunter", icon = 691, default = addon.NpcOption.ShowWithIcon },
                { npcID = 1863, name = "Sayaad", icon = 366222, default = addon.NpcOption.ShowWithIcon },
                { npcID = 17252, name = "Felguard", icon = 30146, default = addon.NpcOption.Show },

                -- Pets that should be hidden
                { npcID = 98035, name = "Dreadstalker", icon = 104316, default = addon.NpcOption.Hide, isCritter = true },
                { npcID = 143622, name = "Wild Imp", icon = 105174, default = addon.NpcOption.Hide, isCritter = true },
            }
        },
    };
elseif addon.PROJECT_CATA then
    addon.importantNpcList = {
        {
            classID = addon.CLASSID.DEATHKNIGHT,
            npcs = {
                { npcID = 27829, name = "Ebon Gargoyle", icon = 49206, default = addon.NpcOption.Highlight },
                { npcID = 26125, name = "Raise Dead", icon = 46585, default = addon.NpcOption.Hide, isCritter = true },
                { npcID = 24207, name = "Army of the Dead", icon = 42650, default = addon.NpcOption.Hide, isCritter = true },
            }
        },
        {
            classID = addon.CLASSID.HUNTER,
            npcs = {
                { npcID = addon.HUNTERPET, name = "Pet", icon = 883, default = addon.NpcOption.Show, isCritter = true },
            }
        },
        {
            classID = addon.CLASSID.MAGE,
            npcs = {
                { npcID = 510, name = "Water Elemental", icon = 31687, default = addon.NpcOption.Show, isCritter = true },
            }
        },
        {
            classID = addon.CLASSID.PRIEST,
            npcs = {
                { npcID = 19668, name = "Shadowfiend", icon = 34433, default = addon.NpcOption.Show },
            }
        },
        {
            classID = addon.CLASSID.SHAMAN,
            npcs = {
                { npcID = 5925, name = "Grounding Totem", icon = 8177, default = addon.NpcOption.Highlight },
                { npcID = 53006, name = "Spirit Link Totem", icon = 98008, default = addon.NpcOption.Highlight },
                { npcID = 5913, name = "Tremor Totem", icon = 8143, default = addon.NpcOption.Highlight },
                { npcID = 3527, name = "Healing Stream Totem", icon = 5394, default = addon.NpcOption.Show },
                { npcID = 10467, name = "Mana Tide Totem", icon = 16191, default = addon.NpcOption.Show },
                { npcID = 3579, name = "Stoneclaw Totem", icon = 5730, default = addon.NpcOption.Show },

                { npcID = 15430, name = "Earth Elemental Totem", icon = 2062, default = addon.NpcOption.Show },
                { npcID = 15439, name = "Fire Elemental Totem", icon = 2894, default = addon.NpcOption.Show },
                { npcID = 15438, name = "Greater Fire Elemental", icon = 2894, default = addon.NpcOption.Show },
                { npcID = 15352, name = "Greater Earth Elemental", icon = 2062, default = addon.NpcOption.Show },
                { npcID = 2630, name = "Earthbind Totem", icon = 2484, default = addon.NpcOption.Show },

                { npcID = 5873, name = "Stoneskin Totem", icon = 8071, default = addon.NpcOption.Hide },                
            }
        },
        {
            classID = addon.CLASSID.WARLOCK,
            npcs = {
                { npcID = 416, name = "Imp", icon = 688, default = addon.NpcOption.Show },
                { npcID = 1860, name = "Voidwalker", icon = 697, default = addon.NpcOption.Show },
                { npcID = 417, name = "Felhunter", icon = 691, default = addon.NpcOption.ShowWithIcon },
                { npcID = 17252, name = "Felguard", icon = 30146, default = addon.NpcOption.Show },
                { npcID = 143622, name = "Wild Imp", icon = 71521, default = addon.NpcOption.Hide, isCritter = true },
            }
        },
    };
else
    addon.importantNpcList = {
        {
            classID = addon.CLASSID.DEATHKNIGHT,
            npcs = {
                { npcID = 27829, name = "Ebon Gargoyle", icon = 49206, default = addon.NpcOption.Highlight },
                { npcID = 26125, name = "Raise Dead", icon = 46585, default = addon.NpcOption.Hide, isCritter = true },
                { npcID = 24207, name = "Army of the Dead", icon = 42650, default = addon.NpcOption.Hide, isCritter = true },
            }
        },
        {
            classID = addon.CLASSID.HUNTER,
            npcs = {
                { npcID = addon.HUNTERPET, name = "Pet", icon = 883, default = addon.NpcOption.Show, isCritter = true },
            }
        },
        {
            classID = addon.CLASSID.MAGE,
            npcs = {
                { npcID = 510, name = "Water Elemental", icon = 31687, default = addon.NpcOption.Show, isCritter = true },
            }
        },
        {
            classID = addon.CLASSID.MONK,
            npcs = {
                { npcID = 63508, name = "Xuen", icon = 123904, default = addon.NpcOption.Hide, isCritter = true },
                { npcID = 69791, name = "Storm, Earth and Fire (Red)", icon = 137639, default = addon.NpcOption.Hide, isCritter = true },
                { npcID = 69680, name = "Storm, Earth and Fire (Green)", icon = 137639, default = addon.NpcOption.Hide, isCritter = true },
            }
        },
        {
            classID = addon.CLASSID.PRIEST,
            npcs = {
                { npcID = 19668, name = "Shadowfiend", icon = 34433, default = addon.NpcOption.Show },
                { npcID = 62982, name = "Mindbender", icon = 123040, default = addon.NpcOption.Show },
            }
        },
        {
            classID = addon.CLASSID.SHAMAN,
            npcs = {
                { npcID = 5925, name = "Grounding Totem", icon = 8177, default = addon.NpcOption.Highlight },
                { npcID = 53006, name = "Spirit Link Totem", icon = 98008, default = addon.NpcOption.Highlight },
                { npcID = 5913, name = "Tremor Totem", icon = 8143, default = addon.NpcOption.Highlight },

                { npcID = 59764, name = "Healing Tide Totem", icon = 108280, default = addon.NpcOption.Show },
                { npcID = 3527, name = "Healing Stream Totem", icon = 5394, default = addon.NpcOption.Show },
                { npcID = 10467, name = "Mana Tide Totem", icon = 16191, default = addon.NpcOption.Show },

                { npcID = 15430, name = "Earth Elemental Totem", icon = 2062, default = addon.NpcOption.Show },
                { npcID = 15439, name = "Fire Elemental Totem", icon = 2894, default = addon.NpcOption.Show },
                { npcID = 15438, name = "Greater Fire Elemental", icon = 2894, default = addon.NpcOption.Show },
                { npcID = 5929, name = "Magma Totem", icon = 8190, default = addon.NpcOption.Show },
                { npcID = 2523, name = "Searing Totem", icon = 3599, default = addon.NpcOption.Show },

                { npcID = 15352, name = "Greater Earth Elemental", icon = 2062, default = addon.NpcOption.Show },
                { npcID = 2630, name = "Earthbind Totem", icon = 2484, default = addon.NpcOption.Show },
                { npcID = 60561, name = "Earthgrab Totem", icon = 51485, default = addon.NpcOption.Show },
            }
        },
        {
            classID = addon.CLASSID.WARLOCK,
            npcs = {
                { npcID = 416, name = "Imp", icon = 688, default = addon.NpcOption.Show },
                { npcID = 1860, name = "Voidwalker", icon = 697, default = addon.NpcOption.Show },
                { npcID = 417, name = "Felhunter", icon = 691, default = addon.NpcOption.ShowWithIcon },
                { npcID = 17252, name = "Felguard", icon = 30146, default = addon.NpcOption.Show },
            }
        },
    };
end

addon.CritterNPCs = {};

if addon.TEST_MODE then
    local testClass;
    if addon.PROJECT_MAINLINE then
        testClass = {
            classID = addon.CLASSID.DRUID,
            npcs = {
                { npcID = 219250, name = "PVP Training Dummy", icon = 204336, default = addon.NpcOption.Highlight },
                { npcID = 225985, name = "Kelpfist", icon = 204336, default = addon.NpcOption.Show },
            },
        };
    else
        testClass = {
            classID = addon.CLASSID.DRUID,
            npcs = {
                { npcID = 46647, name = "Training Dummy", icon = 8177, default = addon.NpcOption.Highlight },
            },
        };
    end
    table.insert(addon.importantNpcList, testClass);
end

addon.iconTexture = {};
--for classID, spells in pairs(addon.importantNpcList) do
for _, classEntry in ipairs(addon.importantNpcList) do
    for _, npcEntry in ipairs(classEntry.npcs) do
        -- Convert npcID to string since this returns string GUID: local npcID = select(6, strsplit("-", guid));
        local npcID, icon = tostring(npcEntry.npcID), C_Spell.GetSpellTexture(npcEntry.icon);
        addon.iconTexture[npcID] = icon;
    end
end

addon.GetNpcIdFromGuid = function (guid)
    local npcID = select ( 6, strsplit ( "-", guid ) );
    if (npcID) then
        return tonumber ( npcID );
    end

    return 0;
end

addon.CheckNpcWhiteList = function (unitId)
    if ( not SweepyBoop.db.profile.nameplatesEnemy.filterEnabled ) then
        return addon.NpcOption.Show, false; -- Filter is disabled, show everything
    end

    local npcID = select ( 6, strsplit ( "-", UnitGUID(unitId) ) );
    local isWhitelisted = SweepyBoop.db.profile.nameplatesEnemy.filterList[tostring(npcID)]; -- nil means Hide
    local isCritter = addon.CritterNPCs[tonumber(npcID)];
    return isWhitelisted, isCritter;
end

addon.FillDefaultToNpcOptions = function(profile)
    for _, classEntry in ipairs(addon.importantNpcList) do
        for _, npcEntry in ipairs(classEntry.npcs) do
            profile[tostring(npcEntry.npcID)] = npcEntry.default;
        end
    end
end

addon.AppendNpcOptionsToGroup = function(group)
    group.args = {};

    group.args.reset = {
        order = 1,
        type = "execute",
        name = "Reset to default",
        func = function()
            addon.FillDefaultToNpcOptions(SweepyBoop.db.profile.nameplatesEnemy.filterList);
        end,
    };

    local index = 2;
    for _, classEntry in ipairs(addon.importantNpcList) do
        local classInfo = C_CreatureInfo.GetClassInfo(classEntry.classID);
        local classGroup = {
            order = index,
            type = "group",
            icon = addon.ICON_ID_CLASSES,
			iconCoords = CLASS_ICON_TCOORDS[classInfo.classFile],
            name = classInfo.className,
            args = {},
        };

        local spellIdx = 1;
        for _, npcEntry in ipairs(classEntry.npcs) do
            -- https://warcraft.wiki.gg/wiki/SpellMixin
            local spell = Spell:CreateFromSpellID(npcEntry.icon);
            spell:ContinueOnSpellLoad(function()
                addon.SPELL_DESCRIPTION[npcEntry.icon] = spell:GetSpellDescription();
            end)

            local texture = C_Spell.GetSpellTexture(npcEntry.icon);
            classGroup.args[tostring(npcEntry.npcID)] = {
                order = spellIdx,
                type = "select",
                width = "full",
                values = {
                    [addon.NpcOption.Hide] = "Hide",
                    [addon.NpcOption.Show] = "Nameplate",
                    [addon.NpcOption.ShowWithIcon] = "Nameplate + icon",
                    [addon.NpcOption.Highlight] = "Nameplate + pulsing icon",
                },
                name = addon.FORMAT_TEXTURE(texture) .. " " .. npcEntry.name,
                desc = function ()
                    return addon.SPELL_DESCRIPTION[npcEntry.icon] or "";
                end,
            };

            if npcEntry.isCritter then
                addon.CritterNPCs[npcEntry.npcID] = true;
            end

            spellIdx = spellIdx + 1;
        end

        group.args[tostring(classEntry.classID)] = classGroup;
        index = index + 1;
    end
end
