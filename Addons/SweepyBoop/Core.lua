local addonName, addon = ...;
addon.addonTitle = C_AddOns.GetAddOnMetadata(addonName, "Title");

SweepyBoop = LibStub("AceAddon-3.0"):NewAddon(addonName, "AceConsole-3.0", "AceSerializer-3.0");

local SweepyBoopLDB = LibStub("LibDataBroker-1.1"):NewDataObject(addonName, {
    type = "data source",
    text = addonName,
    icon = addon.INTERFACE_SWEEPY .. "Art/Logo",
    OnTooltipShow = function(tooltip)
        tooltip:SetText(addon.addonTitle, 1, 1, 1);
        tooltip:AddLine("Click to open options");
    end,
    OnClick = function()
        LibStub("AceConfigDialog-3.0"):Open(addonName);
    end,
})
local icon = LibStub("LibDBIcon-1.0");

local options = {
    name = addon.addonTitle,
    type = "group",
    args = {
        description = {
            order = 1,
            type = "description",
            fontSize = "large",
            image = addon.INTERFACE_SWEEPY .. "Art/Logo",
            imageWidth = 36,
            imageHeight = 36,
            name = "A lightweight addon to enhance your arena & battleground experience :)"
        },
    },
};

options.args.support = {
    order = 8,
    type = "group",
    name = "Support",
    args = {
        discordLink = {
            order = 1,
            type = "input",
            width = "full",
            name = addon.FORMAT_ATLAS("UI-ChatIcon-ODIN") .. " Join Discord for PvP UI support",
            desc = "Press Ctrl+C to copy URL",
            dialogControl = "InlineLink-SweepyBoop",
            get = function ()
                return "https://discord.gg/SMRxeZzVwc";
            end
        },

        donate = {
            order = 2,
            type = "input",
            width = "full",
            name = addon.FORMAT_ATLAS("GarrisonTroops-Health") .. " If feeling generous",
            desc = "Press Ctrl+C to copy URL",
            dialogControl = "InlineLink-SweepyBoop",
            get = function ()
                return "https://www.paypal.me/sweepyboop";
            end
        },
    },
};

