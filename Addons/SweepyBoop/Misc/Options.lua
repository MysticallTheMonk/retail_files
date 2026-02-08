local addonName, addon = ...;

addon.GetMiscOptions = function (order, icon, SweepyBoopLDB)
    local optionGroup = {
        order = order,
        type = "group",
        childGroups = "tab",
        name = "Misc",
        get = function(info) return SweepyBoop.db.profile.misc[info[#info]] end,
        set = function(info, val)
            SweepyBoop.db.profile.misc[info[#info]] = val;
            SweepyBoop.db.profile.misc.lastModified = GetTime();
        end,
        handler = SweepyBoop,
        args = {
            general = {
                order = 1,
                type = "group",
                name = "General",
                args = {
                    -- header1 = {
                    --     order = 1,
                    --     type = "header",
                    --     name = "Healer in crowd control reminder in arena",
                    -- },
                    -- healerInCrowdControl = {
                    --     order = 2,
                    --     type = "toggle",
                    --     width = 0.675,
                    --     name = addon.FORMAT_TEXTURE(addon.ICON_PATH("spell_nature_polymorph")) .. " Enabled",
                    --     set = function (info, val)
                    --         SweepyBoop.db.profile.misc[info[#info]] = val;
                    --         SweepyBoop.db.profile.misc.lastModified = GetTime();
                    --         SweepyBoop:SetupHealerInCrowdControl();
                    --     end
                    -- },
                    -- healerInCrowdControlSound = {
                    --     order = 3,
                    --     type = "toggle",
                    --     width = 0.75,
                    --     name = addon.FORMAT_ATLAS("chatframe-button-icon-voicechat") .. " Play sound",
                    --     hidden = function ()
                    --         return ( not SweepyBoop.db.profile.misc.healerInCrowdControl );
                    --     end
                    -- },
                    -- healerInCrowdControlTest = {
                    --     order = 4,
                    --     type = "execute",
                    --     width = "half",
                    --     name = "Test",
                    --     func = "TestHealerInCrowdControl",
                    --     hidden = function ()
                    --         return ( not SweepyBoop.db.profile.misc.healerInCrowdControl );
                    --     end
                    -- },
                    -- healerInCrowdControlHide = {
                    --     order = 5,
                    --     type = "execute",
                    --     width = "half",
                    --     name = "Hide",
                    --     func = "HideTestHealerInCrowdControl",
                    --     hidden = function ()
                    --         return ( not SweepyBoop.db.profile.misc.healerInCrowdControl );
                    --     end
                    -- },
                    -- newline = {
                    --     order = 6,
                    --     type = "description",
                    --     width = "full",
                    --     name = "",
                    --     hidden = function ()
                    --         return ( not SweepyBoop.db.profile.misc.healerInCrowdControl );
                    --     end
                    -- },
                    -- healerInCrowdControlSize = {
                    --     order = 7,
                    --     type = "range",
                    --     width = 0.8,
                    --     min = 30,
                    --     max = 200,
                    --     step = 1,
                    --     name = "Icon size",
                    --     set = function (info, val)
                    --         SweepyBoop.db.profile.misc[info[#info]] = val;
                    --         SweepyBoop.db.profile.misc.lastModified = GetTime();
                    --         SweepyBoop:UpdateHealerInCrowdControl();
                    --     end,
                    --     hidden = function ()
                    --         return ( not SweepyBoop.db.profile.misc.healerInCrowdControl );
                    --     end
                    -- },
                    -- healerInCrowdControlOffsetX = {
                    --     order = 8,
                    --     type = "range",
                    --     width = 1,
                    --     min = -500,
                    --     max = 500,
                    --     step = 1,
                    --     name = "X offset",
                    --     set = function (info, val)
                    --         SweepyBoop.db.profile.misc[info[#info]] = val;
                    --         SweepyBoop.db.profile.misc.lastModified = GetTime();
                    --         SweepyBoop:UpdateHealerInCrowdControl();
                    --     end,
                    --     hidden = function ()
                    --         return ( not SweepyBoop.db.profile.misc.healerInCrowdControl );
                    --     end
                    -- },
                    -- healerInCrowdControlOffsetY = {
                    --     order = 9,
                    --     type = "range",
                    --     width = 1,
                    --     min = -500,
                    --     max = 500,
                    --     step = 1,
                    --     name = "Y offset",
                    --     set = function (info, val)
                    --         SweepyBoop.db.profile.misc[info[#info]] = val;
                    --         SweepyBoop.db.profile.misc.lastModified = GetTime();
                    --         SweepyBoop:UpdateHealerInCrowdControl();
                    --     end,
                    --     hidden = function ()
                    --         return ( not SweepyBoop.db.profile.misc.healerInCrowdControl );
                    --     end
                    -- },

                    header2 = {
                        order = 10,
                        type = "header",
                        name = "",
                    },
                    queueReminder = {
                        order = 11,
                        type = "toggle",
                        width = "full",
                        name = addon.FORMAT_TEXTURE(addon.ICON_PATH("ability_racial_timeismoney")) .. " PvP Queue Timer",
                        desc = "Shows a timer on arena / battlefield queue pop, and plays an alert when it's about to expire",
                        set = function (info, val)
                            SweepyBoop.db.profile.misc[info[#info]] = val;
                            SweepyBoop:SetupQueueReminder();
                        end
                    },

                    header3 = {
                        order = 12,
                        type = "header",
                        name = "Unit frames",
                    },
                    combatIndicator = {
                        order = 13,
                        type = "toggle",
                        width = "full",
                        name = addon.FORMAT_ATLAS("countdown-swords") .. " Show combat indicators on unit frames",
                        desc = "Show combat indicator icons on Player / Target / Focus frames",
                        set = function(info, val)
                            SweepyBoop.db.profile.misc[info[#info]] = val;
                            SweepyBoop.db.profile.misc.lastModified = GetTime();
                            SweepyBoop:SetupCombatIndicator();
                        end,
                    },
                    alwaysShowDruidComboPoints = {
                        order = 14,
                        type = "toggle",
                        width = "full",
                        name = addon.FORMAT_TEXTURE(addon.ICON_PATH("ability_druid_mangle")) .. " Always show Druid combo points",
                        set = function (info, val)
                            SweepyBoop.db.profile.misc[info[#info]] = val;
                            SweepyBoop.db.profile.misc.lastModified = GetTime();
                            SweepyBoop:SetupAlwaysShowDruidComboPoints();
                        end,
                    },
                    fixEvokerCastBars = {
                        order = 15,
                        type = "toggle",
                        width = "full",
                        name = addon.FORMAT_TEXTURE(addon.ICON_PATH("Classicon_evoker")) .. " Fix Evoker cast bars",
                        set = function (info, val)
                            SweepyBoop.db.profile.misc[info[#info]] = val;
                            SweepyBoop.db.profile.misc.lastModified = GetTime();
                            --SweepyBoop:SetupFixEvokerCastbars();
                        end,
                    },

                    header4 = {
                        order = 16,
                        type = "header",
                        name = "Arena",
                    },
                    hideBlizzArenaFrames = {
                        order = 17,
                        type = "toggle",
                        width = "full",
                        name = addon.FORMAT_TEXTURE(addon.ICON_PATH("achievement_arena_3v3_3")) .. " Hide Blizzard arena frames",
                        set = function (info, val)
                            SweepyBoop.db.profile.misc[info[#info]] = val;
                            SweepyBoop.db.profile.misc.lastModified = GetTime();
                            SweepyBoop:SetupHideBlizzArenaFrames();
                        end,
                        hidden = function ()
                            return ( not ( Gladius or GladiusEx or sArena ) );
                        end
                    },
                    arenaSurrenderEnabled = {
                        order = 18,
                        width = "full",
                        type = "toggle",
                        name = addon.FORMAT_TEXTURE(addon.ICON_PATH("inv_pet_exitbattle")) .. " Type /afk to surrender, type /gg to leave without confirmation",
                        desc = "Disabling this option requires a UI reload to take effect",
                        set = function (info, val)
                            SweepyBoop.db.profile.misc[info[#info]] = val;
                            SweepyBoop.db.profile.misc.lastModified = GetTime();
                            if ( val == false ) then
                                ReloadUI();
                            end
                        end,
                    },

                    showDampenPercentage = {
                        order = 19,
                        width = "full",
                        type = "toggle",
                        name = addon.FORMAT_TEXTURE(addon.ICON_PATH("achievement_bg_winsoa_underxminutes")) .. " Show dampen percentage on the arena widget",
                    },

                    healerIndicator = {
                        order = 20,
                        type = "toggle",
                        name = addon.FORMAT_ATLAS("Icon-Healer") .. " Show healer indicator on arena frames",
                        desc = "To make it easier to identify the healer in case of class stacking",
                        width = "full",
                        hidden = function ()
                            return ( not ( Gladius or sArena ) );
                        end
                    },

                    header6 = {
                        order = 21,
                        type = "header",
                        name = "",
                    },

                    showMinimapIcon = {
                        order = 22,
                        type = "toggle",
                        width = "full",
                        name = addon.FORMAT_TEXTURE(addon.INTERFACE_SWEEPY .. "Art/Logo") .. " Show minimap icon for invoking options UI",
                        set = function(info, val)
                            SweepyBoop.db.profile.minimap.hide = ( not val );
                            if val then
                                icon:Show(addonName);
                            else
                                icon:Hide(addonName);
                            end
                        end,
                        get = function (info)
                            return ( not SweepyBoop.db.profile.minimap.hide );
                        end
                    }
                },
            },

            gismo = {
                order = 2,
                type = "group",
                name = "Range checker",
                args = {
                    supportGismo = {
                        order = 1,
                        type = "input",
                        width = "full",
                        name = addon.FORMAT_ATLAS("GarrisonTroops-Health") .. " Support the original WA author",
                        desc = "Press Ctrl+C to copy URL",
                        dialogControl = "InlineLink-SweepyBoop",
                        get = function ()
                            return "https://www.twitch.tv/gismodruid";
                        end
                    },

                    rangeCheckerEnabled = {
                        order = 2,
                        type = "toggle",
                        width = 0.8,
                        name = "|A:CircleMaskScalable:20:20:0:0:0:255:0|a Enabled",
                        set = function (info, val)
                            SweepyBoop.db.profile.misc[info[#info]] = val;
                            SweepyBoop.db.profile.misc.lastModified = GetTime();
                            SweepyBoop:SetupRangeChecker();
                        end
                    },

                    rangeCheckerShowTest = {
                        order = 3,
                        type = "execute",
                        name = "Test",
                        width = 0.8,
                        func = "TestRangeChecker",
                    },
                    rangeCheckerHideTest = {
                        order = 4,
                        type = "execute",
                        name = "Hide",
                        width = 0.8,
                        func = "HideTestRangeChecker",
                    },

                    breaker1 = {
                        order = 5,
                        type = "description",
                        name = "",
                    },

                    rangeCheckerSize = {
                        order = 6,
                        type = "range",
                        width = 0.8,
                        min = 4,
                        max = 64,
                        step = 1,
                        name = "Indicator size",
                        set = function (info, val)
                            SweepyBoop.db.profile.misc[info[#info]] = val;
                            SweepyBoop.db.profile.misc.lastModified = GetTime();
                            SweepyBoop:RefreshRangeCheckerTestMode();
                        end,
                    },
                    rangeCheckerOffsetX = {
                        order = 7,
                        type = "range",
                        width = 0.8,
                        min = -250,
                        max = 250,
                        step = 1,
                        name = "X offset",
                        set = function (info, val)
                            SweepyBoop.db.profile.misc[info[#info]] = val;
                            SweepyBoop.db.profile.misc.lastModified = GetTime();
                            SweepyBoop:RefreshRangeCheckerTestMode();
                        end,
                    },
                    rangeCheckerOffsetY = {
                        order = 8,
                        type = "range",
                        width = 0.8,
                        min = -250,
                        max = 250,
                        step = 1,
                        name = "Y offset",
                        set = function (info, val)
                            SweepyBoop.db.profile.misc[info[#info]] = val;
                            SweepyBoop.db.profile.misc.lastModified = GetTime();
                            SweepyBoop:RefreshRangeCheckerTestMode();
                        end,
                    },

                    breaker2 = {
                        order = 9,
                        type = "header",
                        name = "Tracked spells",
                    },
                },
            }
        },
    };

    local index = 10;
    for _, classID in ipairs(addon.CLASSORDER) do
        local classInfo = C_CreatureInfo.GetClassInfo(classID);
        local classFile = classInfo.classFile;
        optionGroup.args.gismo.args[classFile] = {
            order = index,
            type = "input",
            width = 0.8,
            name = classInfo.className,
            get = function (info)
                return tostring(SweepyBoop.db.profile.misc.rangeCheckerSpells[info[#info]]);
            end,
            set = function (info, val)
                SweepyBoop.db.profile.misc.rangeCheckerSpells[info[#info]] = val;
                SweepyBoop.db.profile.misc.lastModified = GetTime();
            end,
            pattern = "^%d+$", -- allow numbers only
        };
        index = index + 1;
    end

    return optionGroup;
end
