local _, addon = ...;

addon.GetFriendlyNameplateOptions = function(order)
    local optionGroup = {
        order = order,
        type = "group",
        name = "Friendly class icons",
        get = function(info) return SweepyBoop.db.profile.nameplatesFriendly[info[#info]] end,
        set = function(info, val)
            SweepyBoop.db.profile.nameplatesFriendly[info[#info]] = val;
            SweepyBoop.db.profile.nameplatesFriendly.lastModified = GetTime();
            SweepyBoop:RefreshAllNamePlates();
        end,
        args = {
            classIconsEnabled = {
                order = 1,
                type = "toggle",
                name = addon.FORMAT_TEXTURE(addon.INTERFACE_SWEEPY .. "Art/Druid") .. " Enabled",
                desc = "Show class/pet icons on friendly players/pets",
                set = function(info, val)
                    SweepyBoop.db.profile.nameplatesFriendly.classIconsEnabled = val;
                    SweepyBoop.db.profile.nameplatesFriendly.lastModified = GetTime();
                    SweepyBoop:RefreshAllNamePlates(true);
                end
            },
            showSpecIcons = {
                order = 2,
                width = 1.5,
                type = "toggle",
                name = addon.FORMAT_TEXTURE(addon.SPEC_ICON_OTHERS_LOGO) .. " Show spec icons in PvP instances",
                hidden = function()
                    return ( not addon.PROJECT_MAINLINE ) or
                        ( not SweepyBoop.db.profile.nameplatesFriendly.classIconsEnabled ) or ( SweepyBoop.db.profile.nameplatesFriendly.classIconStyle == addon.CLASS_ICON_STYLE.ARROW );
                end
            },

            description1 = {
                order = 3,
                width = "full",
                type = "description",
                name = "|cFFFF0000" .. addon.EXCLAMATION .. " Enable \"Friendly Player Nameplates\" in Interface - Nameplates for class icons|r",
                hidden = function ()
                    return ( C_CVar.GetCVar("nameplateShowFriends") == "1" );
                end
            },
            description2 = {
                order = 4,
                width = "full",
                type = "description",
                name = addon.EXCLAMATION .. " Enable \"Minions\" in Interface - Nameplates for pet icons",
                hidden = function ()
                    return ( C_CVar.GetCVar("nameplateShowFriendlyPets") == "1" );
                end
            },

            newline1 = {
                order = 5,
                type = "description",
                name = "",
                hidden = function()
                    return ( not SweepyBoop.db.profile.nameplatesFriendly.classIconsEnabled );
                end
            },

            classIconStyle = {
                order = 6,
                type = "select",
                width = 1.25,
                values = {
                    [addon.CLASS_ICON_STYLE.ICON] = addon.FORMAT_TEXTURE(addon.INTERFACE_SWEEPY .. "Art/Druid") .. " WoW class icons",
                    [addon.CLASS_ICON_STYLE.ARROW] = addon.FORMAT_TEXTURE(addon.INTERFACE_SWEEPY .. "Art/ClassArrow") .. " Class color arrows",
                    [addon.CLASS_ICON_STYLE.ICON_AND_ARROW] =
                        addon.FORMAT_TEXTURE(addon.INTERFACE_SWEEPY .. "Art/ClassArrow")
                        .. addon.FORMAT_TEXTURE(addon.INTERFACE_SWEEPY .. "Art/Druid")
                        .. " Icon + party arrow",
                },
                name = "Icon style",
                hidden = function()
                    return ( not SweepyBoop.db.profile.nameplatesFriendly.classIconsEnabled ) or ( not addon.PROJECT_MAINLINE );
                end
            },
            partyArrowDesc = {
                order = 7,
                type = "description",
                name = addon.EXCLAMATION .. " Class-colored party arrows only show on party members in PvP instances",
                hidden = function()
                    return ( not SweepyBoop.db.profile.nameplatesFriendly.classIconsEnabled ) or ( not addon.PROJECT_MAINLINE )
                        or ( SweepyBoop.db.profile.nameplatesFriendly.classIconStyle ~= addon.CLASS_ICON_STYLE.ICON_AND_ARROW );
                end
            },

            newline2 = {
                order = 8,
                type = "description",
                name = "",
                hidden = function()
                    return ( not SweepyBoop.db.profile.nameplatesFriendly.classIconsEnabled );
                end
            },

            visibilityHeader = {
                order = 9,
                type = "header",
                name = "Visibility",
                hidden = function()
                    return ( not SweepyBoop.db.profile.nameplatesFriendly.classIconsEnabled );
                end
            },
            hideOutsidePvP = {
                order = 10,
                type = "toggle",
                name = addon.FORMAT_TEXTURE(addon.ICON_PATH("Inv_misc_rune_01")) .. " Hide in World",
                hidden = function()
                    return ( not SweepyBoop.db.profile.nameplatesFriendly.classIconsEnabled );
                end
            },
            hideInBattlegrounds = {
                order = 11,
                type = "toggle",
                width = 1.5,
                name = addon.FORMAT_TEXTURE(addon.ICON_ID_PVP_CURSOR) .. " Hide in Battlegrounds",
                hidden = function()
                    return ( not SweepyBoop.db.profile.nameplatesFriendly.classIconsEnabled );
                end
            },
            breaker1 = {
                order = 12,
                type = "header",
                name = "",
                hidden = function()
                    return ( not SweepyBoop.db.profile.nameplatesFriendly.classIconsEnabled );
                end
            },
            useHealerIcon = {
                order = 13,
                width = 1.35,
                type = "toggle",
                name = addon.HELAER_LOGO .. " Special icon for healers",
                hidden = function()
                    return ( not SweepyBoop.db.profile.nameplatesFriendly.classIconsEnabled );
                end
            },
            showHealerOnly = {
                order = 14,
                type = "toggle",
                name = addon.HELAER_LOGO .. " Show healers only",
                desc = "Hide class icons of non-healer players\nFlag carrier icons will still show if the option is enabled",
                hidden = function ()
                    return ( not SweepyBoop.db.profile.nameplatesFriendly.classIconsEnabled );
                end
            },
            showMyPetOnly = {
                order = 15,
                width = "full",
                type = "toggle",
                name = addon.FORMAT_TEXTURE(addon.ICON_ID_PET) .. " Show my pet only",
                desc = "Hide class icons of other players' pets\nThis option is not available in arenas",
                hidden = function ()
                    return ( not SweepyBoop.db.profile.nameplatesFriendly.classIconsEnabled );
                end
            },
            useFlagCarrierIcon = {
                order = 16,
                width = "full",
                type = "toggle",
                name = addon.FORMAT_TEXTURE(addon.FLAG_CARRIER_ALLIANCE_LOGO) .. " Show flag carrier icons in battlegrounds",
                desc = "Use special icons for friendly flag carriers\nThis overwrites the healer icon",
                hidden = function()
                    return ( not SweepyBoop.db.profile.nameplatesFriendly.classIconsEnabled ) or ( not addon.PROJECT_MAINLINE );
                end
            },
            targetHighlight = {
                order = 17,
                type = "toggle",
                width = "full",
                name = addon.FORMAT_ATLAS("charactercreate-ring-select") .. " Show target highlight",
                hidden = function()
                    return ( not SweepyBoop.db.profile.nameplatesFriendly.classIconsEnabled );
                end
            },
            classIconOffset = {
                order = 18,
                type = "range",
                min = -50,
                max = 150,
                step = 1,
                name = "Icon offset",
                desc = "Vertical offset of class / pet icons",
                hidden = function()
                    return ( not SweepyBoop.db.profile.nameplatesFriendly.classIconsEnabled );
                end
            },

            header1 = {
                order = 19,
                type = "header",
                name = "Icon size",
                hidden = function()
                    return ( not SweepyBoop.db.profile.nameplatesFriendly.classIconsEnabled );
                end
            },
            classIconSize = {
                order = 20,
                type = "range",
                width = 0.675,
                isPercent = true,
                min = 0.5,
                max = 2,
                step = 0.01,
                name = "Player",
                hidden = function()
                    return ( not SweepyBoop.db.profile.nameplatesFriendly.classIconsEnabled );
                end
            },
            healerIconSize = {
                order = 21,
                type = "range",
                width = 0.675,
                isPercent = true,
                min = 0.5,
                max = 2,
                step = 0.01,
                name = "Healer",
                hidden = function()
                    local config = SweepyBoop.db.profile.nameplatesFriendly;
                    return ( not config.classIconsEnabled ) or ( not config.useHealerIcon );
                end
            },
            flagCarrierIconSize = {
                order = 22,
                type = "range",
                width = 0.675,
                isPercent = true,
                min = 0.5,
                max = 2,
                step = 0.01,
                name = "Flag carrier",
                hidden = function()
                    local config = SweepyBoop.db.profile.nameplatesFriendly;
                    return ( not config.classIconsEnabled ) or ( not config.useFlagCarrierIcon ) or ( not addon.PROJECT_MAINLINE );
                end
            },
            petIconSize = {
                order = 23,
                type = "range",
                width = 0.675,
                isPercent = true,
                min = 0.5,
                max = 2,
                step = 0.01,
                name = "Pet",
                hidden = function()
                    return ( not SweepyBoop.db.profile.nameplatesFriendly.classIconsEnabled );
                end
            },

            breaker2 = {
                order = 24,
                type = "header",
                name = "",
                hidden = function()
                    return ( not SweepyBoop.db.profile.nameplatesFriendly.classIconsEnabled );
                end
            },

            classColorBorder = {
                order = 25,
                type = "toggle",
                width = 1.25,
                name = addon.FORMAT_ATLAS("charactercreate-ring-select") .. " Class-colored borders",
                hidden = function()
                    return ( not SweepyBoop.db.profile.nameplatesFriendly.classIconsEnabled );
                end
            },

            showPlayerName = {
                order = 26,
                type = "toggle",
                width = 1.25,
                name = addon.FORMAT_ATLAS("UI-ChatIcon-ODIN") .. " Class-colored names",
                desc = "Show class-colored names under class icons",
                hidden = function()
                    local config = SweepyBoop.db.profile.nameplatesFriendly;
                    return ( not config.classIconsEnabled ) or config.keepHealthBar;
                end
            },

            showCrowdControl = {
                order = 27,
                type = "toggle",
                width = "full",
                name = addon.FORMAT_TEXTURE(addon.ICON_PATH("spell_nature_polymorph")) .. " Show crowd controls on party members",
                desc = "Show crowd control icons instead of class icons during crowd control effects",
                hidden = function()
                    return ( not SweepyBoop.db.profile.nameplatesFriendly.classIconsEnabled ) or ( SweepyBoop.db.profile.nameplatesFriendly.classIconStyle == addon.CLASS_ICON_STYLE.ARROW );
                end
            },

            keepHealthBar = {
                order = 28,
                type = "toggle",
                width = 1.25,
                name = addon.FORMAT_ATLAS("MainPet-HealthBarFill") .. " Keep Blizzard health bar",
                desc = "Keep Blizzard health bars while showing class icons",
                hidden = function()
                    return ( not SweepyBoop.db.profile.nameplatesFriendly.classIconsEnabled );
                end
            },
        }
    };

    return optionGroup;
end

addon.GetEnemyNameplateOptions = function(order)
    local beastMasteryHunterIcon = ( addon.PROJECT_MAINLINE and addon.GetSpellTexture(267116) ) or addon.GetSpellTexture(19574);
    local optionGroup = {
        order = order,
        type = "group",
        childGroups = "tab",
        name = "Enemy nameplates",
        get = function(info) return SweepyBoop.db.profile.nameplatesEnemy[info[#info]] end,
        set = function(info, val)
            SweepyBoop.db.profile.nameplatesEnemy[info[#info]] = val;
            SweepyBoop.db.profile.nameplatesEnemy.lastModified = GetTime();
            SweepyBoop:RefreshAllNamePlates();
        end,
        args = {
            general = {
                order = 1,
                type = "group",
                name = "General",
                args = {
                    arenaNumbersEnabled = {
                        order = 1,
                        width = "full",
                        type = "toggle",
                        name = addon.FORMAT_TEXTURE(addon.ICON_PATH("inv_misc_number_1")) .. " Arena enemy player nameplate numbers",
                        desc = "Places arena numbers over enemy players' nameplates, e.g., 1 for arena1, and so on",
                    },

                    breaker2 = {
                        order = 2,
                        type = "header",
                        name = ( addon.PROJECT_MAINLINE and "Arena & battleground enemy spec icons" ) or "Arena enemy spec icons",
                    },
                    arenaSpecIconHealer = {
                        order = 3,
                        width = "full",
                        type = "toggle",
                        name = addon.FORMAT_TEXTURE(addon.SPEC_ICON_HEALER_LOGO) ..  " Show spec icon for healers",
                        desc = "Show spec icons on top of the nameplates of enemy healers",
                    },
                    arenaSpecIconHealerIcon = {
                        order = 4,
                        width = "full",
                        type = "toggle",
                        name = addon.SPEC_ICON_ENEMY_HEALER_LOGO .. " Show healer icon instead of spec icon for healers",
                        hidden = function ()
                            return ( not SweepyBoop.db.profile.nameplatesEnemy.arenaSpecIconHealer );
                        end
                    },
                    arenaSpecIconOthers = {
                        order = 5,
                        width = "full",
                        type = "toggle",
                        name = addon.FORMAT_TEXTURE(addon.SPEC_ICON_OTHERS_LOGO) .. " Show spec icon for non-healers",
                        desc = "Show a spec icon on top of the nameplate for enemy players that are not healers inside arenas",
                    },
                    arenaSpecIconAlignment = {
                        order = 6,
                        type = "select",
                        width = 0.75,
                        name = "Alignment",
                        values = {
                            [addon.SPEC_ICON_ALIGNMENT.TOP] = "Top",
                            [addon.SPEC_ICON_ALIGNMENT.LEFT] = "Left",
                            [addon.SPEC_ICON_ALIGNMENT.RIGHT] = "Right",
                        },
                        hidden = function ()
                            return ( not SweepyBoop.db.profile.nameplatesEnemy.arenaSpecIconHealer ) and ( not SweepyBoop.db.profile.nameplatesEnemy.arenaSpecIconOthers );
                        end
                    },
                    arenaSpecIconVerticalOffset = {
                        order = 7,
                        min = -150,
                        max = 150,
                        step = 1,
                        type = "range",
                        width = 0.85,
                        name = "Vertical offset",
                        hidden = function ()
                            if ( not SweepyBoop.db.profile.nameplatesEnemy.arenaSpecIconHealer ) and ( not SweepyBoop.db.profile.nameplatesEnemy.arenaSpecIconOthers ) then return true end
                            return ( SweepyBoop.db.profile.nameplatesEnemy.arenaSpecIconAlignment ~= addon.SPEC_ICON_ALIGNMENT.TOP );
                        end
                    },
                    arenaSpecIconScale = {
                        order = 8,
                        min = 50,
                        max = 300,
                        step = 1,
                        type = "range",
                        width = 0.75,
                        name = "Scale (%)",
                        hidden = function ()
                            return ( not SweepyBoop.db.profile.nameplatesEnemy.arenaSpecIconHealer ) and ( not SweepyBoop.db.profile.nameplatesEnemy.arenaSpecIconOthers );
                        end
                    },

                    breaker3 = {
                        order = 9,
                        type = "header",
                        name = "Nameplate Filters & Highlights",
                    },

                    hideHunterSecondaryPet = {
                        order = 10,
                        type = "toggle",
                        width = "full",
                        name = addon.FORMAT_TEXTURE(beastMasteryHunterIcon) .. " Hide beast mastery hunter secondary pets in arena",
                        desc = "Hide the extra pet from talents\nThis feature is not available in battlegrounds due to WoW API limitations",
                    },
                    filterEnabled = {
                        order = 11,
                        type = "toggle",
                        width = "full",
                        name = addon.FORMAT_TEXTURE(addon.ICON_ID_PVP_CURSOR) .. " Customize enemy units to hide / show / highlight",
                        desc = "Each unit's nameplate can be hidden, shown, or shown with a pulsing icon on top\nThis works in arenas and battlegrounds",
                    },
                    showCritterIcons = {
                        order = 12,
                        type = "toggle",
                        width = "full",
                        name = addon.FORMAT_ATLAS(addon.ICON_CRITTER) .. " Show critter icons for hidden pet nameplates",
                        desc = "Show a critter icon in place of pet nameplates hidden by the addon\nThis helps with situations such as casting Ring of the Frost on hunter pets, without actually showing all those nameplates to clutter the screen",
                        hidden = function ()
                            return ( not SweepyBoop.db.profile.nameplatesEnemy.filterEnabled ) and ( not SweepyBoop.db.profile.nameplatesEnemy.hideHunterSecondaryPet );
                        end
                    },
                    npcHighlightScale = {
                        order = 13,
                        type = "range",
                        name = "Highlight icon scale",
                        width = 1,
                        min = 0.5,
                        max = 3,
                        isPercent = true,
                        step = 1,
                        hidden = function()
                            return ( not SweepyBoop.db.profile.nameplatesEnemy.filterEnabled );
                        end,
                    },
                    npcHighlightOffset = {
                        order = 14,
                        type = "range",
                        name = "Highlight icon offset",
                        width = 1,
                        min = -50,
                        max = 150,
                        step = 1,
                        hidden = function()
                            return ( not SweepyBoop.db.profile.nameplatesEnemy.filterEnabled );
                        end,
                    },

                    auraFilterEnabled = {
                        order = 15,
                        type = "toggle",
                        width = "full",
                        name = addon.FORMAT_TEXTURE(addon.ICON_PATH("spell_shadow_shadowwordpain")) .. " Filter debuffs applied by myself",
                        desc = "Show whitelisted debuffs applied by myself"
                            .. "\n\nCrowd control debuffs are never filtered as they are critical for PvP",
                        set = function (info, val)
                            SweepyBoop.db.profile.nameplatesEnemy[info[#info]] = val;
                            SweepyBoop.db.profile.nameplatesEnemy.lastModified = GetTime();
                            SweepyBoop:RefreshAurasForAllNamePlates();
                        end
                    },

                    showBuffsOnEnemy = {
                        order = 16,
                        type = "toggle",
                        width = "full",
                        name = addon.FORMAT_TEXTURE(addon.ICON_PATH("spell_holy_divineshield")) .. " Show whitelisted buffs on enemy nameplates",
                        desc = "Show whitelisted buffs on enemy nameplates from all sources",
                        hidden = function ()
                            return ( not SweepyBoop.db.profile.nameplatesEnemy.auraFilterEnabled );
                        end,
                        set = function (info, val)
                            SweepyBoop.db.profile.nameplatesEnemy[info[#info]] = val;
                            SweepyBoop.db.profile.nameplatesEnemy.lastModified = GetTime();
                            SweepyBoop:RefreshAurasForAllNamePlates();
                        end
                    },
                },
            },

            filterList = {
                order = 2,
                type = "group",
                name = "Unit whitelist",
                get = function(info) return SweepyBoop.db.profile.nameplatesEnemy.filterList[info[#info]] end,
                set = function(info, val)
                    SweepyBoop.db.profile.nameplatesEnemy.filterList[info[#info]] = val;
                    SweepyBoop.db.profile.nameplatesEnemy.lastModified = GetTime();
                    SweepyBoop:RefreshAllNamePlates();
                end,
                args = {},
                hidden = function()
                    return ( not SweepyBoop.db.profile.nameplatesEnemy.filterEnabled );
                end
            },

            debuffWhiteList = {
                order = 3,
                type = "group",
                name = "Debuff whitelist",
                get = function(info) return SweepyBoop.db.profile.nameplatesEnemy.debuffWhiteList[info[#info]] end,
                set = function(info, val)
                    SweepyBoop.db.profile.nameplatesEnemy.debuffWhiteList[info[#info]] = val;
                    SweepyBoop.db.profile.nameplatesEnemy.lastModified = GetTime();
                    -- No need to refresh nameplates, just apply it on next UNIT_AURA
                end,
                args = {},
                hidden = function()
                    return ( not SweepyBoop.db.profile.nameplatesEnemy.auraFilterEnabled );
                end
            },

            buffWhiteList = {
                order = 4,
                type = "group",
                name = "Buff whitelist",
                get = function(info) return SweepyBoop.db.profile.nameplatesEnemy.buffWhiteList[info[#info]] end,
                set = function(info, val)
                    SweepyBoop.db.profile.nameplatesEnemy.buffWhiteList[info[#info]] = val;
                    SweepyBoop.db.profile.nameplatesEnemy.lastModified = GetTime();
                    -- No need to refresh nameplates, just apply it on next UNIT_AURA
                end,
                args = {},
                hidden = function()
                    return ( not SweepyBoop.db.profile.nameplatesEnemy.auraFilterEnabled ) or ( not SweepyBoop.db.profile.nameplatesEnemy.showBuffsOnEnemy );
                end
            },
        },
    };

    addon.AppendNpcOptionsToGroup(optionGroup.args.filterList);
    addon.AppendAuraOptionsToGroup(optionGroup.args.debuffWhiteList, addon.DebuffList, "debuffWhiteList");
    addon.AppendAuraOptionsToGroup(optionGroup.args.buffWhiteList, addon.BuffList, "buffWhiteList");

    return optionGroup;
end