local defaults = {
    profile = {
        nameplatesFriendly = {
            classIconsEnabled = true,
            classIconStyle = addon.CLASS_ICON_STYLE.ICON,
            showSpecIcons = true,
            hideOutsidePvP = false,
            hideInBattlegrounds = false;
            classIconSize = 1,
            healerIconSize = 1.25,
            flagCarrierIconSize = 1.5,
            petIconSize = 0.8,
            classIconOffset = 0,
            useHealerIcon = true,
            showHealerOnly = false,
            useFlagCarrierIcon = true,
            targetHighlight = true,
            classColorBorder = true,
            showPlayerName = false,
        },
        nameplatesEnemy = {
            arenaNumbersEnabled = true,
            arenaSpecIconHealer = true,
            arenaSpecIconHealerIcon = true,
            arenaSpecIconOthers = false,
            arenaSpecIconScale = 100,
            arenaSpecIconAlignment = addon.SPEC_ICON_ALIGNMENT.TOP,
            arenaSpecIconVerticalOffset = 0,
            filterEnabled = true,
            showCritterIcons = true,
            auraFilterEnabled = false,
            showBuffsOnEnemy = false,
            npcHighlightScale = 1,
            npcHighlightOffset = 0,
            hideHunterSecondaryPet = true,
            filterList = {},
            debuffWhiteList = {},
            buffWhiteList = {},
        },
        arenaFrames = {
            arenaCooldownTrackerEnabled = true,
            arenaCooldownSecondaryBar = false,

            arenaCooldownGrowDirection = addon.ARENA_COOLDOWN_GROW_DIRECTION.RIGHT,
            arenaCooldownOffsetX = 0,
            arenaCooldownOffsetY = 0,

            arenaCooldownGrowDirectionSecondary = addon.ARENA_COOLDOWN_GROW_DIRECTION.RIGHT,
            arenaCooldownOffsetXSecondary = 0,
            arenaCooldownOffsetYSecondary = -35,

            arenaCooldownTrackerIconSize = 32,
            arenaCooldownTrackerIconSizeSecondary = 32,
            arenaCooldownTrackerIconPadding = 2,
            arenaCooldownTrackerIconPaddingSecondary = 2,
            arenaCooldownTrackerGlow = true,
            arenaCooldownTrackerGlowSecondary = true,
            unusedIconAlpha = 0.5,
            usedIconAlpha = 1,
            showUnusedIcons = false,
            hideCountDownNumbers = false,
            spellList = {},
            spellList2 = {},

            spellCatPriority = {
                [tostring(addon.SPELLCATEGORY.IMMUNITY)] = 100,
                [tostring(addon.SPELLCATEGORY.DEFENSIVE)] = 90,
                [tostring(addon.SPELLCATEGORY.DISPEL)] = 50,
                [tostring(addon.SPELLCATEGORY.MASS_DISPEL)] = 55,
                [tostring(addon.SPELLCATEGORY.INTERRUPT)] = 50,
                [tostring(addon.SPELLCATEGORY.STUN)] = 90,
                [tostring(addon.SPELLCATEGORY.SILENCE)] = 80,
                [tostring(addon.SPELLCATEGORY.KNOCKBACK)] = 30,
                [tostring(addon.SPELLCATEGORY.CROWDCONTROL)] = 70,
                [tostring(addon.SPELLCATEGORY.BURST)] = 90,
                [tostring(addon.SPELLCATEGORY.HEAL)] = 80,
                [tostring(addon.SPELLCATEGORY.OTHERS)] = 10,
            },
        },
        raidFrames = {
            arenaRaidFrameSortOrder = addon.RAID_FRAME_SORT_ORDER.DISABLED,
            raidFrameAggroHighlightEnabled = true,
            raidFrameAggroHighlightThickness = 2,
            raidFrameAggroHighlightAlpha = 0.5,
            raidFrameAggroHighlightAnimationSpeed = 0,
            druidHoTHelper = true,
        },
        misc = {
            healerInCrowdControl = false,
            healerInCrowdControlSize = 48,
            healerInCrowdControlOffsetX = 0,
            healerInCrowdControlOffsetY = 250,
            queueReminder = true,
            combatIndicator = true,
            alwaysShowDruidComboPoints = true,
            fixEvokerCastBars = true,
            hideBlizzArenaFrames = true,
            arenaSurrenderEnabled = true,
            healerIndicator = true,
            showDampenPercentage = true,

            rangeCheckerSize = 32,
            rangeCheckerOffsetX = 0,
            rangeCheckerOffsetY = 0,

            rangeCheckerSpells = {
                [addon.DEATHKNIGHT] = 49576, -- Death Grip
                [addon.DEMONHUNTER] = 217832, -- Imprison
                [addon.DRUID] = 33786, -- Cyclone
                [addon.EVOKER] = 360806, -- Sleep Walk
                [addon.HUNTER] = 213691, -- Scatter Shot
                [addon.MAGE] = 118, -- Polymorph
                [addon.MONK] = 115078, -- Paralysis
                [addon.PALADIN] = 20066, -- Repentance
                [addon.PRIEST] = 605, -- Mind Control
                [addon.ROGUE] = 36554, -- Shadowstep
                [addon.SHAMAN] = 51514, -- Hex
                [addon.WARLOCK] = 5782, -- Fear
                [addon.WARRIOR] = 107570, -- Storm Bolt
            },
        },
        minimap = {
            hide = false,
        },
    }
};

