-- [[ Namespaces ]] --
local addonName, addon = ...
local options = addon.Options
options.General = {}
local general = options.General
tinsert(options.OptionsTables, general)

local OrderPP = addon.InjectOptions.AutoOrderPlusPlus
local AdjustedWidth = addon.InjectOptions.AdjustedWidth

function general.RegisterOptionsTable()
    LibStub('AceConfig-3.0'):RegisterOptionsTable(addon.Metadata.Title, options.OptionsTable.args.General)
    LibStub('AceConfigDialog-3.0'):AddToBlizOptions(addon.Metadata.Title, addon.Metadata.Title, nil)
end

local RefreshOptions -- Assigned at the end of the file
function general.OnProfileChanged(db, newProfile)
    RefreshOptions()
end

function general.OnProfileCopied(db, sourceProfile)
    RefreshOptions()
end

function general.OnProfileReset(db)
    RefreshOptions()
end

local function MinimapShowMinimapIconSet(_, value)
    if addon.Options.db.profile.ShowMinimapIcon == value then return end
    addon.Options.db.profile.ShowMinimapIcon = value
    if addon.Options.db.profile.ShowMinimapIcon then
        addon.Icon:Show(addonName .. 'LDB')
    else
        addon.Icon:Hide(addonName .. 'LDB')
    end
end

local function OptionsButtonShowOptionsButtonSet(_, value)
    if addon.Options.db.profile.ShowOptionsButton == value then return end
    addon.Options.db.profile.ShowOptionsButton = value
    KrowiEVU_OptionsButton:ShowHide()
end

local function OptionsButtonOpenOptionsFunc()
    KrowiEVU_OptionsButton:ShowPopup()
end

local info = {
    order = OrderPP(), type = 'group',
    name = addon.Util.L['Info'],
    args = {
        General = {
            order = OrderPP(), type = 'group', inline = true,
            name = addon.Util.L['General'],
            args = {
                Version = {
                    order = OrderPP(), type = 'description', width = AdjustedWidth(), fontSize = 'medium',
                    name = (addon.Util.L['Version'] .. ': '):SetColorYellow() .. addon.Metadata.Version,
                },
                Build = {
                    order = OrderPP(), type = 'description', width = AdjustedWidth(), fontSize = 'medium',
                    name = (addon.Util.L['Build'] .. ': '):SetColorYellow() .. addon.Metadata.Build,
                },
                Blank1 = {order = OrderPP(), type = 'description', width = AdjustedWidth(), name = ''},
                Author = {
                    order = OrderPP(), type = 'description', width = AdjustedWidth(2), fontSize = 'medium',
                    name = (addon.Util.L['Author'] .. ': '):SetColorYellow() .. addon.Metadata.Author,
                },
                Discord = {
                    order = OrderPP(), type = 'execute', width = AdjustedWidth(),
                    name = addon.Util.L['Discord'],
                    desc = addon.Util.L['Discord Desc']:K_ReplaceVars(addon.Util.Constants.DiscordServerName),
                    func = function() LibStub('Krowi_PopupDialog_2').ShowExternalLink(addon.Util.Constants.DiscordInviteLink) end
                }
            }
        },
        Sources = {
            order = OrderPP(), type = 'group', inline = true,
            name = addon.Util.L['Sources'],
            args = {
                CurseForge = {
                    order = OrderPP(), type = 'execute', width = AdjustedWidth(),
                    name = addon.Util.L['CurseForge'],
                    desc = addon.Util.L['CurseForge Desc']:KEVU_InjectAddonName():K_ReplaceVars(addon.Util.L['CurseForge']),
                    func = function() LibStub('Krowi_PopupDialog_2').ShowExternalLink(addon.Metadata.CurseForge) end
                },
                Wago = {
                    order = OrderPP(), type = 'execute', width = AdjustedWidth(),
                    name = addon.Util.L['Wago'],
                    desc = addon.Util.L['Wago Desc']:KEVU_InjectAddonName():K_ReplaceVars(addon.Util.L['Wago']),
                    func = function() LibStub('Krowi_PopupDialog_2').ShowExternalLink(addon.Metadata.Wago) end
                },
            }
        }
    }
}

local icon = {
    order = OrderPP(), type = 'group',
    name = addon.Util.L['Icon'],
    args = {
        Minimap = {
            order = OrderPP(), type = 'group', inline = true,
            name = addon.Util.L['Minimap'],
            args = {
                ShowMinimapIcon = {
                    order = OrderPP(), type = 'toggle', width = AdjustedWidth(),
                    name = addon.Util.L['Show minimap icon'],
                    desc = addon.Util.L['Show minimap icon Desc']:KEVU_AddDefaultValueText('ShowMinimapIcon'),
                    get = function() return addon.Options.db.profile.ShowMinimapIcon end,
                    set = MinimapShowMinimapIconSet
                }
            }
        }
    }
}

local optionsButton = {
    order = OrderPP(), type = 'group',
    name = addon.Util.L['Options'],
    args = {
        OptionsButton = {
            order = OrderPP(), type = 'group', inline = true,
            name = addon.L['Options button'],
            args = {
                ShowOptionsButton = {
                    order = OrderPP(), type = 'toggle', width = AdjustedWidth(),
                    name = addon.L['Show options button'],
                    desc = addon.L['Show options button Desc']:KEVU_AddDefaultValueText('ShowOptionsButton'),
                    get = function() return addon.Options.db.profile.ShowOptionsButton end,
                    set = OptionsButtonShowOptionsButtonSet
                },
                Blank1 = {order = OrderPP(), type = 'description', width = AdjustedWidth(), name = ''},
                OpenOptions = {
                    order = OrderPP(), type = 'execute', width = AdjustedWidth(),
                    name = addon.Util.L['Options'],
                    desc = addon.L['Options Desc'],
                    func = OptionsButtonOpenOptionsFunc
                },
                ShowHideOption = {
                    order = OrderPP(), type = 'toggle', width = AdjustedWidth(),
                    name = addon.L['Show Hide option']:K_ReplaceVars(addon.Util.L['Hide']),
                    desc = addon.L['Show Hide option Desc']:K_ReplaceVars{
                        hide = addon.Util.L['Hide'],
                        optionsButton = addon.L['Options button']
                    }:KEVU_AddDefaultValueText('ShowHideOption'),
                    get = function() return addon.Options.db.profile.ShowHideOption end,
                    set = function(_, value) addon.Options.db.profile.ShowHideOption = value end
                }
            }
        }
    }
}

options.OptionsTable.args['General'] = {
    type = 'group', childGroups = 'tab',
    name = addon.Util.L['General'],
    args = {
        Info = info,
        Icon = icon,
        Options = optionsButton
    }
}

function RefreshOptions()
    local profile = addon.Options.db.profile
    MinimapShowMinimapIconSet(nil, profile.ShowMinimapIcon)
    OptionsButtonShowOptionsButtonSet(nil, profile.ShowOptionsButton)
end