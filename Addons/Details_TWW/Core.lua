local TWW = LibStub('AceAddon-3.0'):NewAddon('Details_TWW', 'AceConsole-3.0')
local LocDetails = _G.LibStub("AceLocale-3.0"):GetLocale("Details")
local LSM = LibStub('LibSharedMedia-3.0')

local skinName = '|cff8080ffThe War Within|r'

local name, realm = UnitName('player')
local debugMode = (name == 'Zimtdev') or (name == 'Zimtdevtwo') or (name == 'Botlike')

local retail = WOW_PROJECT_ID == WOW_PROJECT_MAINLINE

local version = C_AddOns.GetAddOnMetadata('Details_TWW', 'Version')

function TWW:OnInitialize()
    -- Called when the addon is loaded
    TWW:Debug('TWW:OnInitialize()')
end

function TWW:OnEnable()
    -- Called when the addon is enabled
    TWW:Debug('TWW:OnEnable()')
    TWW:RegisterSlashCommand()
end

function TWW:OnDisable()
    -- Called when the addon is disabled
end

function TWW:Debug(str, ...)
    if not debugMode then return end
    self:Print(str, ...)
end

function TWW:OnEvent(event, arg1, ...)
    TWW:Debug(event, arg1, ...)
    if event == 'PLAYER_LOGIN' then
        --
        TWW:SetupAfterLogin()
    end
end

function TWW:SetupAfterLogin()
    if Details.IsLoaded and not Details.IsLoaded() then
        C_Timer.After(0, function()
            TWW:SetupAfterLogin()
        end)
        return
    end

    TWW:RegisterSkin()
    TWW:FixTitleBar()
    if retail then TWW:ChangeAugmentationBar() end
end

local frame = CreateFrame('FRAME')
frame:SetScript("OnEvent", TWW.OnEvent)
frame:RegisterEvent("PLAYER_LOGIN")
frame:RegisterEvent("PLAYER_ENTERING_WORLD")

function TWW:RegisterTextures()
    TWW:Debug('TWW:RegisterTextures()')

    LSM:Register('statusbar', 'TheWarWithinHeader', [[Interface\AddOns\Details_TWW\Textures\header.tga]])
    LSM:Register('statusbar', 'TheWarWithinBar', [[Interface\AddOns\Details_TWW\Textures\bar.tga]])
    LSM:Register('statusbar', 'TheWarWithinBackground', [[Interface\AddOns\Details_TWW\Textures\background.tga]])
end
TWW:RegisterTextures()