if addon.internal then -- Set default for internal version
    defaults.profile.nameplatesFriendly.classIconStyle = addon.CLASS_ICON_STYLE.ICON_AND_ARROW;
    defaults.profile.nameplatesFriendly.classIconSize = 1.25;
    defaults.profile.nameplatesFriendly.petIconSize = 1;
    defaults.profile.nameplatesFriendly.showCrowdControl = true;
    defaults.profile.nameplatesEnemy.auraFilterEnabled = true;
    defaults.profile.nameplatesEnemy.showBuffsOnEnemy = true;
    defaults.profile.raidFrames.arenaRaidFrameSortOrder = addon.RAID_FRAME_SORT_ORDER.PLAYER_MID;
    defaults.profile.raidFrames.raidFrameAggroHighlightAnimationSpeed = 5;
    defaults.profile.arenaFrames.arenaCooldownSecondaryBar = true;
    defaults.profile.arenaFrames.arenaCooldownTrackerIconSize = 28;
    defaults.profile.arenaFrames.arenaCooldownTrackerIconSizeSecondary = 28;
    defaults.profile.arenaFrames.arenaCooldownOffsetX = 35;
    defaults.profile.arenaFrames.arenaCooldownOffsetY = 15;
    defaults.profile.arenaFrames.arenaCooldownOffsetXSecondary = 35;
    defaults.profile.arenaFrames.arenaCooldownOffsetYSecondary = -25;
    defaults.profile.arenaFrames.showUnusedIcons = true;
    defaults.profile.arenaFrames.unusedIconAlpha = 1;
    defaults.profile.arenaFrames.usedIconAlpha = 0.5;
    defaults.profile.arenaFrames.interruptBarEnabled = true;
    defaults.profile.arenaFrames.interruptBarShowUnused = true;
    defaults.profile.arenaFrames.interruptBarUnusedIconAlpha = 1;
    defaults.profile.arenaFrames.interruptBarUsedIconAlpha = 0.5;
    defaults.profile.misc.skipLeaveArenaConfirmation = true;
    defaults.profile.misc.healerInCrowdControl = true;
end

local function FillDefaults()
    addon.FillDefaultToNpcOptions(defaults.profile.nameplatesEnemy.filterList);
    addon.FillDefaultToAuraOptions(defaults.profile.nameplatesEnemy.debuffWhiteList, addon.DebuffList);
    addon.FillDefaultToAuraOptions(defaults.profile.nameplatesEnemy.buffWhiteList, addon.BuffList);

    if addon.PROJECT_MAINLINE then
        defaults.profile.arenaFrames.standaloneBars = {};
        for i = 1, 6 do
            local groupName = "Bar ".. i;
            defaults.profile.arenaFrames.standaloneBars[groupName] = {
                name = groupName,
                enabled = false,

                growDirection = addon.STANDALONE_GROW_DIRECTION.CENTER,
                columns = 8,
                growUpward = true,
                offsetX = 0,
                offsetY = 0,

                iconSize = 32,
                iconPadding = 2,
                unusedIconAlpha = 0.5,
                usedIconAlpha = 1,
                showUnusedIcons = false,
                hideCountDownNumbers = false,
                spellList = {},
            };
        end

        addon.SetupAllSpells(defaults.profile.arenaFrames.spellList, addon.SpellData);
        addon.SetupInterrupts(defaults.profile.arenaFrames.standaloneBars["Bar 1"].spellList, addon.SpellData);
    end
end

function SweepyBoop:SetupBlizzardOptions()
    local interfaceOptionPanel = CreateFrame("Frame", nil, UIParent);
    interfaceOptionPanel.name = addon.addonTitle;
    interfaceOptionPanel:Hide();

    interfaceOptionPanel:SetScript("OnShow", function(self)
        local title = self:CreateFontString(nil, "ARTWORK", "GameFontNormalLarge");
        title:SetPoint("TOPLEFT", 16, -16);
        title:SetText(addon.addonTitle);

        local context = self:CreateFontString(nil, "ARTWORK", "GameFontHighlightSmall");
        context:SetPoint("TOPLEFT", title, "BOTTOMLEFT", 0, -8);
        context:SetText("\124cFF00FF00Type /sb\124r or click the minimap icon to open the option panel.");

        local open = CreateFrame("Button", nil, self, "UIPanelButtonTemplate");
        open:SetText("Open Option Panel");
        open:SetWidth(177);
        open:SetHeight(24);
        open:SetPoint("TOPLEFT", context, "BOTTOMLEFT", 0, -30);
        open.tooltipText = "";
        open:SetScript("OnClick", function()
            LibStub("AceConfigDialog-3.0"):Open(addonName);
        end)

        self:SetScript("OnShow", nil);
    end)

    if Settings and Settings.RegisterCanvasLayoutCategory then
        local category = Settings.RegisterCanvasLayoutCategory(interfaceOptionPanel, addon.addonTitle);
        Settings.RegisterAddOnCategory(category);
    else
        InterfaceOptions_AddCategory(interfaceOptionPanel);
    end

    SLASH_SweepyBoop1 = "/sb";
    SlashCmdList.SweepyBoop = function(msg)
        -- This opens the in-game options panel that is not moveable or resizable
        -- if Settings and Settings.OpenToCategory then
        --     Settings.OpenToCategory(SweepyBoop.categoryID);
        -- end
        LibStub("AceConfigDialog-3.0"):Open(addonName);
    end