local skinTable = {
    file = [[Interface\AddOns\Details\images\skins\flat_skin.blp]],
    author = "Karl-Heinz Schneider",
    version = version,
    site = "https://github.com/Karl-HeinzSchneider/WoW-Details-Skin-TheWarWithin",
    desc = "The War Within Skin.\n\n ...",
    no_cache = true,

    -- micro frames
    micro_frames = {color = {1, 1, 1, 1}, font = "Accidental Presidency", size = 10, textymod = 1},

    can_change_alpha_head = true,
    icon_anchor_main = {-1, -5},
    icon_anchor_plugins = {-7, -13},
    icon_plugins_size = {19, 18},

    -- anchors:
    icon_point_anchor = {-37, 0},
    left_corner_anchor = {-107, 0},
    right_corner_anchor = {96, 0},

    icon_point_anchor_bottom = {-37, 12},
    left_corner_anchor_bottom = {-107, 0},
    right_corner_anchor_bottom = {96, 0},

    icon_on_top = true,
    icon_ignore_alpha = true,
    icon_titletext_position = {3, 3},

    instance_cprops = {
        -- titlebar
        titlebar_shown = true,
        titlebar_height = 32,
        titlebar_texture = "TheWarWithinHeader",
        titlebar_texture_color = {1.0, 1.0, 1.0, 1.0},
        --
        ["toolbar_icon_file"] = "Interface\\AddOns\\Details\\images\\toolbar_icons_shadow",
        ["toolbar_side"] = 1,
        ["menu_anchor"] = {
            10, -- [1]
            10, -- [2]
            ["side"] = 2
        },
        --
        ["attribute_text"] = {
            ["enabled"] = true,
            ["shadow"] = false,
            ["side"] = 1,
            ["text_size"] = 13,
            ["custom_text"] = "{name}",
            ["text_face"] = "Friz Quadrata TT",
            ["anchor"] = {
                -4, -- [1]
                10 -- [2]
            },
            ["text_color"] = {
                NORMAL_FONT_COLOR.r, -- [1]
                NORMAL_FONT_COLOR.g, -- [2]
                NORMAL_FONT_COLOR.b, -- [3]
                NORMAL_FONT_COLOR.a -- [4]
            },
            ["enable_custom_text"] = false,
            ["show_timer"] = true
        },
        --
        ["row_info"] = {
            ["texture_highlight"] = "Interface\\FriendsFrame\\UI-FriendsList-Highlight",
            ["fixed_text_color"] = {
                1, -- [1]
                1, -- [2]
                1 -- [3]
            },
            ["height"] = 28, --
            ["space"] = {["right"] = 0, ["left"] = 0, ["between"] = 4}, --
            row_offsets = {left = 29, right = -29 - 8, top = 0, bottom = 0}, --
            ["texture_background_class_color"] = false,
            ["font_face_file"] = "Interface\\Addons\\Details\\fonts\\Accidental Presidency.ttf",
            ["backdrop"] = {
                ["enabled"] = false,
                ["size"] = 12,
                ["color"] = {
                    1, -- [1]
                    1, -- [2]
                    1, -- [3]
                    1 -- [4]
                },
                ["texture"] = "Details BarBorder 2"
            },
            ["icon_file"] = "Interface\\AddOns\\Details_TWW\\Textures\\ClassIconsTWW",
            start_after_icon = false, --
            icon_offset = {-30, 0}, --
            --
            ["textL_show_number"] = true, --
            ["textL_outline"] = false,
            ["textL_enable_custom_text"] = false, --
            ["textL_custom_text"] = "{data1}. {data3}{data2}", --
            ["textL_class_colors"] = false,
            --
            ["textR_outline"] = false, --
            ["textR_bracket"] = "(",
            ["textR_enable_custom_text"] = false,
            ["textR_custom_text"] = "{data1} ({data2}, {data3}%)",
            ["textR_class_colors"] = false,
            ["textR_show_data"] = {
                true, -- [1]
                true, -- [2]
                true -- [3]
            },
            --
            ["fixed_texture_color"] = {
                0, -- [1]
                0, -- [2]
                0 -- [3]
            },
            ["models"] = {
                ["upper_model"] = "Spells\\AcidBreath_SuperGreen.M2",
                ["lower_model"] = "World\\EXPANSION02\\DOODADS\\Coldarra\\COLDARRALOCUS.m2",
                ["upper_alpha"] = 0.5,
                ["lower_enabled"] = false,
                ["lower_alpha"] = 0.1,
                ["upper_enabled"] = false
            },
            ["texture_custom_file"] = "Interface\\",
            ["texture_custom"] = "",
            ["alpha"] = 1,
            ["no_icon"] = false,
            ["texture"] = "TheWarWithinBar",
            ["texture_file"] = "Interface\\AddOns\\Details_TWW\\Textures\\bar",
            ["texture_background"] = "TheWarWithinBackground", --
            ["texture_background_file"] = "Interface\\AddOns\\Details_TWW\\Textures\\background", --        

            ["fixed_texture_background_color"] = {1, 1, 1, 1}, --
            ["font_face"] = "Friz Quadrata TT", --
            ["font_size"] = 11, --
            ["textL_offset"] = 0, --
            ["text_yoffset"] = 7, --
            ["texture_class_colors"] = true,
            ["percent_type"] = 1,
            ["fast_ps_update"] = false,
            ["textR_separator"] = ",",
            ["use_spec_icons"] = true, --
            ["spec_file"] = "Interface\\AddOns\\Details_TWW\\Textures\\specs", --
            icon_size_offset = 1.2
        },
        --
        menu_icons_alpha = 1,
        ["show_statusbar"] = false,
        ["menu_icons_size"] = 1.07,
        ["color"] = {
            0.333333333333333, -- [1]
            0.333333333333333, -- [2]
            0.333333333333333, -- [3]
            0 -- [4]
        },
        ["bg_r"] = 0.0941176470588235,
        ["hide_out_of_combat"] = false,
        ["following"] = {
            ["bar_color"] = {
                1, -- [1]
                1, -- [2]
                1 -- [3]
            },
            ["enabled"] = false,
            ["text_color"] = {
                1, -- [1]
                1, -- [2]
                1 -- [3]
            }
        },
        ["color_buttons"] = {
            1, -- [1]
            1, -- [2]
            1, -- [3]
            1 -- [4]
        },
        ["skin_custom"] = "",
        ["menu_anchor_down"] = {
            16, -- [1]
            -3 -- [2]
        },
        ["micro_displays_locked"] = true,
        ["row_show_animation"] = {["anim"] = "Fade", ["options"] = {}},
        ["tooltip"] = {["n_abilities"] = 3, ["n_enemies"] = 3},
        ["total_bar"] = {
            ["enabled"] = false,
            ["only_in_group"] = true,
            ["icon"] = "Interface\\ICONS\\INV_Sigil_Thorim",
            ["color"] = {
                1, -- [1]
                1, -- [2]
                1 -- [3]
            }
        },
        ["show_sidebars"] = false,
        ["instance_button_anchor"] = {
            -27, -- [1]
            1 -- [2]
        },
        ["plugins_grow_direction"] = 1,
        ["menu_alpha"] = {
            ["enabled"] = false,
            ["onleave"] = 1,
            ["ignorebars"] = false,
            ["iconstoo"] = true,
            ["onenter"] = 1
        },
        ["micro_displays_side"] = 2,
        ["grab_on_top"] = false,
        ["strata"] = "LOW",
        ["bars_grow_direction"] = 1,
        ["bg_alpha"] = 0, --
        ["ignore_mass_showhide"] = false,
        ["hide_in_combat_alpha"] = 0,
        ["menu_icons"] = {
            true, -- [1]
            true, -- [2]
            true, -- [3]
            true, -- [4]
            true, -- [5]
            false, -- [6]
            ["space"] = 0,
            ["shadow"] = false
        },
        ["auto_hide_menu"] = {["left"] = false, ["right"] = false},
        ["statusbar_info"] = {
            ["alpha"] = 0,
            ["overlay"] = {
                0.333333333333333, -- [1]
                0.333333333333333, -- [2]
                0.333333333333333 -- [3]
            }
        },
        ["window_scale"] = 1,
        ["libwindow"] = {["y"] = 90.9987335205078, ["x"] = -80.0020751953125, ["point"] = "BOTTOMRIGHT"},
        ["backdrop_texture"] = "Details Ground",
        ["hide_icon"] = true,
        ["bg_b"] = 0.0941176470588235,
        ["bg_g"] = 0.0941176470588235,
        ["desaturated_menu"] = false,
        ["wallpaper"] = {
            ["enabled"] = false,
            ["texcoord"] = {
                0, -- [1]
                1, -- [2]
                0, -- [3]
                0.7 -- [4]
            },
            ["overlay"] = {
                1, -- [1]
                1, -- [2]
                1, -- [3]
                1 -- [4]
            },
            ["anchor"] = "all",
            ["height"] = 114.042518615723,
            ["alpha"] = 0.5,
            ["width"] = 283.000183105469
        },
        ["stretch_button_side"] = 1,
        ["bars_sort_direction"] = 1
    }
}