end

function SweepyBoop:OnInitialize()
    FillDefaults();
    local currentTime = GetTime();
    for _, category in pairs(defaults) do
        if type(category) == "table" then
            category.lastModified = currentTime;
        end
    end
    self.db = LibStub("AceDB-3.0"):New("SweepyBoopDB", defaults, true);

    options.args.nameplatesFriendly = addon.GetFriendlyNameplateOptions(3);
    options.args.nameplatesEnemy = addon.GetEnemyNameplateOptions(4);

    if addon.PROJECT_MAINLINE then
        options.args.arenaFrames = addon.GetArenaFrameOptions(5);
        options.args.raidFrames = addon.GetRaidFrameOptions(6);
        options.args.misc = addon.GetMiscOptions(7, icon, SweepyBoopLDB);
    end

    addon.importDialogs = addon.importDialogs or {};
    addon.importDialogs[""] = addon.CreateImportDialog("");
    addon.exportDialog = addon.exportDialog or addon.CreateExportDialog(); -- One shared dialog for exporting
    options.args.profileSharing = {
        order = 9,
        type = "group",
        name = "Profile sharing",
        args = {
            import = {
                order = 1,
                type = "execute",
                name = "Import Profile",
                desc = "Import a profile from another user.",
                func = function()
                    SweepyBoop:ShowImport("");
                end,
            },
            export = {
                order = 2,
                type = "execute",
                name = "Export Profile",
                desc = "Export your profile to share with others.",
                func = function()
                    SweepyBoop:ShowExport();
                end,
            },
        },
    };

    options.args.profiles = LibStub("AceDBOptions-3.0"):GetOptionsTable(self.db);
    LibStub("AceConfig-3.0"):RegisterOptionsTable(addonName, options);
    LibStub("AceConfigDialog-3.0"):SetDefaultSize(addonName, 760, 660);

    -- We don't add settings UI to game Options as it freezes after we modify settings then try to invoke options
    -- OmniBar has the same issue
    --self.optionsFrame, self.categoryID = LibStub("AceConfigDialog-3.0"):AddToBlizOptions(addonName, addon.addonTitle); -- Can we open to the friendly class icons page instead of the first empty page?

    self:SetupBlizzardOptions();

    icon:Register(addonName, SweepyBoopLDB, self.db.profile.minimap);

    -- Register callback (https://www.wowace.com/projects/ace3/pages/ace-db-3-0-tutorial)
    self.db.RegisterCallback(self, "OnProfileChanged", "RefreshConfig");
    self.db.RegisterCallback(self, "OnProfileReset", "RefreshConfig");

    -- Nameplate module needs optimization to eat less CPU
    -- Setup nameplate modules
    self:SetupNameplateModules();

    -- Only nameplate modules for Classic currently
    -- If only enabling nameplates, 7 ms / Sec CPU, otherwise 11 ms / Sec CPU
    if ( not addon.PROJECT_MAINLINE ) then return end

    self:SetupArenaCooldownTracker();

    self:SetupHealerIndicator();

    -- Setup raid frame modules
    self:SetupRaidFrameAggroHighlight();
    self:SetupRaidFrameAuraModule();


    self:SetupQueueReminder();
    self:SetupCombatIndicator();
    self:SetupHealerInCrowdControl();
    self:SetupArenaSurrender();
    self:SetupHideBlizzArenaFrames();
    self:SetupAlwaysShowDruidComboPoints();
    self:SetupRangeChecker();
    self:SetupFixBlizzardCastbars();
end

function SweepyBoop:RefreshConfig()
    if addon.PROJECT_MAINLINE then
        self:HideTestArenaCooldownTracker();
        self:HideTestArenaStandaloneBars();

        self:SetupCombatIndicator();
        self:HideTestHealerInCrowdControl();
    end

    local currentTime = GetTime();
    for _, category in pairs(self.db.profile) do
        if type(category) == "table" then
            category.lastModified = currentTime;
        end
    end

    self:RefreshAllNamePlates(true);

    if self.db.profile.minimap.hide then
        icon:Hide(addonName);
    else
        icon:Show(addonName);
    end
end