function TWW:RegisterSkin()
    TWW:Debug('TWW:RegisterSkin()')

    -- hooksecurefunc(Details, 'ChangeSkin', function(self, skin)
    --     --
    --     TWW:Debug('ChangeSkin', skin)
    --     TWW:Debug('self.skin', Details.skin)
    -- end)

    Details:InstallSkin(skinName, skinTable)
end

function TWW:FixTitleBar()
    --
    TWW:Debug('TWW:FixTitleBar()', Details.skin)

    for instanceId = 1, Details:GetNumInstances() do
        --      
        local instance = Details:GetInstance(instanceId)
        if (instance and instance.baseframe and instance.ativa) then instance:ChangeSkin() end
    end
end

function TWW:ChangeAugmentationBar()
    TWW:Debug('TWW:ChangeAugmentationBar()')

    local evokerColor = Details.class_colors["EVOKER"]

    for instanceId = 1, Details:GetNumInstances() do
        --      
        -- TWW:Debug('instance', instanceId)
        local instance = Details:GetInstance(instanceId)
        if (instance and instance.baseframe and instance.ativa) then

            for lineIndex, line in ipairs(instance:GetAllLines()) do
                -- TWW:Debug('line', lineIndex, line)
                local extraStatusbar = line.extraStatusbar
                extraStatusbar:SetStatusBarTexture([[Interface\AddOns\Details_TWW\Textures\augment]])
                extraStatusbar:GetStatusBarTexture():SetVertexColor(unpack(evokerColor))
                extraStatusbar.texture:SetVertexColor(unpack(evokerColor))
            end
        end
    end

    local gump = Details.gump

    hooksecurefunc(gump, 'CreateNewLine', function(self, instance, index)
        --
        -- TWW:Debug('CreateNewLine', instance, index)

        local newLine = _G['DetailsBarra_' .. instance.meu_id .. '_' .. index]

        local extraStatusbar = newLine.extraStatusbar
        extraStatusbar:SetStatusBarTexture([[Interface\AddOns\Details_TWW\Textures\augment]])
        extraStatusbar:GetStatusBarTexture():SetVertexColor(unpack(evokerColor))
        extraStatusbar.texture:SetVertexColor(unpack(evokerColor))
    end)
end

function TWW:RegisterSlashCommand()
    -- Module:RegisterChatCommand('df', 'SlashCommand')
    TWW:RegisterChatCommand('tww', 'SlashCommand')
end

function TWW:SlashCommand(msg)
    TWW:Debug('TWW:SlashCommand()', msg)

    if msg == 'import' then
        TWW:ShowImportProfile()
    else
        TWW:Print([[Slashcommand not found. Did you mean '/tww import'?]])
    end
end

function TWW:ShowImportProfile()
    TWW:Debug('TWW:ShowImportProfile()')
    TWW:Print('Import default profile...')

    local askForNewProfileName = function(newProfileName, importAutoRunCode)
        Details:ImportProfile(TWW.DefaultProfileImport, newProfileName, importAutoRunCode, true)
    end
    Details.ShowImportProfileConfirmation(LocDetails["STRING_OPTIONS_IMPORT_PROFILE_NAME"] ..
                                              " [Skin: |cff8080ffDetails_TWW|r]" .. ":", askForNewProfileName)
end

