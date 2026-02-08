local LSM = LibStub("LibSharedMedia-3.0")
local isRetail = sArenaMixin.isRetail
local isMidnight = sArenaMixin.isMidnight
local L = sArenaMixin.L

local midnightInfo
if not isMidnight then
    midnightInfo = L["Midnight_UpdateInfo"]
else
    midnightInfo = L["Midnight_BetaInfo"]
end

local function GetSpellInfoCompat(spellID)
    if not spellID then
        return nil
    end

    if GetSpellInfo then
        return GetSpellInfo(spellID)
    end

    if C_Spell and C_Spell.GetSpellInfo then
        local spellInfo = C_Spell.GetSpellInfo(spellID)
        if spellInfo then
            return spellInfo.name, nil, spellInfo.iconID, spellInfo.castTime, spellInfo.minRange, spellInfo.maxRange, spellInfo.spellID, spellInfo.originalIconID
        end
    end

    return nil
end

local function GetSpellDescriptionCompat(spellID)
    if not spellID then
        return ""
    end

    if GetSpellDescription then
        return GetSpellDescription(spellID) or ""
    end

    if C_Spell and C_Spell.GetSpellDescription then
        return C_Spell.GetSpellDescription(spellID) or ""
    end

    return ""
end

local function getLayoutTable()
    local t = {}

    for k, _ in pairs(sArenaMixin.layouts) do
        t[k] = sArenaMixin.layouts[k].name and sArenaMixin.layouts[k].name or k
    end

    return t
end

local function validateCombat()
    if (InCombatLockdown()) then
        return L["Message_MustLeaveCombat"]
    end

    return true
end

local growthValues = { L["Direction_Down"], L["Direction_Up"], L["Direction_Right"], L["Direction_Left"] }
local drIcons = sArenaMixin.defaultSettings.profile.drIcons or {}

local drCategoryDisplay = {}
for category, tex in pairs(drIcons) do
    drCategoryDisplay[category] = "|cFFFFFFFF|T" .. tostring(tex) .. ":16|t " .. (L["DR_" .. category] or category) .. "|r"
end

local racialCategories = {}
for raceKey, data in pairs(sArenaMixin.racialData or {}) do
    local name = L["Race_" .. raceKey] or raceKey
    local texture = data and data.texture
    if texture then
        if type(texture) == "string" then
            racialCategories[raceKey] = "|T" .. texture .. ":16|t " .. name
        else
            racialCategories[raceKey] = "|T" .. tostring(texture) .. ":16|t " .. name
        end
    else
        racialCategories[raceKey] = name
    end
end

local function StatusbarValues()
    local t, keys = {}, {}
    for k in pairs(LSM:HashTable(LSM.MediaType.STATUSBAR)) do keys[#keys+1] = k end
    table.sort(keys)
    for _, k in ipairs(keys) do t[k] = k end
    return t
end

function sArenaMixin:GetLayoutOptionsTable(layoutName)
        local function LDB(info)
        return info.handler.db.profile.layoutSettings[layoutName]
    end
    local function getSetting(info)
        return LDB(info)[info[#info]]
    end
    local function getFontOutlineSetting(info)
        local value = LDB(info)[info[#info]]
        if value == nil then
            return "OUTLINE"
        end
        return value
    end
    local function setSetting(info, val)
        local db = LDB(info)
        db[info[#info]] = val

        if self.RefreshConfig then self:RefreshConfig() end
    end

    local optionsTable = {
        arenaFrames = {
            order = 1,
            name = L["Category_ArenaFrames"],
            type = "group",
            get = function(info) return info.handler.db.profile.layoutSettings[layoutName][info[#info]] end,
            set = function(info, val)
                self:UpdateFrameSettings(info.handler.db.profile.layoutSettings[layoutName], info,
                    val)
            end,
            args = {
                textures = {
                    order  = 0.1,
                    name   = L["Textures"],
                    type   = "group",
                    inline = true,
                    args   = {
                        generalTexture = {
                            order         = 1,
                            type          = "select",
                            name          = "|A:UI-LFG-RoleIcon-DPS-Micro:20:20|a " .. L["Texture_General"],
                            desc          = L["Texture_General_Desc"],
                            style         = "dropdown",
                            dialogControl = "LSM30_Statusbar",
                            values        = StatusbarValues,
                            get           = function(info)
                                local layout = info.handler.db.profile.layoutSettings[layoutName]
                                local t = layout.textures
                                return (t and t.generalStatusBarTexture) or "sArena Default"
                            end,
                            set           = function(info, key)
                                local layout = info.handler.db.profile.layoutSettings[layoutName]
                                layout.textures = layout.textures or {
                                    generalStatusBarTexture = "sArena Default",
                                    healStatusBarTexture    = "sArena Default",
                                    castbarStatusBarTexture = "sArena Default",
                                    castbarUninterruptibleTexture = "sArena Default",
                                }
                                layout.textures.generalStatusBarTexture = key
                                info.handler:UpdateTextures()
                            end,
                        },
                        healerTexture = {
                            order         = 2,
                            type          = "select",
                            name          = "|A:UI-LFG-RoleIcon-Healer-Micro:20:20|a " .. L["Texture_Healer"],
                            desc          = L["Texture_Healer_Desc"],
                            style         = "dropdown",
                            dialogControl = "LSM30_Statusbar",
                            values        = StatusbarValues,
                            get           = function(info)
                                local layout = info.handler.db.profile.layoutSettings[layoutName]
                                local t = layout.textures
                                return (t and t.healStatusBarTexture) or "sArena Default"
                            end,
                            set           = function(info, key)
                                local layout = info.handler.db.profile.layoutSettings[layoutName]
                                layout.textures = layout.textures or {
                                    generalStatusBarTexture = "sArena Default",
                                    healStatusBarTexture    = "sArena Default",
                                    castbarStatusBarTexture = "sArena Default",
                                    castbarUninterruptibleTexture = "sArena Default",
                                }
                                layout.textures.healStatusBarTexture = key
                                info.handler:UpdateTextures()
                            end,
                        },
                        healerClassStackOnly = {
                            order = 3,
                            type  = "toggle",
                            name  = L["Texture_ClassStackingOnly"],
                            desc  = L["Texture_ClassStackingOnly_Desc"],
                            get   = function(info)
                                local layout = info.handler.db.profile.layoutSettings[layoutName]
                                return layout.retextureHealerClassStackOnly or false
                            end,
                            set   = function(info, val)
                                local layout = info.handler.db.profile.layoutSettings[layoutName]
                                layout.retextureHealerClassStackOnly = val
                                info.handler:UpdateTextures()
                            end,
                            width = "75%",
                        },
                        bgTexture = {
                            order         = 4,
                            type          = "select",
                            name          = L["Texture_Background"],
                            desc          = L["Texture_Background_Desc"],
                            style         = "dropdown",
                            dialogControl = "LSM30_Statusbar",
                            values        = StatusbarValues,
                            get           = function(info)
                                local layout = info.handler.db.profile.layoutSettings[layoutName]
                                local t = layout.textures
                                return (t and t.bgTexture) or "Solid"
                            end,
                            set           = function(info, key)
                                local layout = info.handler.db.profile.layoutSettings[layoutName]
                                layout.textures = layout.textures or {
                                    generalStatusBarTexture = "sArena Default",
                                    healStatusBarTexture    = "sArena Default",
                                    castbarStatusBarTexture = "sArena Default",
                                    castbarUninterruptibleTexture = "sArena Default",
                                    bgTexture = "Solid",
                                }
                                layout.textures.bgTexture = key
                                info.handler:UpdateTextures()
                            end,
                            width = "75%",
                        },
                        bgColor = {
                            order = 5,
                            type  = "color",
                            name  = L["Texture_BackgroundColor"],
                            desc  = L["Texture_BackgroundColor_Desc"],
                            hasAlpha = true,
                            get   = function(info)
                                local layout = info.handler.db.profile.layoutSettings[layoutName]
                                local c = layout.textures and layout.textures.bgColor or {0, 0, 0, 0.6}
                                return c[1], c[2], c[3], c[4]
                            end,
                            set   = function(info, r, g, b, a)
                                local layout = info.handler.db.profile.layoutSettings[layoutName]
                                layout.textures = layout.textures or {
                                    generalStatusBarTexture = "sArena Default",
                                    healStatusBarTexture    = "sArena Default",
                                    castbarStatusBarTexture = "sArena Default",
                                    castbarUninterruptibleTexture = "sArena Default",
                                    bgTexture = "Solid",
                                    bgColor = {0, 0, 0, 0.6},
                                }
                                layout.textures.bgColor = {r, g, b, a}
                                info.handler:UpdateTextures()
                            end,
                            width = 1.5,
                        },
                    },
                },
                other = {
                    order  = 0.5,
                    name   = L["Options"],
                    type   = "group",
                    inline = true,
                    args   = {
                        replaceClassIcon = {
                            order = 2,
                            type  = "toggle",
                            name  = L["Option_ReplaceClassIcon"],
                            desc  = L["Option_ReplaceClassIcon_Desc"],
                            get   = getSetting,
                            set   = setSetting,
                        },
                        showSpecManaText = {
                            order = 3,
                            type  = "toggle",
                            name  = L["Option_SpecTextOnManabar"],
                            get   = getSetting,
                            set   = setSetting,
                        },
                    },
                },
                positioning = {
                    order = 1,
                    name = L["Positioning"],
                    type = "group",
                    inline = true,
                    args = {
                        posX = {
                            order = 1,
                            name = L["Horizontal"],
                            type = "range",
                            min = -1000,
                            max = 1000,
                            step = 0.1,
                            bigStep = 1,
                        },
                        posY = {
                            order = 2,
                            name = L["Vertical"],
                            type = "range",
                            min = -1000,
                            max = 1000,
                            step = 0.1,
                            bigStep = 1,
                        },
                        spacing = {
                            order = 3,
                            name = L["Spacing"],
                            desc = L["Option_SpacingBetweenFrames_Desc"],
                            type = "range",
                            min = 0,
                            max = 100,
                            step = 1,
                        },
                        growthDirection = {
                            order = 4,
                            name = L["Option_GrowthDirection"],
                            type = "select",
                            style = "dropdown",
                            values = growthValues,
                        },
                    },
                },
                sizing = {
                    order = 0.3,
                    name = L["Sizing"],
                    type = "group",
                    inline = true,
                    args = {
                        scale = {
                            order = 1,
                            name = L["Scale"],
                            type = "range",
                            min = 0.1,
                            max = 5.0,
                            softMin = 0.5,
                            softMax = 3.0,
                            step = 0.01,
                            bigStep = 0.1,
                            isPercent = true,
                        },
                        classIconFontSize = {
                            order = 2,
                            name = L["Option_ClassIconCDFontSize"],
                            desc = L["Option_FontSize_Desc"],
                            type = "range",
                            min = 2,
                            max = 48,
                            softMin = 4,
                            softMax = 32,
                            step = 1,
                        },
                    },
                },
            },
        },
        specIcon = {
            order = 2,
            name = L["Category_SpecIcons"],
            type = "group",
            get = function(info) return info.handler.db.profile.layoutSettings[layoutName].specIcon[info[#info]] end,
            set = function(info, val)
                self:UpdateSpecIconSettings(
                    info.handler.db.profile.layoutSettings[layoutName].specIcon, info, val)
            end,
            args = {
                positioning = {
                    order = 1,
                    name = L["Positioning"],
                    type = "group",
                    inline = true,
                    args = {
                        posX = {
                            order = 1,
                            name = L["Horizontal"],
                            type = "range",
                            min = -700,
                            max = 700,
                            softMin = -350,
                            softMax = 350,
                            step = 0.1,
                            bigStep = 1,
                        },
                        posY = {
                            order = 2,
                            name = L["Vertical"],
                            type = "range",
                            min = -700,
                            max = 700,
                            softMin = -350,
                            softMax = 350,
                            step = 0.1,
                            bigStep = 1,
                        },
                    },
                },
                sizing = {
                    order = 2,
                    name = L["Sizing"],
                    type = "group",
                    inline = true,
                    args = {
                        scale = {
                            order = 1,
                            name = L["Scale"],
                            type = "range",
                            min = 0.1,
                            max = 5.0,
                            softMin = 0.5,
                            softMax = 3.0,
                            step = 0.01,
                            bigStep = 0.1,
                            isPercent = true,
                        },
                    },
                },
            },
        },
        trinket = {
            order = 3,
            name = L["Category_Trinkets"],
            type = "group",
            get = function(info) return info.handler.db.profile.layoutSettings[layoutName].trinket[info[#info]] end,
            set = function(info, val)
                self:UpdateTrinketSettings(
                    info.handler.db.profile.layoutSettings[layoutName].trinket, info, val)
            end,
            args = {
                positioning = {
                    order = 1,
                    name = L["Positioning"],
                    type = "group",
                    inline = true,
                    args = {
                        posX = {
                            order = 1,
                            name = L["Horizontal"],
                            type = "range",
                            min = -700,
                            max = 700,
                            softMin = -350,
                            softMax = 350,
                            step = 0.1,
                            bigStep = 1,
                        },
                        posY = {
                            order = 2,
                            name = L["Vertical"],
                            type = "range",
                            min = -700,
                            max = 700,
                            softMin = -350,
                            softMax = 350,
                            step = 0.1,
                            bigStep = 1,
                        },
                    },
                },
                sizing = {
                    order = 2,
                    name = L["Sizing"],
                    type = "group",
                    inline = true,
                    args = {
                        scale = {
                            order = 1,
                            name = L["Scale"],
                            type = "range",
                            min = 0.1,
                            max = 5.0,
                            softMin = 0.5,
                            softMax = 3.0,
                            step = 0.001,
                            bigStep = 0.1,
                            isPercent = true,
                        },
                        fontSize = {
                            order = 3,
                            name = L["Option_FontSize"],
                            desc = L["Option_FontSize_Desc"],
                            type = "range",
                            min = 2,
                            max = 48,
                            softMin = 4,
                            softMax = 32,
                            step = 1,
                        },
                    },
                },
            },
        },
        racial = {
            order = 4,
            name = L["Category_Racials"],
            type = "group",
            get = function(info) return info.handler.db.profile.layoutSettings[layoutName].racial[info[#info]] end,
            set = function(info, val)
                self:UpdateRacialSettings(
                    info.handler.db.profile.layoutSettings[layoutName].racial, info, val)
            end,
            args = {
                positioning = {
                    order = 1,
                    name = L["Positioning"],
                    type = "group",
                    inline = true,
                    args = {
                        posX = {
                            order = 1,
                            name = L["Horizontal"],
                            type = "range",
                            min = -700,
                            max = 700,
                            softMin = -350,
                            softMax = 350,
                            step = 0.1,
                            bigStep = 1,
                        },
                        posY = {
                            order = 2,
                            name = L["Vertical"],
                            type = "range",
                            min = -700,
                            max = 700,
                            softMin = -350,
                            softMax = 350,
                            step = 0.1,
                            bigStep = 1,
                        },
                    },
                },
                sizing = {
                    order = 2,
                    name = L["Sizing"],
                    type = "group",
                    inline = true,
                    args = {
                        scale = {
                            order = 1,
                            name = L["Scale"],
                            type = "range",
                            min = 0.1,
                            max = 5.0,
                            softMin = 0.5,
                            softMax = 3.0,
                            step = 0.001,
                            bigStep = 0.1,
                            isPercent = true,
                        },
                        fontSize = {
                            order = 3,
                            name = L["Option_FontSize"],
                            desc = L["Option_FontSize_Desc"],
                            type = "range",
                            min = 2,
                            max = 48,
                            softMin = 4,
                            softMax = 32,
                            step = 1,
                        },
                    },
                },
            },
        },
        dispel = {
            order = 4.5,
            name = L["Category_Dispels"],
            type = "group",
            get = function(info) return info.handler.db.profile.layoutSettings[layoutName].dispel[info[#info]] end,
            set = function(info, val)
                self:UpdateDispelSettings(
                    info.handler.db.profile.layoutSettings[layoutName].dispel, info, val)
            end,
            args = {
                positioning = {
                    order = 1,
                    name = L["Positioning"],
                    type = "group",
                    inline = true,
                    args = {
                        posX = {
                            order = 1,
                            name = L["Horizontal"],
                            type = "range",
                            min = -700,
                            max = 700,
                            softMin = -350,
                            softMax = 350,
                            step = 0.1,
                            bigStep = 1,
                        },
                        posY = {
                            order = 2,
                            name = L["Vertical"],
                            type = "range",
                            min = -700,
                            max = 700,
                            softMin = -350,
                            softMax = 350,
                            step = 0.1,
                            bigStep = 1,
                        },
                    },
                },
                sizing = {
                    order = 2,
                    name = L["Sizing"],
                    type = "group",
                    inline = true,
                    args = {
                        scale = {
                            order = 1,
                            name = L["Scale"],
                            type = "range",
                            min = 0.1,
                            max = 5.0,
                            softMin = 0.5,
                            softMax = 3.0,
                            step = 0.001,
                            bigStep = 0.1,
                            isPercent = true,
                        },
                        fontSize = {
                            order = 3,
                            name = L["Option_FontSize"],
                            desc = L["Option_FontSize_Desc"],
                            type = "range",
                            min = 2,
                            max = 48,
                            softMin = 4,
                            softMax = 32,
                            step = 1,
                        },
                    },
                },
            },
        },
        castBar = {
            order = 5,
            name = L["Category_CastBars"],
            type = "group",
            get = function(info) return info.handler.db.profile.layoutSettings[layoutName].castBar[info[#info]] end,
            set = function(info, val)
                self:UpdateCastBarSettings(info.handler.db.profile.layoutSettings[layoutName].castBar, info, val)
                if sArenaMixin.RefreshMasque then
                    sArenaMixin:RefreshMasque()
                end
            end,
            args = {
                castBarLook = {
                    order  = 0,
                    name   = L["Castbar_Look"],
                    type   = "group",
                    inline = true,
                    args   = {
                        useModernCastbars = {
                            order = 1,
                            type  = "toggle",
                            name  = L["Castbar_UseModern"],
                            desc  = L["Castbar_UseModern_Desc"],
                            width = "75%",
                            set   = function(info, val)
                                local castDB = info.handler.db.profile.layoutSettings[layoutName].castBar
                                castDB.useModernCastbars = val
                                info.handler:UpdateTextures()
                                info.handler:RefreshTestModeCastbars()
                                info.handler:RefreshConfig()
                            end,
                        },

                        keepDefaultModernTextures = {
                            order    = 2,
                            type     = "toggle",
                            name     = L["Castbar_KeepDefaultModernTextures"],
                            width    = "90%",
                            desc     = L["Castbar_KeepDefaultModernTextures_Desc"],
                            disabled = function(info)
                                return not info.handler.db.profile.layoutSettings[layoutName].castBar.useModernCastbars
                            end,
                            set      = function(info, val)
                                local castDB = info.handler.db.profile.layoutSettings[layoutName].castBar
                                castDB.keepDefaultModernTextures = val
                                info.handler:UpdateTextures()
                                info.handler:RefreshTestModeCastbars()
                                info.handler:RefreshConfig()
                            end,
                        },

                        simpleCastbar = {
                            order    = 2.3,
                            type     = "toggle",
                            name     = L["Castbar_Simple"],
                            width    = "75%",
                            desc     = L["Castbar_Simple_Desc"],
                            disabled = function(info)
                                return not info.handler.db.profile.layoutSettings[layoutName].castBar.useModernCastbars
                            end,
                            get      = function(info)
                                return info.handler.db.profile.layoutSettings[layoutName].castBar.simpleCastbar
                            end,
                            set      = function(info, val)
                                local castDB = info.handler.db.profile.layoutSettings[layoutName].castBar
                                castDB.simpleCastbar = val
                                info.handler:RefreshConfig()
                            end,
                        },

                        spacerOne = {
                            order = 2.4,
                            type  = "description",
                            name  = "",
                            width = "full",
                        },

                        hideBorderShield = {
                            order = 2.5,
                            name = L["Castbar_HideShield"],
                            desc = L["Castbar_HideShield_Desc"],
                            type = "toggle",
                            get = function(info)
                                return info.handler.db.profile.layoutSettings[layoutName].castBar.hideBorderShield
                            end,
                            set = function(info, val)
                                info.handler.db.profile.layoutSettings[layoutName].castBar.hideBorderShield = val
                                info.handler:UpdateCastBarSettings(info.handler.db.profile.layoutSettings[layoutName].castBar, info, val)
                            end,
                        },

                        hideCastbarSpark = {
                            order = 2.6,
                            name = L["Castbar_HideSpark"],
                            desc = L["Castbar_HideSpark_Desc"],
                            type = "toggle",
                            get = function(info)
                                return info.handler.db.profile.layoutSettings[layoutName].castBar.hideCastbarSpark
                            end,
                            set = function(info, val)
                                info.handler.db.profile.layoutSettings[layoutName].castBar.hideCastbarSpark = val
                                info.handler:UpdateCastBarSettings(info.handler.db.profile.layoutSettings[layoutName].castBar, info, val)
                            end,
                        },

                        hideCastbarIcon = {
                            order = 2.7,
                            name = L["Castbar_HideIcon"],
                            desc = L["Castbar_HideIcon_Desc"],
                            type = "toggle",
                            get = function(info)
                                return info.handler.db.profile.layoutSettings[layoutName].castBar.hideCastbarIcon
                            end,
                            set = function(info, val)
                                info.handler.db.profile.layoutSettings[layoutName].castBar.hideCastbarIcon = val
                                info.handler:UpdateCastBarSettings(info.handler.db.profile.layoutSettings[layoutName].castBar, info, val)
                            end,
                        },

                        spacer = {
                            order = 2.9,
                            type  = "description",
                            name  = "",
                            width = "full",
                        },

                        castbarStatusBarTexture = {
                            order         = 3,
                            type          = "select",
                            name          = "|A:GarrMission_ClassIcon-DemonHunter-Outcast:20:20|a " .. L["Castbar_Texture"],
                            style         = "dropdown",
                            dialogControl = "LSM30_Statusbar",
                            values        = StatusbarValues,
                            get           = function(info)
                                local layout = info.handler.db.profile.layoutSettings[layoutName]
                                local t = layout.textures
                                return (t and t.castbarStatusBarTexture) or "sArena Default"
                            end,
                            set           = function(info, key)
                                local layout = info.handler.db.profile.layoutSettings[layoutName]
                                layout.textures = layout.textures or {
                                    generalStatusBarTexture = "sArena Default",
                                    healStatusBarTexture    = "sArena Default",
                                    castbarStatusBarTexture = "sArena Default",
                                    castbarUninterruptibleTexture = "sArena Default",
                                }
                                layout.textures.castbarStatusBarTexture = key
                                info.handler:UpdateTextures()
                            end,
                            width         = "75%",
                            disabled      = function(info)
                                return info.handler.db.profile.layoutSettings[layoutName].castBar.useModernCastbars and info.handler.db.profile.layoutSettings[layoutName].castBar.keepDefaultModernTextures
                            end,
                        },
                        castbarUninterruptibleTexture = {
                            order         = 3.5,
                            type          = "select",
                            name          = "|A:GarrMission_ClassIcon-DemonHunter-Outcast:20:20|a " .. L["Castbar_UninterruptibleTexture"],
                            style         = "dropdown",
                            dialogControl = "LSM30_Statusbar",
                            values        = StatusbarValues,
                            get           = function(info)
                                local layout = info.handler.db.profile.layoutSettings[layoutName]
                                local t = layout.textures
                                return (t and t.castbarUninterruptibleTexture) or (t and t.castbarStatusBarTexture) or "sArena Default"
                            end,
                            set           = function(info, key)
                                local layout = info.handler.db.profile.layoutSettings[layoutName]
                                layout.textures = layout.textures or {
                                    generalStatusBarTexture = "sArena Default",
                                    healStatusBarTexture    = "sArena Default",
                                    castbarStatusBarTexture = "sArena Default",
                                    castbarUninterruptibleTexture = "sArena Default",
                                }
                                layout.textures.castbarUninterruptibleTexture = key
                                info.handler:UpdateTextures()
                            end,
                            width         = "75%",
                            disabled      = function(info)
                                return info.handler.db.profile.layoutSettings[layoutName].castBar.useModernCastbars and info.handler.db.profile.layoutSettings[layoutName].castBar.keepDefaultModernTextures
                            end,
                        },
                        castBarColorsGroup = {
                            order = 4,
                            type = "group",
                            name = L["Castbar_Colors"],
                            inline = true,
                            args = {
                                recolorCastbar = {
                                    order = 0,
                                    type = "toggle",
                                    width = "full",
                                    name = L["Castbar_RecolorCastbar"],
                                    desc = L["Castbar_RecolorCastbar_Desc"],
                                    get = function(info)
                                        local layout = info.handler.db.profile.layoutSettings[layoutName]
                                        return layout.castBar.recolorCastbar or false
                                    end,
                                    set = function(info, val)
                                        local layout = info.handler.db.profile.layoutSettings[layoutName]
                                        layout.castBar.recolorCastbar = val
                                        info.handler:UpdateCastbarColors()
                                        info.handler:UpdateTextures()
                                        info.handler:RefreshTestModeCastbars()
                                    end,
                                },
                                standard = {
                                    order = 1,
                                    disabled = function(info)
                                        local layout = info.handler.db.profile.layoutSettings[layoutName]
                                        return not layout.castBar.recolorCastbar
                                    end,
                                    type = "color",
                                    name = L["Castbar_Cast"],
                                    hasAlpha = true,
                                    get = function(info)
                                        local colors = info.handler.db.profile.castBarColors
                                        if colors and colors.standard then
                                            return unpack(colors.standard)
                                        end
                                        return 1.0, 0.7, 0.0, 1
                                    end,
                                    set = function(info, r, g, b, a)
                                        info.handler.db.profile.castBarColors = info.handler.db.profile.castBarColors or {}
                                        info.handler.db.profile.castBarColors.standard = {r, g, b, a}
                                        info.handler:UpdateCastbarColors()
                                        info.handler:UpdateTextures()
                                        info.handler:RefreshTestModeCastbars()
                                    end,
                                },
                                channel = {
                                    order = 2,
                                    type = "color",
                                    name = L["Castbar_Channeled"],
                                    hasAlpha = true,
                                    disabled = function(info)
                                        local layout = info.handler.db.profile.layoutSettings[layoutName]
                                        return not layout.castBar.recolorCastbar
                                    end,
                                    get = function(info)
                                        local colors = info.handler.db.profile.castBarColors
                                        if colors and colors.channel then
                                            return unpack(colors.channel)
                                        end
                                        return 0.0, 1.0, 0.0, 1
                                    end,
                                    set = function(info, r, g, b, a)
                                        info.handler.db.profile.castBarColors = info.handler.db.profile.castBarColors or {}
                                        info.handler.db.profile.castBarColors.channel = {r, g, b, a}
                                        info.handler:UpdateCastbarColors()
                                        info.handler:UpdateTextures()
                                        info.handler:RefreshTestModeCastbars()
                                    end,
                                },
                                uninterruptable = {
                                    order = 3,
                                    type = "color",
                                    name = L["Castbar_Uninterruptible"],
                                    hasAlpha = true,
                                    disabled = function(info)
                                        local layout = info.handler.db.profile.layoutSettings[layoutName]
                                        return not layout.castBar.recolorCastbar
                                    end,
                                    get = function(info)
                                        local colors = info.handler.db.profile.castBarColors
                                        if colors and colors.uninterruptable then
                                            return unpack(colors.uninterruptable)
                                        end
                                        return 0.7, 0.7, 0.7, 1
                                    end,
                                    set = function(info, r, g, b, a)
                                        info.handler.db.profile.castBarColors = info.handler.db.profile.castBarColors or {}
                                        info.handler.db.profile.castBarColors.uninterruptable = {r, g, b, a}
                                        info.handler:UpdateCastbarColors()
                                        info.handler:UpdateTextures()
                                        info.handler:RefreshTestModeCastbars()
                                    end,
                                },
                            },
                        },
                        interruptNotReadyGroup = {
                            order = 5,
                            type = "group",
                            name = L["Castbar_InterruptNotReady"],
                            inline = true,
                            args = {
                                interruptStatusColorOn = {
                                    order = 1,
                                    type = "toggle",
                                    width = "full",
                                    name = L["Castbar_EnableNoInterruptColor"],
                                    desc = L["Castbar_EnableNoInterruptColor_Desc"],
                                    get = function(info)
                                        local layout = info.handler.db.profile.layoutSettings[layoutName]
                                        return layout.castBar.interruptStatusColorOn or false
                                    end,
                                    set = function(info, val)
                                        local layout = info.handler.db.profile.layoutSettings[layoutName]
                                        layout.castBar.interruptStatusColorOn = val
                                        info.handler:UpdateCastbarColors()
                                        info.handler:UpdateTextures()
                                        info.handler:RefreshTestModeCastbars()
                                    end,
                                },
                                interruptNotReady = {
                                    order = 2,
                                    type = "color",
                                    name = L["Castbar_InterruptNotReadyColor"],
                                    width = "full",
                                    hasAlpha = true,
                                    disabled = function(info)
                                        local layout = info.handler.db.profile.layoutSettings[layoutName]
                                        return not (layout.castBar.interruptStatusColorOn)
                                    end,
                                    get = function(info)
                                        local colors = info.handler.db.profile.castBarColors
                                        if colors and colors.interruptNotReady then
                                            return unpack(colors.interruptNotReady)
                                        end
                                        return 1.0, 0.0, 0.0, 1
                                    end,
                                    set = function(info, r, g, b, a)
                                        info.handler.db.profile.castBarColors = info.handler.db.profile.castBarColors or {}
                                        info.handler.db.profile.castBarColors.interruptNotReady = {r, g, b, a}
                                        info.handler:UpdateCastbarColors()
                                        info.handler:UpdateTextures()
                                        info.handler:RefreshTestModeCastbars()
                                    end,
                                },
                            },
                        },
                    },
                },
                castbarPosition = {
                    order = 1,
                    name = L["Castbar_Position"],
                    type = "group",
                    inline = true,
                    args = {
                        posX = {
                            order = 1,
                            name = L["Horizontal"],
                            type = "range",
                            min = -700,
                            max = 700,
                            softMin = -350,
                            softMax = 350,
                            step = 0.1,
                            bigStep = 1,
                        },
                        posY = {
                            order = 2,
                            name = L["Vertical"],
                            type = "range",
                            min = -700,
                            max = 700,
                            softMin = -350,
                            softMax = 350,
                            step = 0.1,
                            bigStep = 1,
                        },
                    },
                },
                iconPosition = {
                    order = 3,
                    name = L["Castbar_IconPosition"],
                    type = "group",
                    inline = true,
                    args = {
                        iconPosX = {
                            order = 1,
                            name = L["Horizontal"],
                            type = "range",
                            min = -500,
                            max = 500,
                            softMin = -200,
                            softMax = 200,
                            step = 0.1,
                            bigStep = 1,
                        },
                        iconPosY = {
                            order = 2,
                            name = L["Vertical"],
                            type = "range",
                            min = -500,
                            max = 500,
                            softMin = -200,
                            softMax = 200,
                            step = 0.1,
                            bigStep = 1,
                        },
                    },
                },
                castbarSize = {
                    order = 2,
                    name = L["Castbar_CastbarSize"],
                    type = "group",
                    inline = true,
                    args = {
                        scale = {
                            order = 1,
                            name = L["Scale"],
                            type = "range",
                            min = 0.1,
                            max = 5.0,
                            softMin = 0.5,
                            softMax = 3.0,
                            step = 0.01,
                            bigStep = 0.1,
                            isPercent = true,
                        },
                        width = {
                            order = 2,
                            name = L["Width"],
                            type = "range",
                            min = 10,
                            max = 400,
                            step = 1,
                        },
                    },
                },
                iconSize = {
                    order = 4,
                    name = L["Castbar_IconSize"],
                    type = "group",
                    inline = true,
                    args = {
                        iconScale = {
                            order = 1,
                            name = L["Castbar_IconScale"],
                            type = "range",
                            min = 0.1,
                            max = 5.0,
                            softMin = 0.5,
                            softMax = 3.0,
                            step = 0.01,
                            bigStep = 0.1,
                            isPercent = true,
                        },
                    },
                },
            },
        },
        dr = {
            order = 6,
            name = L["Category_DiminishingReturns"],
            type = "group",
            get = function(info) return info.handler.db.profile.layoutSettings[layoutName].dr[info[#info]] end,
            set = function(info, val)
                self:UpdateDRSettings(info.handler.db.profile.layoutSettings[layoutName].dr, info, val)
                if sArenaMixin.RefreshMasque then
                    sArenaMixin:RefreshMasque()
                end
            end,
            args = {
                options = {
                    order = 0,
                    name = L["Options"],
                    type = "group",
                    inline = true,
                    args = {
                        brightDRBorder = {
                            order = 1,
                            name  = L["DR_BrightBorder"],
                            type  = "toggle",
                            get = function(info)
                                return info.handler.db.profile.layoutSettings[layoutName].dr.brightDRBorder
                            end,
                            set = function(info, val)
                                local db = info.handler.db.profile.layoutSettings[layoutName].dr
                                db.brightDRBorder = val
                                if val then
                                    db.drBorderGlowOff = false
                                    db.thickPixelBorder = false
                                    db.thinPixelBorder = false
                                end
                                self:UpdateDRSettings(info.handler.db.profile.layoutSettings[layoutName].dr, info, val)
                                LibStub("AceConfigRegistry-3.0"):NotifyChange("sArena")
                            end,
                        },
                        blackDRBorder = {
                            order = 2,
                            name  = L["DR_BlackBorder"],
                            type  = "toggle",
                            desc  = L["DR_BlackBorder_Desc"],
                            get = function(info)
                                return info.handler.db.profile.layoutSettings[layoutName].dr.blackDRBorder
                            end,
                            set = function(info, val)
                                local db = info.handler.db.profile.layoutSettings[layoutName].dr
                                db.blackDRBorder = val
                                self:UpdateDRSettings(info.handler.db.profile.layoutSettings[layoutName].dr, info, val)
                                info.handler:RefreshConfig()
                                info.handler:Test()
                            end,
                        },
                        showDRText = {
                            order = 3,
                            name = L["DR_ShowText"],
                            desc = L["DR_ShowText_Desc"],
                            type = "toggle",
                            get = function(info)
                                return info.handler.db.profile.layoutSettings[layoutName].dr.showDRText
                            end,
                            set = function(info, val)
                                local db = info.handler.db.profile.layoutSettings[layoutName].dr
                                db.showDRText = val
                                self:UpdateDRSettings(db, info, val)
                            end,
                        },
                        drBorderGlowOff = {
                            order = 4,
                            name  = L["DR_DisableBorderGlow"],
                            type  = "toggle",
                            get = function(info)
                                return info.handler.db.profile.layoutSettings[layoutName].dr.drBorderGlowOff
                            end,
                            set = function(info, val)
                                local db = info.handler.db.profile.layoutSettings[layoutName].dr
                                db.drBorderGlowOff = val
                                if val then
                                    db.brightDRBorder = false
                                    db.thickPixelBorder = false
                                    db.thinPixelBorder = false
                                end
                                self:UpdateDRSettings(info.handler.db.profile.layoutSettings[layoutName].dr, info, val)
                                info.handler:RefreshConfig()
                                info.handler:Test()
                                LibStub("AceConfigRegistry-3.0"):NotifyChange("sArena")
                            end,
                        },
                        thickPixelBorder = {
                            order = 5,
                            name  = L["DR_ThickPixelBorder"],
                            type  = "toggle",
                            get = function(info)
                                return info.handler.db.profile.layoutSettings[layoutName].dr.thickPixelBorder
                            end,
                            set = function(info, val)
                                local db = info.handler.db.profile.layoutSettings[layoutName].dr
                                db.thickPixelBorder = val
                                if val then
                                    db.brightDRBorder = false
                                    db.drBorderGlowOff = false
                                    db.thinPixelBorder = false
                                end
                                self:UpdateDRSettings(info.handler.db.profile.layoutSettings[layoutName].dr, info, val)
                                info.handler:RefreshConfig()
                                info.handler:Test()
                                LibStub("AceConfigRegistry-3.0"):NotifyChange("sArena")
                            end,
                        },
                        thinPixelBorder = {
                            order = 5.5,
                            name  = L["DR_ThinPixelBorder"],
                            type  = "toggle",
                            get = function(info)
                                return info.handler.db.profile.layoutSettings[layoutName].dr.thinPixelBorder
                            end,
                            set = function(info, val)
                                local db = info.handler.db.profile.layoutSettings[layoutName].dr
                                db.thinPixelBorder = val
                                if val then
                                    db.brightDRBorder = false
                                    db.drBorderGlowOff = false
                                    db.thickPixelBorder = false
                                end
                                self:UpdateDRSettings(info.handler.db.profile.layoutSettings[layoutName].dr, info, val)
                                info.handler:RefreshConfig()
                                info.handler:Test()
                                LibStub("AceConfigRegistry-3.0"):NotifyChange("sArena")
                            end,
                        },
                        disableDRBorder = {
                            order = 6,
                            name  = L["DR_DisableBorder"],
                            type  = "toggle",
                            desc  = L["DR_DisableBorder_Desc"],
                            get = function(info)
                                return info.handler.db.profile.layoutSettings[layoutName].dr.disableDRBorder
                            end,
                            set = function(info, val)
                                local db = info.handler.db.profile.layoutSettings[layoutName].dr
                                db.disableDRBorder = val
                                self:UpdateDRSettings(info.handler.db.profile.layoutSettings[layoutName].dr, info, val)
                                info.handler:RefreshConfig()
                                info.handler:Test()
                            end,
                        },
                    },
                },
                positioning = {
                    order = 1,
                    name = L["Positioning"],
                    type = "group",
                    inline = true,
                    args = {
                        posX = {
                            order = 1,
                            name = L["Horizontal"],
                            type = "range",
                            min = -700,
                            max = 700,
                            softMin = -350,
                            softMax = 350,
                            step = 0.1,
                            bigStep = 1,
                        },
                        posY = {
                            order = 2,
                            name = L["Vertical"],
                            type = "range",
                            min = -700,
                            max = 700,
                            softMin = -350,
                            softMax = 350,
                            step = 0.1,
                            bigStep = 1,
                        },
                        spacing = {
                            order = 3,
                            name = L["Spacing"],
                            type = "range",
                            min = 0,
                            max = 32,
                            softMin = 0,
                            softMax = 32,
                            step = 1,
                            disabled = function()
                                return sArenaMixin.isMidnight
                            end,
                        },
                        growthDirection = {
                            order = 4,
                            name = L["Option_GrowthDirection"],
                            type = "select",
                            style = "dropdown",
                            values = growthValues,
                        },
                    },
                },
                sizing = {
                    order = 2,
                    name = L["Sizing"],
                    type = "group",
                    inline = true,
                    args = {
                        size = {
                            order = 1,
                            name = L["Size"],
                            type = "range",
                            min = 2,
                            max = 128,
                            softMin = 8,
                            softMax = 64,
                            step = 1,
                        },
                        borderSize = {
                            order = 2,
                            name = L["DR_BorderSize"],
                            type = "range",
                            min = 0,
                            max = 24,
                            softMin = 1,
                            softMax = 16,
                            step = 0.1,
                            bigStep = 1,
                            disabled = function(info)
                                local drSettings = info.handler.db.profile.layoutSettings[layoutName].dr
                                return drSettings.brightDRBorder or drSettings.drBorderGlowOff or drSettings.thickPixelBorder or drSettings.thinPixelBorder
                            end,
                        },
                        fontSize = {
                            order = 3,
                            name = L["Option_FontSize"],
                            desc = L["Option_FontSize_Desc"],
                            type = "range",
                            min = 2,
                            max = 48,
                            softMin = 4,
                            softMax = 32,
                            step = 1,
                        },
                    },
                },
                drCategorySizing = {
                    order = 3,
                    name = L["DR_SpecificSizeAdjustment"],
                    type = "group",
                    inline = true,
                    disabled = function() return isMidnight end,
                    args = {},
                },
            },
        },
    }

    local drCategoryOrder = {
        Incapacitate = 1,
        Stun         = 2,
        Root         = 3,
        Silence      = 4,
        Disarm       = 5,
        Disorient    = 6,
        Knock        = 7,
    }

    for categoryKey, categoryName in pairs(drCategoryDisplay) do
        optionsTable.dr.args.drCategorySizing.args[categoryKey] = {
            order = drCategoryOrder[categoryKey],
            name = L["DR_" .. categoryKey] or categoryName,
            type = "range",
            min = -25,
            max = 25,
            softMin = -10,
            softMax = 20,
            step = 1,
            get = function(info)
                local dr = info.handler.db.profile.layoutSettings[layoutName].dr
                dr.drCategorySizeOffsets = dr.drCategorySizeOffsets or {}
                return dr.drCategorySizeOffsets[info[#info]] or 0
            end,
            set = function(info, val)
                local dr = info.handler.db.profile.layoutSettings[layoutName].dr
                dr.drCategorySizeOffsets = dr.drCategorySizeOffsets or {}
                dr.drCategorySizeOffsets[info[#info]] = val
                self:UpdateDRSettings(dr, info)
            end,
        }
    end

    -- Widgets options
    optionsTable.widgets = {
        order = 6.5,
        name = L["Category_Widgets"] .. " |A:NewCharacter-Alliance:38:65|a",
        type = "group",
        get = function(info)
            local widgets = info.handler.db.profile.layoutSettings[layoutName].widgets
            local widgetType = info[#info - 1]
            local setting = info[#info]

            if widgets and widgets[widgetType] then
                return widgets[widgetType][setting]
            end
            return nil
        end,
        set = function(info, val)
            local widgets = info.handler.db.profile.layoutSettings[layoutName].widgets
            widgets = widgets or {}
            local widgetType = info[#info - 1]
            widgets[widgetType] = widgets[widgetType] or {}
            widgets[widgetType][info[#info]] = val

            info.handler.db.profile.layoutSettings[layoutName].widgets = widgets
            self:UpdateWidgetSettings(widgets, info, val)
        end,
        args = {
            combatIndicator = {
                order = 1,
                name = L["Widget_CombatIndicator"] .. " |A:Food:23:23|a",
                type = "group",
                inline = true,
                args = {
                    enabled = {
                        order = 1,
                        name = L["Widget_CombatIndicator_Enable"],
                        desc = L["Widget_CombatIndicator_Desc"],
                        type = "toggle",
                        width = "full",
                        set = function(info, val)
                            local widgets = info.handler.db.profile.layoutSettings[layoutName].widgets
                            widgets = widgets or {}
                            widgets.combatIndicator = widgets.combatIndicator or {}
                            widgets.combatIndicator.enabled = val
                            info.handler.db.profile.layoutSettings[layoutName].widgets = widgets
                            self:UpdateWidgetSettings(widgets, info, val)
                            info.handler:Test()
                        end,
                    },
                    scale = {
                        order = 2,
                        name = L["Scale"],
                        type = "range",
                        min = 0.1,
                        max = 3.0,
                        step = 0.01,
                        bigStep = 0.1,
                        isPercent = true,
                        width = 0.95,
                        disabled = function(info)
                            local widgets = info.handler.db.profile.layoutSettings[layoutName].widgets
                            return not (widgets and widgets.combatIndicator and widgets.combatIndicator.enabled)
                        end,
                    },
                    posX = {
                        order = 3,
                        name = L["Horizontal"],
                        type = "range",
                        min = -500,
                        max = 500,
                        step = 0.1,
                        bigStep = 1,
                        width = 0.95,
                        disabled = function(info)
                            local widgets = info.handler.db.profile.layoutSettings[layoutName].widgets
                            return not (widgets and widgets.combatIndicator and widgets.combatIndicator.enabled)
                        end,
                    },
                    posY = {
                        order = 4,
                        name = L["Vertical"],
                        type = "range",
                        min = -500,
                        max = 500,
                        step = 0.1,
                        bigStep = 1,
                        width = 0.95,
                        disabled = function(info)
                            local widgets = info.handler.db.profile.layoutSettings[layoutName].widgets
                            return not (widgets and widgets.combatIndicator and widgets.combatIndicator.enabled)
                        end,
                    },
                    resetCombatIndicator = {
                        order = 5,
                        name = L["Reset"],
                        width = 0.4,
                        type = "execute",
                        func = function(info)
                            local layout = info.handler.db.profile.layoutSettings[layoutName]
                            local currentLayout = info.handler.layouts[layoutName]
                            local defaults = currentLayout.defaultSettings.widgets
                            layout.widgets = layout.widgets or {}
                            local currentEnabled = layout.widgets.combatIndicator and layout.widgets.combatIndicator.enabled
                            layout.widgets.combatIndicator = {
                                enabled = currentEnabled,
                                scale = defaults.combatIndicator.scale,
                                posX = defaults.combatIndicator.posX,
                                posY = defaults.combatIndicator.posY,
                            }
                            self:UpdateWidgetSettings(layout.widgets, info, nil)
                            LibStub("AceConfigRegistry-3.0"):NotifyChange("sArena")
                        end,
                    },
                },
            },
            targetIndicator = {
                order = 2,
                name = L["Widget_TargetIndicator"] .. " |A:TargetCrosshairs:45:45|a",
                type = "group",
                inline = true,
                args = {
                    enabled = {
                        order = 1,
                        name = L["Widget_TargetIndicator_Enable"],
                        desc = L["Widget_TargetIndicator_Desc"],
                        type = "toggle",
                        width = "full",
                        set = function(info, val)
                            local widgets = info.handler.db.profile.layoutSettings[layoutName].widgets
                            widgets = widgets or {}
                            widgets.targetIndicator = widgets.targetIndicator or {}
                            widgets.targetIndicator.enabled = val
                            info.handler.db.profile.layoutSettings[layoutName].widgets = widgets
                            self:UpdateWidgetSettings(widgets, info, val)
                            info.handler:Test()
                        end,
                    },
                    scale = {
                        order = 2,
                        name = L["Scale"],
                        type = "range",
                        min = 0.1,
                        max = 3.0,
                        step = 0.01,
                        bigStep = 0.1,
                        isPercent = true,
                        width = 0.95,
                        disabled = function(info)
                            local widgets = info.handler.db.profile.layoutSettings[layoutName].widgets
                            return not (widgets and widgets.targetIndicator and widgets.targetIndicator.enabled)
                        end,
                    },
                    posX = {
                        order = 3,
                        name = L["Horizontal"],
                        type = "range",
                        min = -500,
                        max = 500,
                        step = 0.1,
                        bigStep = 1,
                        width = 0.95,
                        disabled = function(info)
                            local widgets = info.handler.db.profile.layoutSettings[layoutName].widgets
                            return not (widgets and widgets.targetIndicator and widgets.targetIndicator.enabled)
                        end,
                    },
                    posY = {
                        order = 4,
                        name = L["Vertical"],
                        type = "range",
                        min = -500,
                        max = 500,
                        step = 0.1,
                        bigStep = 1,
                        width = 0.95,
                        disabled = function(info)
                            local widgets = info.handler.db.profile.layoutSettings[layoutName].widgets
                            return not (widgets and widgets.targetIndicator and widgets.targetIndicator.enabled)
                        end,
                    },
                    resetTargetIndicator = {
                        order = 5,
                        name = L["Reset"],
                        width = 0.4,
                        type = "execute",
                        func = function(info)
                            local layout = info.handler.db.profile.layoutSettings[layoutName]
                            local currentLayout = info.handler.layouts[layoutName]
                            local defaults = currentLayout.defaultSettings.widgets
                            layout.widgets = layout.widgets or {}
                            local currentEnabled = layout.widgets.targetIndicator and layout.widgets.targetIndicator.enabled
                            layout.widgets.targetIndicator = {
                                enabled = currentEnabled,
                                scale = defaults.targetIndicator.scale,
                                posX = defaults.targetIndicator.posX,
                                posY = defaults.targetIndicator.posY,
                            }
                            self:UpdateWidgetSettings(layout.widgets, info, nil)
                            LibStub("AceConfigRegistry-3.0"):NotifyChange("sArena")
                        end,
                    },
                },
            },
            focusIndicator = {
                order = 3,
                name = L["Widget_FocusIndicator"] .. " |TInterface\\AddOns\\sArena_Reloaded\\Textures\\Waypoint-MapPin-Untracked.tga:23:23|t",
                type = "group",
                inline = true,
                args = {
                    enabled = {
                        order = 1,
                        name = L["Widget_FocusIndicator_Enable"],
                        desc = L["Widget_FocusIndicator_Desc"],
                        type = "toggle",
                        width = "full",
                        set = function(info, val)
                            local widgets = info.handler.db.profile.layoutSettings[layoutName].widgets
                            widgets = widgets or {}
                            widgets.focusIndicator = widgets.focusIndicator or {}
                            widgets.focusIndicator.enabled = val
                            info.handler.db.profile.layoutSettings[layoutName].widgets = widgets
                            self:UpdateWidgetSettings(widgets, info, val)
                            info.handler:Test()
                        end,
                    },
                    scale = {
                        order = 2,
                        name = L["Scale"],
                        type = "range",
                        min = 0.1,
                        max = 3.0,
                        step = 0.01,
                        bigStep = 0.1,
                        isPercent = true,
                        width = 0.95,
                        disabled = function(info)
                            local widgets = info.handler.db.profile.layoutSettings[layoutName].widgets
                            return not (widgets and widgets.focusIndicator and widgets.focusIndicator.enabled)
                        end,
                    },
                    posX = {
                        order = 3,
                        name = L["Horizontal"],
                        type = "range",
                        min = -500,
                        max = 500,
                        step = 0.1,
                        bigStep = 1,
                        width = 0.95,
                        disabled = function(info)
                            local widgets = info.handler.db.profile.layoutSettings[layoutName].widgets
                            return not (widgets and widgets.focusIndicator and widgets.focusIndicator.enabled)
                        end,
                    },
                    posY = {
                        order = 4,
                        name = L["Vertical"],
                        type = "range",
                        min = -500,
                        max = 500,
                        step = 0.1,
                        bigStep = 1,
                        width = 0.95,
                        disabled = function(info)
                            local widgets = info.handler.db.profile.layoutSettings[layoutName].widgets
                            return not (widgets and widgets.focusIndicator and widgets.focusIndicator.enabled)
                        end,
                    },
                    resetFocusIndicator = {
                        order = 5,
                        name = L["Reset"],
                        width = 0.4,
                        type = "execute",
                        func = function(info)
                            local layout = info.handler.db.profile.layoutSettings[layoutName]
                            local currentLayout = info.handler.layouts[layoutName]
                            local defaults = currentLayout.defaultSettings.widgets
                            layout.widgets = layout.widgets or {}
                            local currentEnabled = layout.widgets.focusIndicator and layout.widgets.focusIndicator.enabled
                            layout.widgets.focusIndicator = {
                                enabled = currentEnabled,
                                scale = defaults.focusIndicator.scale,
                                posX = defaults.focusIndicator.posX,
                                posY = defaults.focusIndicator.posY,
                            }
                            self:UpdateWidgetSettings(layout.widgets, info, nil)
                            LibStub("AceConfigRegistry-3.0"):NotifyChange("sArena")
                        end,
                    },
                },
            },
            partyTargetIndicators = {
                order = 4,
                name = L["Widget_PartyTargetIndicators"] .. " |TInterface\\AddOns\\sArena_Reloaded\\Textures\\GM-icon-headCount.tga:19:19|t",
                type = "group",
                inline = true,
                args = {
                    enabled = {
                        order = 1,
                        name = L["Widget_PartyTargetIndicators_Enable"],
                        desc = L["Widget_PartyTargetIndicators_Desc"],
                        type = "toggle",
                        width = "full",
                        set = function(info, val)
                            local widgets = info.handler.db.profile.layoutSettings[layoutName].widgets
                            widgets = widgets or {}
                            widgets.partyTargetIndicators = widgets.partyTargetIndicators or {}
                            widgets.partyTargetIndicators.enabled = val
                            info.handler.db.profile.layoutSettings[layoutName].widgets = widgets
                            self:UpdateWidgetSettings(widgets, info, val)
                            info.handler:Test()
                        end,
                    },
                    scale = {
                        order = 2,
                        name = L["Scale"],
                        type = "range",
                        min = 0.1,
                        max = 3.0,
                        step = 0.01,
                        bigStep = 0.1,
                        isPercent = true,
                        width = 0.95,
                        disabled = function(info)
                            local widgets = info.handler.db.profile.layoutSettings[layoutName].widgets
                            return not (widgets and widgets.partyTargetIndicators and widgets.partyTargetIndicators.enabled)
                        end,
                    },
                    posX = {
                        order = 3,
                        name = L["Horizontal"],
                        type = "range",
                        min = -500,
                        max = 500,
                        step = 0.1,
                        bigStep = 1,
                        width = 0.95,
                        disabled = function(info)
                            local widgets = info.handler.db.profile.layoutSettings[layoutName].widgets
                            return not (widgets and widgets.partyTargetIndicators and widgets.partyTargetIndicators.enabled)
                        end,
                    },
                    posY = {
                        order = 4,
                        name = L["Vertical"],
                        type = "range",
                        min = -500,
                        max = 500,
                        step = 0.1,
                        bigStep = 1,
                        width = 0.95,
                        disabled = function(info)
                            local widgets = info.handler.db.profile.layoutSettings[layoutName].widgets
                            return not (widgets and widgets.partyTargetIndicators and widgets.partyTargetIndicators.enabled)
                        end,
                    },
                    resetPartyTargetIndicators = {
                        order = 5,
                        name = L["Reset"],
                        width = 0.4,
                        type = "execute",
                        func = function(info)
                            local layout = info.handler.db.profile.layoutSettings[layoutName]
                            local currentLayout = info.handler.layouts[layoutName]
                            local defaults = currentLayout.defaultSettings.widgets
                            layout.widgets = layout.widgets or {}
                            local currentEnabled = layout.widgets.partyTargetIndicators and layout.widgets.partyTargetIndicators.enabled
                            layout.widgets.partyTargetIndicators = {
                                enabled = currentEnabled,
                                scale = defaults.partyTargetIndicators.scale,
                                posX = defaults.partyTargetIndicators.posX,
                                posY = defaults.partyTargetIndicators.posY,
                            }
                            self:UpdateWidgetSettings(layout.widgets, info, nil)
                            LibStub("AceConfigRegistry-3.0"):NotifyChange("sArena")
                        end,
                    },
                },
            },
        },
    }

    -- Text Settings options
    optionsTable.textSettings = {
        order = 1.1,
        name = L["Category_TextSettings"],
        type = "group",
        args = {
            fonts = {
                order  = 0,
                name   = L["Text_Fonts"],
                type   = "group",
                inline = true,
                args   = {
                    changeFont = {
                        order = 0,
                        type = "toggle",
                        name  = L["Text_ChangeFont"],
                        desc  = L["Text_ChangeFont_Desc"],
                        width = "full",
                        get   = getSetting,
                        set   = setSetting,
                    },
                    frameFont = {
                        order = 1, type = "select",
                        name  = L["Text_FrameFont"],
                        desc  = L["Text_FrameFont_Desc"],
                        style = "dropdown",
                        width = 0.7,
                        dialogControl = "LSM30_Font",
                        values = sArenaMixin.FontValues,
                        get    = getSetting,
                        set    = setSetting,
                        disabled = function(info)
                            return not info.handler.db.profile.layoutSettings[layoutName].changeFont
                        end,
                    },
                    cdFont = {
                        order = 2, type = "select",
                        name  = L["Text_CooldownFont"],
                        desc  = L["Text_CooldownFont_Desc"],
                        style = "dropdown",
                        width = 0.7,
                        dialogControl = "LSM30_Font",
                        values = sArenaMixin.FontValues,
                        get    = getSetting,
                        set    = setSetting,
                        disabled = function(info)
                            return not info.handler.db.profile.layoutSettings[layoutName].changeFont
                        end,
                    },
                    fontOutline = {
                        order = 3, type = "select",
                        name  = L["Text_FontOutline"],
                        desc  = L["Text_FontOutline_Desc"],
                        style = "dropdown",
                        width = 0.7,
                        values = sArenaMixin.FontOutlineValues,
                        get    = getFontOutlineSetting,
                        set    = setSetting,
                        disabled = function(info)
                            return not info.handler.db.profile.layoutSettings[layoutName].changeFont
                        end,
                    },
                },
            },
            nameText = {
                order = 1,
                name = L["Text_NameText"],
                type = "group",
                inline = true,
                args = {
                    nameAnchor = {
                        order = 1,
                        name = L["Text_AnchorPoint"],
                        type = "select",
                        style = "dropdown",
                        width = 0.5,
                        values = {
                            ["LEFT"] = L["Direction_Left"],
                            ["CENTER"] = L["Direction_Center"],
                            ["RIGHT"] = L["Direction_Right"],
                        },
                        get = function(info)
                            local layout = info.handler.db.profile.layoutSettings[layoutName]
                            layout.textSettings = layout.textSettings or {}
                            return layout.textSettings.nameAnchor or "CENTER"
                        end,
                        set = function(info, val)
                            local layout = info.handler.db.profile.layoutSettings[layoutName]
                            layout.textSettings = layout.textSettings or {}
                            layout.textSettings.nameAnchor = val
                            sArenaMixin:UpdateTextPositions(layout.textSettings, info, val)
                        end,
                    },
                    nameSize = {
                        order = 2,
                        name = L["Size"],
                        type = "range",
                        min = 0.2,
                        max = 3,
                        softMin = 0.05,
                        softMax = 5,
                        step = 0.01,
                        width = 0.8,
                        isPercent = true,
                        get = function(info)
                            local layout = info.handler.db.profile.layoutSettings[layoutName]
                            layout.textSettings = layout.textSettings or {}
                            return layout.textSettings.nameSize or 1.0
                        end,
                        set = function(info, val)
                            local layout = info.handler.db.profile.layoutSettings[layoutName]
                            layout.textSettings = layout.textSettings or {}
                            layout.textSettings.nameSize = val
                            sArenaMixin:UpdateTextPositions(layout.textSettings, info, val)
                        end,
                    },
                    nameOffsetX = {
                        order = 3,
                        name = L["Horizontal"],
                        type = "range",
                        softMin = -200,
                        softMax = 200,
                        step = 0.5,
                        width = 0.8,
                        get = function(info)
                            local layout = info.handler.db.profile.layoutSettings[layoutName]
                            layout.textSettings = layout.textSettings or {}
                            return layout.textSettings.nameOffsetX or 0
                        end,
                        set = function(info, val)
                            local layout = info.handler.db.profile.layoutSettings[layoutName]
                            layout.textSettings = layout.textSettings or {}
                            layout.textSettings.nameOffsetX = val
                            sArenaMixin:UpdateTextPositions(layout.textSettings, info, val)
                        end,
                    },
                    nameOffsetY = {
                        order = 4,
                        name = L["Vertical"],
                        type = "range",
                        softMin = -200,
                        softMax = 200,
                        step = 0.5,
                        width = 0.8,
                        get = function(info)
                            local layout = info.handler.db.profile.layoutSettings[layoutName]
                            layout.textSettings = layout.textSettings or {}
                            return layout.textSettings.nameOffsetY or 0
                        end,
                        set = function(info, val)
                            local layout = info.handler.db.profile.layoutSettings[layoutName]
                            layout.textSettings = layout.textSettings or {}
                            layout.textSettings.nameOffsetY = val
                            sArenaMixin:UpdateTextPositions(layout.textSettings, info, val)
                        end,
                    },
                    resetNameText = {
                        order = 5,
                        name = L["Reset"],
                        width = 0.4,
                        type = "execute",
                        func = function(info)
                            local layout = info.handler.db.profile.layoutSettings[layoutName]
                            local currentLayout = info.handler.layouts[layoutName]
                            local defaults = currentLayout.defaultSettings.textSettings
                            layout.textSettings = layout.textSettings or {}
                            layout.textSettings.nameAnchor = defaults.nameAnchor
                            layout.textSettings.nameSize = defaults.nameSize
                            layout.textSettings.nameOffsetX = defaults.nameOffsetX
                            layout.textSettings.nameOffsetY = defaults.nameOffsetY
                            sArenaMixin:UpdateTextPositions(layout.textSettings, info, nil)
                            LibStub("AceConfigRegistry-3.0"):NotifyChange("sArena")
                        end,
                    },
                },
            },
            healthText = {
                order = 2,
                name = L["Text_HealthText"],
                type = "group",
                inline = true,
                args = {
                    healthAnchor = {
                        order = 1,
                        name = L["Text_AnchorPoint"],
                        type = "select",
                        style = "dropdown",
                        width = 0.5,
                        values = {
                            ["LEFT"] = L["Direction_Left"],
                            ["CENTER"] = L["Direction_Center"],
                            ["RIGHT"] = L["Direction_Right"],
                        },
                        get = function(info)
                            local layout = info.handler.db.profile.layoutSettings[layoutName]
                            layout.textSettings = layout.textSettings or {}
                            return layout.textSettings.healthAnchor or "CENTER"
                        end,
                        set = function(info, val)
                            local layout = info.handler.db.profile.layoutSettings[layoutName]
                            layout.textSettings = layout.textSettings or {}
                            layout.textSettings.healthAnchor = val
                            sArenaMixin:UpdateTextPositions(layout.textSettings, info, val)
                        end,
                    },
                    healthSize = {
                        order = 2,
                        name = L["Size"],
                        type = "range",
                        min = 0.05,
                        max = 5,
                        step = 0.01,
                        width = 0.8,
                        isPercent = true,
                        get = function(info)
                            local layout = info.handler.db.profile.layoutSettings[layoutName]
                            layout.textSettings = layout.textSettings or {}
                            return layout.textSettings.healthSize or 1.0
                        end,
                        set = function(info, val)
                            local layout = info.handler.db.profile.layoutSettings[layoutName]
                            layout.textSettings = layout.textSettings or {}
                            layout.textSettings.healthSize = val
                            sArenaMixin:UpdateTextPositions(layout.textSettings, info, val)
                        end,
                    },
                    healthOffsetX = {
                        order = 3,
                        name = L["Horizontal"],
                        type = "range",
                        softMin = -200,
                        softMax = 200,
                        step = 0.5,
                        width = 0.8,
                        get = function(info)
                            local layout = info.handler.db.profile.layoutSettings[layoutName]
                            layout.textSettings = layout.textSettings or {}
                            return layout.textSettings.healthOffsetX or 0
                        end,
                        set = function(info, val)
                            local layout = info.handler.db.profile.layoutSettings[layoutName]
                            layout.textSettings = layout.textSettings or {}
                            layout.textSettings.healthOffsetX = val
                            sArenaMixin:UpdateTextPositions(layout.textSettings, info, val)
                        end,
                    },
                    healthOffsetY = {
                        order = 4,
                        name = L["Vertical"],
                        type = "range",
                        softMin = -200,
                        softMax = 200,
                        step = 0.5,
                        width = 0.8,
                        get = function(info)
                            local layout = info.handler.db.profile.layoutSettings[layoutName]
                            layout.textSettings = layout.textSettings or {}
                            return layout.textSettings.healthOffsetY or 0
                        end,
                        set = function(info, val)
                            local layout = info.handler.db.profile.layoutSettings[layoutName]
                            layout.textSettings = layout.textSettings or {}
                            layout.textSettings.healthOffsetY = val
                            sArenaMixin:UpdateTextPositions(layout.textSettings, info, val)
                        end,
                    },
                    resetHealthText = {
                        order = 5,
                        name = L["Reset"],
                        width = 0.4,
                        type = "execute",
                        func = function(info)
                            local layout = info.handler.db.profile.layoutSettings[layoutName]
                            local currentLayout = info.handler.layouts[layoutName]
                            local defaults = currentLayout.defaultSettings.textSettings
                            layout.textSettings = layout.textSettings or {}
                            layout.textSettings.healthAnchor = defaults.healthAnchor
                            layout.textSettings.healthSize = defaults.healthSize
                            layout.textSettings.healthOffsetX = defaults.healthOffsetX
                            layout.textSettings.healthOffsetY = defaults.healthOffsetY
                            sArenaMixin:UpdateTextPositions(layout.textSettings, info, nil)
                            LibStub("AceConfigRegistry-3.0"):NotifyChange("sArena")
                        end,
                    },
                },
            },
            powerText = {
                order = 2.5,
                name = L["Text_ManaText"],
                type = "group",
                inline = true,
                args = {
                    powerAnchor = {
                        order = 1,
                        name = L["Text_AnchorPoint"],
                        type = "select",
                        style = "dropdown",
                        width = 0.5,
                        values = {
                            ["LEFT"] = L["Direction_Left"],
                            ["CENTER"] = L["Direction_Center"],
                            ["RIGHT"] = L["Direction_Right"],
                        },
                        get = function(info)
                            local layout = info.handler.db.profile.layoutSettings[layoutName]
                            layout.textSettings = layout.textSettings or {}
                            return layout.textSettings.powerAnchor or "CENTER"
                        end,
                        set = function(info, val)
                            local layout = info.handler.db.profile.layoutSettings[layoutName]
                            layout.textSettings = layout.textSettings or {}
                            layout.textSettings.powerAnchor = val
                            sArenaMixin:UpdateTextPositions(layout.textSettings, info, val)
                        end,
                    },
                    powerSize = {
                        order = 2,
                        name = L["Size"],
                        type = "range",
                        min = 0.05,
                        max = 5,
                        step = 0.01,
                        width = 0.8,
                        isPercent = true,
                        get = function(info)
                            local layout = info.handler.db.profile.layoutSettings[layoutName]
                            layout.textSettings = layout.textSettings or {}
                            return layout.textSettings.powerSize or 1.0
                        end,
                        set = function(info, val)
                            local layout = info.handler.db.profile.layoutSettings[layoutName]
                            layout.textSettings = layout.textSettings or {}
                            layout.textSettings.powerSize = val
                            sArenaMixin:UpdateTextPositions(layout.textSettings, info, val)
                        end,
                    },
                    powerOffsetX = {
                        order = 3,
                        name = L["Horizontal"],
                        type = "range",
                        softMin = -200,
                        softMax = 200,
                        step = 0.5,
                        width = 0.8,
                        get = function(info)
                            local layout = info.handler.db.profile.layoutSettings[layoutName]
                            layout.textSettings = layout.textSettings or {}
                            return layout.textSettings.powerOffsetX or 0
                        end,
                        set = function(info, val)
                            local layout = info.handler.db.profile.layoutSettings[layoutName]
                            layout.textSettings = layout.textSettings or {}
                            layout.textSettings.powerOffsetX = val
                            sArenaMixin:UpdateTextPositions(layout.textSettings, info, val)
                        end,
                    },
                    powerOffsetY = {
                        order = 4,
                        name = L["Vertical"],
                        type = "range",
                        softMin = -200,
                        softMax = 200,
                        step = 0.5,
                        width = 0.8,
                        get = function(info)
                            local layout = info.handler.db.profile.layoutSettings[layoutName]
                            layout.textSettings = layout.textSettings or {}
                            return layout.textSettings.powerOffsetY or 0
                        end,
                        set = function(info, val)
                            local layout = info.handler.db.profile.layoutSettings[layoutName]
                            layout.textSettings = layout.textSettings or {}
                            layout.textSettings.powerOffsetY = val
                            sArenaMixin:UpdateTextPositions(layout.textSettings, info, val)
                        end,
                    },
                    resetPowerText = {
                        order = 5,
                        name = L["Reset"],
                        width = 0.4,
                        type = "execute",
                        func = function(info)
                            local layout = info.handler.db.profile.layoutSettings[layoutName]
                            local currentLayout = info.handler.layouts[layoutName]
                            local defaults = currentLayout.defaultSettings.textSettings
                            layout.textSettings = layout.textSettings or {}
                            layout.textSettings.powerAnchor = defaults.powerAnchor
                            layout.textSettings.powerSize = defaults.powerSize
                            layout.textSettings.powerOffsetX = defaults.powerOffsetX
                            layout.textSettings.powerOffsetY = defaults.powerOffsetY
                            sArenaMixin:UpdateTextPositions(layout.textSettings, info, nil)
                            LibStub("AceConfigRegistry-3.0"):NotifyChange("sArena")
                        end,
                    },
                },
            },
            specNameText = {
                order = 3,
                name = L["Text_SpecNameText"],
                type = "group",
                inline = true,
                args = {
                    specNameAnchor = {
                        order = 1,
                        name = L["Text_AnchorPoint"],
                        type = "select",
                        style = "dropdown",
                        width = 0.5,
                        values = {
                            ["LEFT"] = L["Direction_Left"],
                            ["CENTER"] = L["Direction_Center"],
                            ["RIGHT"] = L["Direction_Right"],
                        },
                        get = function(info)
                            local layout = info.handler.db.profile.layoutSettings[layoutName]
                            layout.textSettings = layout.textSettings or {}
                            return layout.textSettings.specNameAnchor or "CENTER"
                        end,
                        set = function(info, val)
                            local layout = info.handler.db.profile.layoutSettings[layoutName]
                            layout.textSettings = layout.textSettings or {}
                            layout.textSettings.specNameAnchor = val
                            sArenaMixin:UpdateTextPositions(layout.textSettings, info, val)
                        end,
                    },
                    specNameSize = {
                        order = 2,
                        name = L["Size"],
                        type = "range",
                        min = 0.05,
                        max = 5,
                        step = 0.01,
                        width = 0.8,
                        isPercent = true,
                        get = function(info)
                            local layout = info.handler.db.profile.layoutSettings[layoutName]
                            layout.textSettings = layout.textSettings or {}
                            return layout.textSettings.specNameSize or 1.0
                        end,
                        set = function(info, val)
                            local layout = info.handler.db.profile.layoutSettings[layoutName]
                            layout.textSettings = layout.textSettings or {}
                            layout.textSettings.specNameSize = val
                            sArenaMixin:UpdateTextPositions(layout.textSettings, info, val)
                        end,
                    },
                    specNameOffsetX = {
                        order = 3,
                        name = L["Horizontal"],
                        type = "range",
                        softMin = -200,
                        softMax = 200,
                        step = 0.5,
                        width = 0.8,
                        get = function(info)
                            local layout = info.handler.db.profile.layoutSettings[layoutName]
                            layout.textSettings = layout.textSettings or {}
                            return layout.textSettings.specNameOffsetX or 0
                        end,
                        set = function(info, val)
                            local layout = info.handler.db.profile.layoutSettings[layoutName]
                            layout.textSettings = layout.textSettings or {}
                            layout.textSettings.specNameOffsetX = val
                            sArenaMixin:UpdateTextPositions(layout.textSettings, info, val)
                        end,
                    },
                    specNameOffsetY = {
                        order = 4,
                        name = L["Vertical"],
                        type = "range",
                        softMin = -200,
                        softMax = 200,
                        step = 0.5,
                        width = 0.8,
                        get = function(info)
                            local layout = info.handler.db.profile.layoutSettings[layoutName]
                            layout.textSettings = layout.textSettings or {}
                            return layout.textSettings.specNameOffsetY or 0
                        end,
                        set = function(info, val)
                            local layout = info.handler.db.profile.layoutSettings[layoutName]
                            layout.textSettings = layout.textSettings or {}
                            layout.textSettings.specNameOffsetY = val
                            sArenaMixin:UpdateTextPositions(layout.textSettings, info, val)
                        end,
                    },
                    resetSpecNameText = {
                        order = 5,
                        name = L["Reset"],
                        width = 0.4,
                        type = "execute",
                        func = function(info)
                            local layout = info.handler.db.profile.layoutSettings[layoutName]
                            local currentLayout = info.handler.layouts[layoutName]
                            local defaults = currentLayout.defaultSettings.textSettings
                            layout.textSettings = layout.textSettings or {}
                            layout.textSettings.specNameAnchor = defaults.specNameAnchor
                            layout.textSettings.specNameSize = defaults.specNameSize
                            layout.textSettings.specNameOffsetX = defaults.specNameOffsetX
                            layout.textSettings.specNameOffsetY = defaults.specNameOffsetY
                            sArenaMixin:UpdateTextPositions(layout.textSettings, info, nil)
                            LibStub("AceConfigRegistry-3.0"):NotifyChange("sArena")
                        end,
                    },
                },
            },
            castbarText = {
                order = 4,
                name = L["Text_CastbarText"],
                type = "group",
                inline = true,
                args = {
                    castbarAnchor = {
                        order = 1,
                        name = L["Text_AnchorPoint"],
                        type = "select",
                        style = "dropdown",
                        width = 0.5,
                        values = {
                            ["LEFT"] = L["Direction_Left"],
                            ["CENTER"] = L["Direction_Center"],
                            ["RIGHT"] = L["Direction_Right"],
                        },
                        get = function(info)
                            local layout = info.handler.db.profile.layoutSettings[layoutName]
                            layout.textSettings = layout.textSettings or {}
                            return layout.textSettings.castbarAnchor or "CENTER"
                        end,
                        set = function(info, val)
                            local layout = info.handler.db.profile.layoutSettings[layoutName]
                            layout.textSettings = layout.textSettings or {}
                            layout.textSettings.castbarAnchor = val
                            sArenaMixin:UpdateTextPositions(layout.textSettings, info, val)
                        end,
                    },
                    castbarSize = {
                        order = 2,
                        name = L["Size"],
                        type = "range",
                        min = 0.05,
                        max = 5,
                        step = 0.01,
                        width = 0.8,
                        isPercent = true,
                        get = function(info)
                            local layout = info.handler.db.profile.layoutSettings[layoutName]
                            layout.textSettings = layout.textSettings or {}
                            return layout.textSettings.castbarSize or 1.0
                        end,
                        set = function(info, val)
                            local layout = info.handler.db.profile.layoutSettings[layoutName]
                            layout.textSettings = layout.textSettings or {}
                            layout.textSettings.castbarSize = val
                            sArenaMixin:UpdateTextPositions(layout.textSettings, info, val)
                        end,
                    },
                    castbarOffsetX = {
                        order = 3,
                        name = L["Horizontal"],
                        type = "range",
                        softMin = -200,
                        softMax = 200,
                        step = 0.5,
                        width = 0.8,
                        get = function(info)
                            local layout = info.handler.db.profile.layoutSettings[layoutName]
                            layout.textSettings = layout.textSettings or {}
                            return layout.textSettings.castbarOffsetX or 0
                        end,
                        set = function(info, val)
                            local layout = info.handler.db.profile.layoutSettings[layoutName]
                            layout.textSettings = layout.textSettings or {}
                            layout.textSettings.castbarOffsetX = val
                            sArenaMixin:UpdateTextPositions(layout.textSettings, info, val)
                        end,
                    },
                    castbarOffsetY = {
                        order = 4,
                        name = L["Vertical"],
                        type = "range",
                        softMin = -200,
                        softMax = 200,
                        step = 0.5,
                        width = 0.8,
                        get = function(info)
                            local layout = info.handler.db.profile.layoutSettings[layoutName]
                            layout.textSettings = layout.textSettings or {}
                            return layout.textSettings.castbarOffsetY or 0
                        end,
                        set = function(info, val)
                            local layout = info.handler.db.profile.layoutSettings[layoutName]
                            layout.textSettings = layout.textSettings or {}
                            layout.textSettings.castbarOffsetY = val
                            sArenaMixin:UpdateTextPositions(layout.textSettings, info, val)
                        end,
                    },
                    resetCastbarText = {
                        order = 5,
                        name = L["Reset"],
                        width = 0.4,
                        type = "execute",
                        func = function(info)
                            local layout = info.handler.db.profile.layoutSettings[layoutName]
                            local currentLayout = info.handler.layouts[layoutName]
                            local defaults = currentLayout.defaultSettings.textSettings
                            layout.textSettings = layout.textSettings or {}
                            layout.textSettings.castbarAnchor = defaults.castbarAnchor
                            layout.textSettings.castbarSize = defaults.castbarSize
                            layout.textSettings.castbarOffsetX = defaults.castbarOffsetX
                            layout.textSettings.castbarOffsetY = defaults.castbarOffsetY
                            sArenaMixin:UpdateTextPositions(layout.textSettings, info, nil)
                            LibStub("AceConfigRegistry-3.0"):NotifyChange("sArena")
                        end,
                    },
                },
            },
            drText = {
                order = 5,
                name = L["Text_DRText"],
                type = "group",
                inline = true,
                args = {
                    drTextAnchor = {
                        order = 1,
                        name = L["Text_AnchorPoint"],
                        type = "select",
                        style = "dropdown",
                        width = 0.5,
                        values = {
                            ["TOPLEFT"] = L["Direction_TopLeft"],
                            ["TOP"] = L["Direction_Top"],
                            ["TOPRIGHT"] = L["Direction_TopRight"],
                            ["LEFT"] = L["Direction_Left"],
                            ["CENTER"] = L["Direction_Center"],
                            ["RIGHT"] = L["Direction_Right"],
                            ["BOTTOMLEFT"] = L["Direction_BottomLeft"],
                            ["BOTTOM"] = L["Direction_Bottom"],
                            ["BOTTOMRIGHT"] = L["Direction_BottomRight"],
                        },
                        get = function(info)
                            local layout = info.handler.db.profile.layoutSettings[layoutName]
                            layout.textSettings = layout.textSettings or {}
                            return layout.textSettings.drTextAnchor or "BOTTOMRIGHT"
                        end,
                        set = function(info, val)
                            local layout = info.handler.db.profile.layoutSettings[layoutName]
                            layout.textSettings = layout.textSettings or {}
                            layout.textSettings.drTextAnchor = val
                            sArenaMixin:UpdateDRTextPositions(layout.textSettings, info, val)
                        end,
                    },
                    drTextSize = {
                        order = 2,
                        name = L["Scale"],
                        type = "range",
                        min = 0.5,
                        max = 3,
                        step = 0.01,
                        width = 0.8,
                        isPercent = true,
                        get = function(info)
                            local layout = info.handler.db.profile.layoutSettings[layoutName]
                            layout.textSettings = layout.textSettings or {}
                            return layout.textSettings.drTextSize or 1.0
                        end,
                        set = function(info, val)
                            local layout = info.handler.db.profile.layoutSettings[layoutName]
                            layout.textSettings = layout.textSettings or {}
                            layout.textSettings.drTextSize = val
                            sArenaMixin:UpdateDRTextPositions(layout.textSettings, info, val)
                        end,
                    },
                    drTextOffsetX = {
                        order = 3,
                        name = L["Horizontal"],
                        type = "range",
                        softMin = -50,
                        softMax = 50,
                        step = 0.5,
                        width = 0.8,
                        get = function(info)
                            local layout = info.handler.db.profile.layoutSettings[layoutName]
                            layout.textSettings = layout.textSettings or {}
                            return layout.textSettings.drTextOffsetX or 4
                        end,
                        set = function(info, val)
                            local layout = info.handler.db.profile.layoutSettings[layoutName]
                            layout.textSettings = layout.textSettings or {}
                            layout.textSettings.drTextOffsetX = val
                            sArenaMixin:UpdateDRTextPositions(layout.textSettings, info, val)
                        end,
                    },
                    drTextOffsetY = {
                        order = 4,
                        name = L["Vertical"],
                        type = "range",
                        softMin = -50,
                        softMax = 50,
                        step = 0.5,
                        width = 0.8,
                        get = function(info)
                            local layout = info.handler.db.profile.layoutSettings[layoutName]
                            layout.textSettings = layout.textSettings or {}
                            return layout.textSettings.drTextOffsetY or -4
                        end,
                        set = function(info, val)
                            local layout = info.handler.db.profile.layoutSettings[layoutName]
                            layout.textSettings = layout.textSettings or {}
                            layout.textSettings.drTextOffsetY = val
                            sArenaMixin:UpdateDRTextPositions(layout.textSettings, info, val)
                        end,
                    },
                    resetDRText = {
                        order = 5,
                        name = L["Reset"],
                        width = 0.4,
                        type = "execute",
                        func = function(info)
                            local layout = info.handler.db.profile.layoutSettings[layoutName]
                            local currentLayout = info.handler.layouts[layoutName]
                            local defaults = currentLayout.defaultSettings.textSettings
                            layout.textSettings = layout.textSettings or {}
                            layout.textSettings.drTextAnchor = defaults.drTextAnchor or "BOTTOMRIGHT"
                            layout.textSettings.drTextSize = defaults.drTextSize or 1.0
                            layout.textSettings.drTextOffsetX = defaults.drTextOffsetX or 4
                            layout.textSettings.drTextOffsetY = defaults.drTextOffsetY or -4
                            sArenaMixin:UpdateDRTextPositions(layout.textSettings, info, nil)
                            LibStub("AceConfigRegistry-3.0"):NotifyChange("sArena")
                        end,
                    },
                },
            },
        },
    }

    return optionsTable
end

function sArenaMixin:UpdateFrameSettings(db, info, val)
    if (val) then
        db[info[#info]] = val
    end

    self:ClearAllPoints()
    self:SetPoint("CENTER", UIParent, "CENTER", db.posX, db.posY)
    self:SetScale(db.scale)

    local growthDirection = db.growthDirection
    local spacing = db.spacing
    local layoutCF = (self.layoutdb and self.layoutdb.changeFont)

    for i = 1, sArenaMixin.maxArenaOpponents do
        local text = self["arena" .. i].ClassIcon.Cooldown.Text
        local fontToUse = text.fontFile
        if layoutCF then
            fontToUse = LSM:Fetch(LSM.MediaType.FONT, self.layoutdb.cdFont)
        end
        text:SetFont(fontToUse, db.classIconFontSize, "OUTLINE")
        local sArenaText = self["arena" .. i].ClassIcon.Cooldown.sArenaText
        if sArenaText then
            sArenaText:SetFont(fontToUse, db.classIconFontSize, "OUTLINE")
        end
    end

    for i = 2, sArenaMixin.maxArenaOpponents do
        local frame = self["arena" .. i]
        local prevFrame = self["arena" .. i - 1]

        frame:ClearAllPoints()
        if (growthDirection == 1) then
            frame:SetPoint("TOP", prevFrame, "BOTTOM", 0, -spacing)
        elseif (growthDirection == 2) then
            frame:SetPoint("BOTTOM", prevFrame, "TOP", 0, spacing)
        elseif (growthDirection == 3) then
            frame:SetPoint("LEFT", prevFrame, "RIGHT", spacing, 0)
        elseif (growthDirection == 4) then
            frame:SetPoint("RIGHT", prevFrame, "LEFT", -spacing, 0)
        end
    end
end

function sArenaMixin:UpdateCastBarSettings(db, info, val)
    if (val) then
        db[info[#info]] = val
    end

    for i = 1, sArenaMixin.maxArenaOpponents do
        local frame = self["arena" .. i]

        frame.CastBar:ClearAllPoints()
        frame.CastBar:SetPoint("CENTER", frame, "CENTER", db.posX, db.posY)

        frame.CastBar.Icon:ClearAllPoints()
        if isRetail then
            frame.CastBar.Icon:SetPoint("RIGHT", frame.CastBar, "LEFT", -5 + (db.iconPosX or 0), (db.iconPosY or 0) + (db.useModernCastbars and -4.5 or 0))
        else
            frame.CastBar.Icon:SetPoint("RIGHT", frame.CastBar, "LEFT", -5 + (db.iconPosX or 0), (db.iconPosY or 0) + (db.useModernCastbars and -5.5 or 0))
        end

        frame.CastBar:SetScale(db.scale)
        frame.CastBar:SetWidth(db.width)
        frame.CastBar.BorderShield:ClearAllPoints()
        if db.useModernCastbars then
            if isRetail then
                frame.CastBar.BorderShield:SetAtlas("UI-CastingBar-Shield")
                frame.CastBar.BorderShield:SetPoint("CENTER", frame.CastBar.Icon, "CENTER", -0.2, -3)
                frame.CastBar.BorderShield:SetSize(30, 34)
            else
                frame.CastBar.BorderShield:SetTexture("Interface\\AddOns\\sArena_Reloaded\\Textures\\UI-CastingBar-Shield.tga")
                frame.CastBar.BorderShield:SetPoint("CENTER", frame.CastBar.Icon, "CENTER", 0, -3)
                frame.CastBar.BorderShield:SetSize(49, 47)
            end
        else
            frame.CastBar.BorderShield:SetTexture(330124)
            frame.CastBar.BorderShield:SetSize(48, 48)
            frame.CastBar.BorderShield:SetPoint("CENTER", frame.CastBar.Icon, "CENTER", 9, -1)
        end

        if db.hideBorderShield then
            frame.CastBar.BorderShield:SetTexture(nil)
        end

        if db.hideCastbarSpark then
            frame.CastBar.Spark:SetAlpha(0)
        else
            frame.CastBar.Spark:SetAlpha(1)
        end

        if db.hideCastbarIcon then
            frame.CastBar.Icon:SetAlpha(0)
            frame.CastBar.BorderShield:SetAlpha(0)
        else
            frame.CastBar.Icon:SetAlpha(1)
            frame.CastBar.BorderShield:SetAlpha(1)
        end

        frame.CastBar.Icon:SetDrawLayer("OVERLAY", 7)
        frame.CastBar.BorderShield:SetDrawLayer("OVERLAY", 6)

        frame.CastBar.BorderShield:SetScale(db.iconScale or 1)
        frame.CastBar.Icon:SetScale(db.iconScale or 1)
    end

    self:UpdateCastBarPixelBorders()
end

function sArenaMixin:UpdateCastBarPixelBorders()
    local currentLayout = self.db and self.db.profile and self.db.profile.currentLayout
    local isPixelBorderLayout = (currentLayout == "Pixelated" or currentLayout == "BlizzRaid")
    local layoutSettings = self.db and self.db.profile and self.db.profile.layoutSettings and self.db.profile.layoutSettings[currentLayout]
    local cropIcons = layoutSettings and layoutSettings.cropIcons or false
    local useModernCastbars = layoutSettings and layoutSettings.castBar and layoutSettings.castBar.useModernCastbars or false

    for i = 1, sArenaMixin.maxArenaOpponents do
        local frame = self["arena" .. i]

        if frame.CastBar.castBar then
            if isPixelBorderLayout and not useModernCastbars then
                frame.CastBar.castBar:Show()
            else
                frame.CastBar.castBar:Hide()
            end
        end

        if frame.CastBar.castBarIcon then
            if isPixelBorderLayout and not useModernCastbars then
                frame.CastBar.castBarIcon:Show()
            else
                frame.CastBar.castBarIcon:Hide()
            end
        end

        local shouldCrop = isPixelBorderLayout or cropIcons
        frame:SetTextureCrop(frame.CastBar.Icon, shouldCrop)
    end
end

function sArenaMixin:UpdateCastbarColors()
    local currentLayout = self.db and self.db.profile and self.db.profile.currentLayout
    local layoutSettings = self.db and self.db.profile and self.db.profile.layoutSettings and self.db.profile.layoutSettings[currentLayout]
    local recolorEnabled = layoutSettings and layoutSettings.castBar and layoutSettings.castBar.recolorCastbar
    local interruptStatusColorOn = layoutSettings and layoutSettings.castBar and layoutSettings.castBar.interruptStatusColorOn
    local colors = self.db and self.db.profile and self.db.profile.castBarColors

    if layoutSettings then
        sArenaMixin.interruptStatusColorOn = interruptStatusColorOn
    end

    local defaultStandard = { 1.0, 0.7, 0.0, 1 }
    local defaultChannel = { 0.0, 1.0, 0.0, 1 }
    local defaultUninterruptable = { 0.7, 0.7, 0.7, 1 }
    local defaultInterruptNotReady = { 1.0, 0.0, 0.0, 1 }

    if colors then
        local standardColor = colors.standard or defaultStandard
        local channelColor = colors.channel or defaultChannel
        local uninterruptableColor = colors.uninterruptable or defaultUninterruptable
        local interruptNotReadyColor = colors.interruptNotReady or defaultInterruptNotReady

        -- Update the colors in ModernCastbar.lua's actionColors table
        sArenaMixin.castbarColors = {
            enabled = recolorEnabled,
            standard = standardColor,
            channel = channelColor,
            uninterruptable = uninterruptableColor,
            interruptNotReady = interruptNotReadyColor,
        }
    end

    -- Update MoP castbar colors for already-created castbars
    if sArenaMixin.isMoP and self.UpdateMoPCastbarColors then
        self:UpdateMoPCastbarColors()
    end
end

function sArenaMixin:RefreshTestModeCastbars()
    for i = 1, self.maxArenaOpponents do
        local frame = self["arena" .. i]
        if frame and frame.tempCast and frame.CastBar:IsShown() then
            local db = self.db
            local layout = db.profile.layoutSettings[db.profile.currentLayout]
            local recolorEnabled = layout and layout.castBar and layout.castBar.recolorCastbar
            local colors = db.profile.castBarColors
            local barTexture = frame.CastBar:GetStatusBarTexture()
            local useModernCastbars = layout and layout.castBar and layout.castBar.useModernCastbars
            local keepDefaultModernTextures = layout and layout.castBar and layout.castBar.keepDefaultModernTextures

            -- Update texture based on cast type
            if not (useModernCastbars and keepDefaultModernTextures) then
                local texKeys = layout.textures or {
                    generalStatusBarTexture = "sArena Default",
                    healStatusBarTexture    = "sArena Default",
                    castbarStatusBarTexture = "sArena Default",
                    castbarUninterruptibleTexture = "sArena Default",
                }

                local castPath
                if frame.tempUninterruptible then
                    castPath = LSM:Fetch(LSM.MediaType.STATUSBAR, texKeys.castbarUninterruptibleTexture or texKeys.castbarStatusBarTexture)
                else
                    castPath = LSM:Fetch(LSM.MediaType.STATUSBAR, texKeys.castbarStatusBarTexture)
                end
                frame.CastBar:SetStatusBarTexture(castPath)
            end

            if recolorEnabled and colors then
                if frame.CastBar.BorderShield:IsShown() then
                    frame.CastBar:SetStatusBarColor(unpack(colors.uninterruptable or {0.7, 0.7, 0.7, 1}))
                elseif frame.tempChannel then
                    frame.CastBar:SetStatusBarColor(unpack(colors.channel or {0.0, 1.0, 0.0, 1}))
                else
                    frame.CastBar:SetStatusBarColor(unpack(colors.standard or {1.0, 0.7, 0.0, 1}))
                end
                barTexture:SetDesaturated(true)
            else
                if useModernCastbars and keepDefaultModernTextures then
                    barTexture:SetDesaturated(false)
                    frame.CastBar:SetStatusBarColor(1, 1, 1)
                else
                    if frame.CastBar.BorderShield:IsShown() then
                        frame.CastBar:SetStatusBarColor(0.7, 0.7, 0.7, 1)
                    elseif frame.tempChannel then
                        frame.CastBar:SetStatusBarColor(0, 1, 0, 1)
                    else
                        frame.CastBar:SetStatusBarColor(1, 0.7, 0, 1)
                    end
                end
            end
        end
    end
end

local function CreatePixelTextureBorder(parent, target, key, size, offset)
    offset = offset or 0
    size = size or 1

    if not parent[key] then
        local holder = CreateFrame("Frame", nil, parent)
        holder:SetIgnoreParentScale(true)
        parent[key] = holder

        local edges = {}
        for i = 1, 4 do
            local tex = holder:CreateTexture(nil, "BORDER", nil, 7)
            tex:SetColorTexture(0,0,0,1)
            tex:SetIgnoreParentScale(true)
            edges[i] = tex
        end
        holder.edges = edges

        function holder:SetVertexColor(r, g, b, a)
            for _, tex in ipairs(self.edges) do
                tex:SetColorTexture(r, g, b, a or 1)
            end
        end
    end

    local holder = parent[key]
    local edges = holder.edges

    local spacing = offset

    holder:ClearAllPoints()
    holder:SetPoint("TOPLEFT", target, "TOPLEFT", -spacing - size, spacing + size)
    holder:SetPoint("BOTTOMRIGHT", target, "BOTTOMRIGHT", spacing + size, -spacing - size)

    -- Top
    edges[1]:ClearAllPoints()
    edges[1]:SetPoint("TOPLEFT", holder, "TOPLEFT")
    edges[1]:SetPoint("TOPRIGHT", holder, "TOPRIGHT")
    edges[1]:SetHeight(size)

    -- Right
    edges[2]:ClearAllPoints()
    edges[2]:SetPoint("TOPRIGHT", holder, "TOPRIGHT")
    edges[2]:SetPoint("BOTTOMRIGHT", holder, "BOTTOMRIGHT")
    edges[2]:SetWidth(size)

    -- Bottom
    edges[3]:ClearAllPoints()
    edges[3]:SetPoint("BOTTOMLEFT", holder, "BOTTOMLEFT")
    edges[3]:SetPoint("BOTTOMRIGHT", holder, "BOTTOMRIGHT")
    edges[3]:SetHeight(size)

    -- Left
    edges[4]:ClearAllPoints()
    edges[4]:SetPoint("TOPLEFT", holder, "TOPLEFT")
    edges[4]:SetPoint("BOTTOMLEFT", holder, "BOTTOMLEFT")
    edges[4]:SetWidth(size)

    holder:Show()
end

-- Initialize DR frames for Midnight
function sArenaMixin:InitializeDRFrames()
    if not sArenaMixin.isMidnight then return end

    if EditModeManagerFrame and EditModeManagerFrame.AccountSettings then
        ShowUIPanel(EditModeManagerFrame)
    end

    local layoutdb = self.db.profile.layoutSettings[self.db.profile.currentLayout]
    local growthDirection = layoutdb.dr.growthDirection

    for i = 1, sArenaMixin.maxArenaOpponents do
        local blizzArenaFrame = _G["CompactArenaFrameMember" .. i]
        local arenaFrame = self["arena" .. i]

        if not blizzArenaFrame or not arenaFrame then return end

        -- Initialize DR frames from Blizzard's SpellDiminishStatusTray
        local drTray = blizzArenaFrame.SpellDiminishStatusTray
        if not drTray then return end

        drTray:SetParent(arenaFrame)
        arenaFrame.drTray = drTray
        drTray:SetFrameStrata("MEDIUM")
        drTray:SetFrameLevel(10)
        drTray:EnableMouse(false)
        drTray:SetMouseClickEnabled(false)
        --local arenaExtraOffset = 0
        -- if inArena then
        --     -- If reloaded in arena the DR frames are secrets and can't be adjusted.
        --     -- Instead we mimic the users settings the best we can using only the parent frame.
        --     drTray:SetScale(1.2)
        --     arenaExtraOffset = 20
        --     sArenaMixin.launchedDuringArena = true
        -- end
        drTray:ClearAllPoints()
        local offset = ((sArenaMixin.drBaseSize or 28) / 2)-- + arenaExtraOffset

        local anchorPoint
        if (growthDirection == 4) then
            anchorPoint = "RIGHT"
        elseif (growthDirection == 3) then
            anchorPoint = "LEFT"
        elseif (growthDirection == 1) then
            anchorPoint = "RIGHT"
        elseif (growthDirection == 2) then
            anchorPoint = "RIGHT"
        end
        drTray:SetPoint(anchorPoint, arenaFrame, "CENTER", layoutdb.dr.posX + offset, layoutdb.dr.posY)

        -- Get the 4 DR frames from the tray
        local drFrames = {drTray:GetChildren()}
        arenaFrame.drFrames = drFrames

        -- Initialize each DR frame with custom borders
        for drIndex, drFrame in ipairs(drFrames) do
            if drFrame and drFrame.Icon then
                drFrame:SetFrameStrata("MEDIUM")
                drFrame:SetFrameLevel(11)
                drFrame:SetAlpha(1)
                drFrame:Show()
                drFrame.Icon:Show()
                drFrame:EnableMouse(false)
                drFrame:SetMouseClickEnabled(false)

                -- Create border for active DR (will be styled by UpdateDRSettings)
                if not drFrame.Border then
                    drFrame.Border = drFrame:CreateTexture(nil, "OVERLAY", nil, 6)
                    drFrame.Border:SetTexture("Interface\\Buttons\\UI-Quickslot-Depress")
                    drFrame.Border:SetAllPoints(drFrame)
                    drFrame.Border:SetVertexColor(0,1,0)

                    drFrame.ImmunityIndicator:SetFrameStrata("MEDIUM")
                    drFrame.ImmunityIndicator:SetFrameLevel(27)

                    drFrame.BorderImmune = drFrame:CreateTexture(nil, "OVERLAY", nil, 7)
                    drFrame.BorderImmune:SetTexture("Interface\\Buttons\\UI-Quickslot-Depress")
                    drFrame.BorderImmune:SetAllPoints(drFrame)
                    drFrame.BorderImmune:SetIgnoreParentAlpha(true)
                    drFrame.BorderImmune:SetVertexColor(1,0,0,1)
                    hooksecurefunc(drFrame.Border, "SetTexture", function(self, texture)
                        drFrame.BorderImmune:SetTexture(texture)
                    end)
                end

                if not drFrame.DRTextFrame then
                    drFrame.DRTextFrame = CreateFrame("Frame", nil, drFrame)
                    drFrame.DRTextFrame:SetAllPoints(drFrame)
                    drFrame.DRTextFrame:SetFrameStrata("MEDIUM")
                    drFrame.DRTextFrame:SetFrameLevel(26)

                    local textSettings = layoutdb.textSettings or {}
                    local drTextAnchor = textSettings.drTextAnchor or "BOTTOMRIGHT"
                    local drTextSize = textSettings.drTextSize or 1.0
                    local drTextOffsetX = textSettings.drTextOffsetX or 4
                    local drTextOffsetY = textSettings.drTextOffsetY or -4

                    drFrame.DRText = drFrame.DRTextFrame:CreateFontString(nil, "OVERLAY", "GameFontNormalLarge")
                    drFrame.DRText:SetPoint(drTextAnchor, drTextOffsetX, drTextOffsetY)
                    drFrame.DRText:SetFont("Interface\\AddOns\\sArena_Reloaded\\Textures\\arialn.ttf", 14, "OUTLINE")
                    drFrame.DRText:SetScale(drTextSize)
                    drFrame.DRText:SetTextColor(0, 1, 0)
                    drFrame.DRText:SetText("½")

                    local green = CreateColor(0, 1, 0, 1)
                    local red = CreateColor(1, 0, 0, 1)

                    if not drFrame.Cooldown.Text then
                        drFrame.Cooldown.Text = drFrame.Cooldown:GetCountdownFontString()
                        drFrame.Cooldown.Text.fontFile = drFrame.Cooldown.Text:GetFont()
                    end

                    hooksecurefunc(drFrame.ImmunityIndicator, "SetShown", function(immunityIndicator, SetShown)
                        drFrame.Border:SetAlphaFromBoolean(SetShown, 0, 1)
                        drFrame.DRText:SetAlphaFromBoolean(SetShown, 0, 1)

                        if self.db and self.db.profile.colorDRCooldownText then
                            drFrame.Cooldown.sArenaText:SetVertexColorFromBoolean(SetShown, red, green)
                        end
                    end)

                    drFrame.DRText2 = drFrame.DRTextFrame:CreateFontString(nil, "OVERLAY", "GameFontNormalLarge")
                    drFrame.DRText2:SetPoint(drTextAnchor, drTextOffsetX, drTextOffsetY)
                    drFrame.DRText2:SetFont("Interface\\AddOns\\sArena_Reloaded\\Textures\\arialn.ttf", 14, "OUTLINE")
                    drFrame.DRText2:SetScale(drTextSize)
                    drFrame.DRText2:SetTextColor(1, 0, 0)
                    drFrame.DRText2:SetText("%")
                    drFrame.DRText2:SetParent(drFrame.ImmunityIndicator)
                    drFrame.DRText2:SetIgnoreParentAlpha(true)
                    drFrame.DRText2:SetAlpha(1)

                end

                if not drFrame.Boverlay then
                    drFrame.Boverlay = CreateFrame("Frame", nil, drFrame)
                    drFrame.Boverlay:SetFrameStrata("MEDIUM")
                    drFrame.Boverlay:SetFrameLevel(26)
                end
                drFrame.Boverlay:Show()
                drFrame.Border:SetParent(drFrame.Boverlay)
                drFrame.BorderImmune:SetParent(drFrame.ImmunityIndicator)
                drFrame.ImmunityIndicator:SetAlpha(0)

                -- Border color will be set by UpdateDRSettings
                drFrame.Border:Show()
                if not drFrame.Cooldown then
                    drFrame.Cooldown = drFrame.Icon
                end
            end
        end
    end

    -- Apply DR settings after all frames are initialized
    if self.layoutdb and self.layoutdb.dr then
        self:UpdateDRSettings(self.layoutdb.dr)
    end


    if EditModeManagerFrame and EditModeManagerFrame.AccountSettings then
        HideUIPanel(EditModeManagerFrame)
    end

end

function sArenaMixin:UpdateDRSettings(db, info, val)
    -- Early return if db is nil or frames aren't ready
    if not db then return end

    if (val) then
        db[info[#info]] = val
    end

    local layoutCF = (self.layoutdb and self.layoutdb.changeFont)

    -- For Midnight: full DR settings support with new frame structure
    if sArenaMixin.isMidnight then
        sArenaMixin.drBaseSize = db.size or 28
        local currentLayout = self.db and self.db.profile and self.db.profile.currentLayout
        local layoutSettings = self.db and self.db.profile and self.db.profile.layoutSettings and self.db.profile.layoutSettings[currentLayout]
        local cropIcons = layoutSettings and layoutSettings.cropIcons or false
        
        for i = 1, sArenaMixin.maxArenaOpponents do
            local frame = self["arena" .. i]
            -- Handle DR swipe settings (global setting) - defined here for both real and fake frames
            local disableSwipeEdge = self.db.profile.disableSwipeEdge
            local disableDRSwipe = self.db.profile.disableDRSwipe
            local reverseDR = self.db.profile.invertDRCooldown

            -- Settings for positioning
            local growthDirection = db.growthDirection or 4
            local spacing = db.spacing or 3
            local size = db.size or 28

            if frame and frame.drFrames then
                -- Get Blizzard's DR tray for positioning
                local blizzArenaFrame = _G["CompactArenaFrameMember" .. i]
                local drTray = blizzArenaFrame and blizzArenaFrame.SpellDiminishStatusTray

                if drTray then
                    -- Position the tray
                    --local arenaScale = 0.05143 * size - 0.24
                    local arenaOffset = 0--2.43 * size - 52
                    -- local _, instanceType = IsInInstance()
                    -- local inArena = (instanceType == "arena")
                    -- if inArena then
                    --     -- If reloaded in arena the DR frames are secrets and can't be adjusted.
                    --     -- Instead we mimic the users settings the best we can using only the parent frame.
                    --     drTray:SetScale(arenaScale) -- 1.2 == 28 size, 1.56 == 35 size.
                    --     -- For default settings, aka 28 size. We need to do SetScale(1.2) and offset by 15.
                    --     -- For 35 size, we do SetScale(1.56) and offset by 32.
                    --     sArenaMixin.launchedDuringArena = true
                    -- end

                    local anchorPoint
                    if (growthDirection == 4) then
                        anchorPoint = "RIGHT"
                    elseif (growthDirection == 3) then
                        anchorPoint = "LEFT"
                    elseif (growthDirection == 1) then
                        anchorPoint = "RIGHT"
                    elseif (growthDirection == 2) then
                        anchorPoint = "RIGHT"
                    end
                    drTray:ClearAllPoints()
                    local offset = ((sArenaMixin.drBaseSize or 28) / 2) + (sArenaMixin.launchedDuringArena and arenaOffset or 0)
                    drTray:SetPoint(anchorPoint, frame, "CENTER", db.posX + offset, db.posY)
                end

                for drIndex, drFrame in ipairs(frame.drFrames) do
                    if drFrame then
                        -- Set size
                        drFrame:SetSize(size, size)

                        local text = drFrame.Cooldown.Text
                        local fontToUse = text.fontFile
                        if layoutCF then
                            fontToUse = LSM:Fetch(LSM.MediaType.FONT, self.layoutdb.cdFont)
                        end
                        text:SetFont(fontToUse, db.fontSize, "OUTLINE")
                        local sArenaText = drFrame.Cooldown.sArenaText
                        if sArenaText then
                            sArenaText:SetFont(fontToUse, db.fontSize, "OUTLINE")
                        end

                        -- Position based on growth direction
                        -- drFrame:ClearAllPoints()
                        -- if drIndex == 1 then
                        --     -- First frame anchors to the tray
                        --     if drTray then
                        --         drFrame:SetPoint("CENTER", drTray, "CENTER", 0, 0)
                        --     end
                        -- else
                        --     -- Subsequent frames position relative to previous frame
                        --     local prevFrame = frame.drFrames[drIndex - 1]
                        --     if prevFrame then
                        --         if growthDirection == 1 then
                        --             -- Down
                        --             drFrame:SetPoint("TOP", prevFrame, "BOTTOM", 0, -spacing)
                        --         elseif growthDirection == 2 then
                        --             -- Up
                        --             drFrame:SetPoint("BOTTOM", prevFrame, "TOP", 0, spacing)
                        --         elseif growthDirection == 3 then
                        --             -- Right
                        --             drFrame:SetPoint("LEFT", prevFrame, "RIGHT", spacing, 0)
                        --         elseif growthDirection == 4 then
                        --             -- Left (default)
                        --             drFrame:SetPoint("RIGHT", prevFrame, "LEFT", -spacing, 0)
                        --         end
                        --     end
                        -- end

                        -- Handle swipe/edge settings if Cooldown exists
                        if drFrame.Cooldown then
                            drFrame.Cooldown:SetReverse(reverseDR)
                            if disableDRSwipe then
                                drFrame.Cooldown:SetDrawSwipe(false)
                                drFrame.Cooldown:SetDrawEdge(false)
                            else
                                drFrame.Cooldown:SetSwipeColor(0, 0, 0, 0.55)
                                drFrame.Cooldown:SetDrawSwipe(true)
                                drFrame.Cooldown:SetDrawEdge(not disableSwipeEdge)
                            end
                        end

                        -- Reset states before applying new styles
                        if drFrame.Icon then
                            drFrame.Icon:SetDrawLayer("ARTWORK", 0)
                        end
                        if drFrame.Boverlay then
                            drFrame.Border:SetParent(drFrame)
                            drFrame.Boverlay:Hide()
                        end
                        if drFrame.Mask and drFrame.Icon then
                            drFrame.Icon:RemoveMaskTexture(drFrame.Mask)
                        end
                        if drFrame.PixelBorder then
                            drFrame.PixelBorder:Hide()
                        end
                        if drFrame.PixelBorderImmune then
                            drFrame.PixelBorderImmune:Hide()
                        end

                        -- Apply border styles
                        if db.disableDRBorder then
                            if drFrame.Border then
                                drFrame.Border:Hide()
                            end
                            if drFrame.BorderImmune then
                                drFrame.BorderImmune:Hide()
                            end
                            if drFrame.PixelBorder then
                                drFrame.PixelBorder:Hide()
                            end
                            if drFrame.PixelBorderImmune then
                                drFrame.PixelBorderImmune:Hide()
                            end
                            if drFrame.Icon then
                                if cropIcons then
                                    drFrame.Icon:SetTexCoord(0.08, 0.92, 0.08, 0.92)
                                else
                                    drFrame.Icon:SetTexCoord(0, 1, 0, 1)
                                end
                            end
                            if drFrame.Cooldown then
                                drFrame.Cooldown:SetSwipeTexture(1)
                            end

                        elseif db.thinPixelBorder then
                            -- Thin pixel border style
                            if drFrame.Border then
                                drFrame.Border:Show()
                                drFrame.Border:SetAtlas("communities-create-avatar-border-selected")
                            end
                            if drFrame.BorderImmune then
                                drFrame.BorderImmune:Show()
                                drFrame.BorderImmune:SetAtlas("communities-create-avatar-border-selected")
                            end
                            if drFrame.PixelBorder then
                                drFrame.PixelBorder:Hide()
                            end
                            if drFrame.PixelBorderImmune then
                                drFrame.PixelBorderImmune:Hide()
                            end
                            if drFrame.Icon then
                                drFrame.Icon:SetTexCoord(0.05, 0.95, 0.07, 0.9)
                            end
                            if drFrame.Cooldown then
                                drFrame.Cooldown:SetSwipeTexture(1)
                            end

                        elseif db.thickPixelBorder then
                            -- Thick pixel border style with dual borders (green/red)
                            if drFrame.Border then
                                drFrame.Border:Hide()
                            end
                            if drFrame.BorderImmune then
                                drFrame.BorderImmune:Hide()
                            end
                            local drSize = 2

                            -- Create green border (active DR)
                            CreatePixelTextureBorder(drFrame, drFrame, "PixelBorder", drSize, 0)
                            drFrame.PixelBorder:Show()

                            -- Create red border (immune) - parent to ImmunityIndicator
                            if not drFrame.PixelBorderImmune then
                                CreatePixelTextureBorder(drFrame, drFrame, "PixelBorderImmune", drSize, 0)
                                drFrame.PixelBorderImmune:SetParent(drFrame.ImmunityIndicator)
                                drFrame.PixelBorderImmune:SetIgnoreParentAlpha(true)
                                -- Hook to keep both borders in sync when positioning
                                hooksecurefunc(drFrame.PixelBorder, "ClearAllPoints", function()
                                    if drFrame.PixelBorderImmune then
                                        drFrame.PixelBorderImmune:ClearAllPoints()
                                        drFrame.PixelBorderImmune:SetPoint("TOPLEFT", drFrame, "TOPLEFT", -drSize, drSize)
                                        drFrame.PixelBorderImmune:SetPoint("BOTTOMRIGHT", drFrame, "BOTTOMRIGHT", drSize, -drSize)
                                    end
                                end)
                            end
                            drFrame.PixelBorderImmune:Show()

                            if db.blackDRBorder then
                                drFrame.PixelBorder:SetVertexColor(0, 0, 0, 1)
                                drFrame.PixelBorderImmune:SetVertexColor(0, 0, 0, 1)
                            else
                                drFrame.PixelBorder:SetVertexColor(0, 1, 0, 1)
                                drFrame.PixelBorderImmune:SetVertexColor(1, 0, 0, 1)
                            end
                            if drFrame.Icon then
                                drFrame.Icon:SetTexCoord(0.08, 0.92, 0.08, 0.92)
                            end
                            if drFrame.Cooldown then
                                drFrame.Cooldown:SetSwipeTexture(1)
                            end

                        elseif db.drBorderGlowOff then
                            -- Square border with cut corners (no glow)
                            if drFrame.Border then
                                drFrame.Border:Show()
                                drFrame.Border:SetTexture("Interface\\Buttons\\UI-Quickslot-Depress")

                                -- Set border color
                                if db.blackDRBorder then
                                    drFrame.Border:SetVertexColor(0, 0, 0, 1)
                                    drFrame.BorderImmune:SetVertexColor(0, 0, 0, 1)
                                else
                                    drFrame.Border:SetVertexColor(0, 1, 0, 1)
                                    drFrame.BorderImmune:SetVertexColor(1, 0, 0, 1)
                                end
                            end
                            if drFrame.BorderImmune then
                                drFrame.BorderImmune:Show()
                                drFrame.BorderImmune:SetTexture("Interface\\Buttons\\UI-Quickslot-Depress")
                            end
                            if drFrame.PixelBorder then
                                drFrame.PixelBorder:Hide()
                            end
                            if drFrame.PixelBorderImmune then
                                drFrame.PixelBorderImmune:Hide()
                            end
                            if not drFrame.Mask then
                                drFrame.Mask = drFrame:CreateMaskTexture()
                            end
                            drFrame.Mask:SetPoint("TOPLEFT", drFrame.Icon, "TOPLEFT", 0.5, -0.5)
                            drFrame.Mask:SetPoint("BOTTOMRIGHT", drFrame.Icon, "BOTTOMRIGHT", -0.5, 0.5)
                            if drFrame.Cooldown then
                                drFrame.Cooldown:SetSwipeTexture("Interface\\AddOns\\sArena_Reloaded\\Textures\\squarecutcornermask")
                            end
                            drFrame.Mask:SetTexture("Interface\\AddOns\\sArena_Reloaded\\Textures\\squarecutcornermask", "CLAMPTOBLACKADDITIVE", "CLAMPTOBLACKADDITIVE")
                            if drFrame.Icon then
                                drFrame.Icon:SetDrawLayer("OVERLAY", 7)
                                drFrame.Icon:SetTexCoord(0.05, 0.95, 0.05, 0.9)
                                drFrame.Icon:AddMaskTexture(drFrame.Mask)
                            end

                            -- Set border size
                            local borderSize = 1.5
                            if drFrame.Border then
                                drFrame.Border:SetPoint("TOPLEFT", drFrame, "TOPLEFT", -borderSize, borderSize)
                                drFrame.Border:SetPoint("BOTTOMRIGHT", drFrame, "BOTTOMRIGHT", borderSize, -borderSize)
                                drFrame.BorderImmune:SetPoint("TOPLEFT", drFrame, "TOPLEFT", -borderSize, borderSize)
                                drFrame.BorderImmune:SetPoint("BOTTOMRIGHT", drFrame, "BOTTOMRIGHT", borderSize, -borderSize)
                            end

                        elseif db.brightDRBorder then
                            -- Bright/glow border style
                            if drFrame.Border then
                                drFrame.Border:Show()
                                drFrame.Border:SetTexture("Interface\\AddOns\\sArena_Reloaded\\Textures\\UI-HUD-ActionBar-PetAutoCast-Mask.tga")

                                -- Set border color
                                if db.blackDRBorder then
                                    drFrame.Border:SetVertexColor(0, 0, 0, 1)
                                    drFrame.BorderImmune:SetVertexColor(0, 0, 0, 1)
                                else
                                    drFrame.Border:SetVertexColor(0, 1, 0, 1)
                                    drFrame.BorderImmune:SetVertexColor(1, 0, 0, 1)
                                end
                            end
                            if drFrame.BorderImmune then
                                drFrame.BorderImmune:Show()
                                drFrame.BorderImmune:SetTexture("Interface\\AddOns\\sArena_Reloaded\\Textures\\UI-HUD-ActionBar-PetAutoCast-Mask.tga")
                            end
                            if drFrame.PixelBorder then
                                drFrame.PixelBorder:Hide()
                            end
                            if drFrame.PixelBorderImmune then
                                drFrame.PixelBorderImmune:Hide()
                            end
                            if not drFrame.Mask then
                                drFrame.Mask = drFrame:CreateMaskTexture()
                            end
                            drFrame.Mask:SetPoint("TOPLEFT", drFrame.Icon, "TOPLEFT", -1, 1)
                            drFrame.Mask:SetPoint("BOTTOMRIGHT", drFrame.Icon, "BOTTOMRIGHT", 1, -1)
                            if isRetail then
                                if drFrame.Cooldown then
                                    drFrame.Cooldown:SetSwipeTexture("Interface\\TalentFrame\\talentsmasknodechoiceflyout")
                                end
                                drFrame.Mask:SetTexture("Interface\\TalentFrame\\talentsmasknodechoiceflyout", "CLAMPTOBLACKADDITIVE", "CLAMPTOBLACKADDITIVE")
                            else
                                if drFrame.Cooldown then
                                    drFrame.Cooldown:SetSwipeTexture("Interface\\AddOns\\sArena_Reloaded\\Textures\\talentsmasknodechoiceflyout")
                                end
                                drFrame.Mask:SetTexture("Interface\\AddOns\\sArena_Reloaded\\Textures\\talentsmasknodechoiceflyout", "CLAMPTOBLACKADDITIVE", "CLAMPTOBLACKADDITIVE")
                            end
                            if drFrame.Icon then
                                drFrame.Icon:SetTexCoord(0.05, 0.95, 0.05, 0.9)
                                drFrame.Icon:AddMaskTexture(drFrame.Mask)
                            end

                            if not drFrame.Boverlay then
                                drFrame.Boverlay = CreateFrame("Frame", nil, drFrame)
                                drFrame.Boverlay:SetFrameStrata("MEDIUM")
                                drFrame.Boverlay:SetFrameLevel(6)
                            end
                            drFrame.Boverlay:Show()
                            if drFrame.Border then
                                drFrame.Border:SetParent(drFrame.Boverlay)
                            end

                            -- Set border size
                            local borderSize = 1
                            if drFrame.Border then
                                drFrame.Border:SetPoint("TOPLEFT", drFrame, "TOPLEFT", -borderSize, borderSize)
                                drFrame.Border:SetPoint("BOTTOMRIGHT", drFrame, "BOTTOMRIGHT", borderSize, -borderSize)
                                drFrame.BorderImmune:SetPoint("TOPLEFT", drFrame, "TOPLEFT", -borderSize, borderSize)
                                drFrame.BorderImmune:SetPoint("BOTTOMRIGHT", drFrame, "BOTTOMRIGHT", borderSize, -borderSize)
                            end

                        else
                            -- Default border style
                            if drFrame.Border then
                                drFrame.Border:SetTexture("Interface\\Buttons\\UI-Quickslot-Depress")
                                drFrame.Border:Show()

                                if db.blackDRBorder then
                                    drFrame.Border:SetVertexColor(0, 0, 0, 1)
                                    drFrame.BorderImmune:SetVertexColor(0, 0, 0, 1)
                                else
                                    drFrame.Border:SetVertexColor(0, 1, 0, 1)
                                    drFrame.BorderImmune:SetVertexColor(1, 0, 0, 1)
                                end

                                local borderSize = db.borderSize or 1
                                drFrame.Border:SetPoint("TOPLEFT", drFrame, "TOPLEFT", -borderSize, borderSize)
                                drFrame.Border:SetPoint("BOTTOMRIGHT", drFrame, "BOTTOMRIGHT", borderSize, -borderSize)
                                drFrame.BorderImmune:SetPoint("TOPLEFT", drFrame, "TOPLEFT", -borderSize, borderSize)
                                drFrame.BorderImmune:SetPoint("BOTTOMRIGHT", drFrame, "BOTTOMRIGHT", borderSize, -borderSize)
                            end
                            if drFrame.BorderImmune then
                                drFrame.BorderImmune:Show()
                                drFrame.BorderImmune:SetTexture("Interface\\Buttons\\UI-Quickslot-Depress")
                            end
                            if drFrame.PixelBorder then
                                drFrame.PixelBorder:Hide()
                            end
                            if drFrame.PixelBorderImmune then
                                drFrame.PixelBorderImmune:Hide()
                            end
                            if drFrame.Icon then
                                drFrame.Icon:SetTexCoord(0.08, 0.92, 0.08, 0.92)
                            end
                            if drFrame.Cooldown then
                                drFrame.Cooldown:SetSwipeTexture(1)
                            end
                        end

                        if drFrame.DRTextFrame then
                            drFrame.DRTextFrame:SetShown(db.showDRText == true)
                        end
                        if drFrame.DRText2 then
                            drFrame.DRText2:SetShown(db.showDRText == true)
                        end
                    end
                end
            end

            -- Also update FAKE DR frames if they exist (from test mode)
            if frame.fakeDRFrames then
                for drIndex, fakeDRFrame in ipairs(frame.fakeDRFrames) do
                    if fakeDRFrame then
                        fakeDRFrame:SetSize(size, size)

                        local text = fakeDRFrame.Cooldown.Text
                        local fontToUse = text.fontFile
                        if layoutCF then
                            fontToUse = LSM:Fetch(LSM.MediaType.FONT, self.layoutdb.cdFont)
                        end
                        text:SetFont(fontToUse, db.fontSize, "OUTLINE")
                        local sArenaText = fakeDRFrame.Cooldown.sArenaText
                        if sArenaText then
                            sArenaText:SetFont(fontToUse, db.fontSize, "OUTLINE")
                        end

                        -- Set border and text colors based on DR index
                        if fakeDRFrame.Border then
                            if drIndex == 1 then
                                fakeDRFrame.Border:SetVertexColor(1, 0, 0)
                            else
                                fakeDRFrame.Border:SetVertexColor(0, 1, 0)
                            end
                        end
                        
                        if fakeDRFrame.DRText then
                            if drIndex == 1 then
                                fakeDRFrame.DRText:SetTextColor(1, 0, 0)
                                fakeDRFrame.DRText:SetText("%")
                            else
                                fakeDRFrame.DRText:SetTextColor(0, 1, 0)
                                fakeDRFrame.DRText:SetText("½")
                            end
                        end
                        
                        if fakeDRFrame.Cooldown then
                            fakeDRFrame.Cooldown:SetReverse(reverseDR)
                            if disableDRSwipe then
                                fakeDRFrame.Cooldown:SetDrawSwipe(false)
                                fakeDRFrame.Cooldown:SetDrawEdge(false)
                            else
                                fakeDRFrame.Cooldown:SetDrawSwipe(true)
                                fakeDRFrame.Cooldown:SetDrawEdge(not disableSwipeEdge)
                            end
                        end
                        fakeDRFrame.Icon:SetDrawLayer("ARTWORK", 0)
                        fakeDRFrame.Border:SetParent(fakeDRFrame)
                        fakeDRFrame.Boverlay:Hide()
                        if fakeDRFrame.Mask then
                            fakeDRFrame.Icon:RemoveMaskTexture(fakeDRFrame.Mask)
                        end
                        if fakeDRFrame.PixelBorder then
                            fakeDRFrame.PixelBorder:Hide()
                        end

                        if db.disableDRBorder then
                            if fakeDRFrame.Border then
                                fakeDRFrame.Border:Hide()
                            end
                            if fakeDRFrame.PixelBorder then
                                fakeDRFrame.PixelBorder:Hide()
                            end
                            if fakeDRFrame.Icon then
                                if cropIcons then
                                    fakeDRFrame.Icon:SetTexCoord(0.08, 0.92, 0.08, 0.92)
                                else
                                    fakeDRFrame.Icon:SetTexCoord(0, 1, 0, 1)
                                end
                            end
                            if fakeDRFrame.Cooldown then
                                fakeDRFrame.Cooldown:SetSwipeTexture(1)
                            end
                            
                        elseif db.thinPixelBorder then
                            if fakeDRFrame.Border then
                                fakeDRFrame.Border:Show()
                                fakeDRFrame.Border:SetAtlas("communities-create-avatar-border-selected")
                            end
                            if fakeDRFrame.PixelBorder then
                                fakeDRFrame.PixelBorder:Hide()
                            end
                            if fakeDRFrame.Icon then
                                fakeDRFrame.Icon:SetTexCoord(0.05, 0.95, 0.07, 0.9)
                            end
                            if fakeDRFrame.Cooldown then
                                fakeDRFrame.Cooldown:SetSwipeTexture(1)
                            end

                        elseif db.thickPixelBorder then
                            if fakeDRFrame.Border then
                                fakeDRFrame.Border:Hide()
                            end
                            local drSize = 2
                            CreatePixelTextureBorder(fakeDRFrame, fakeDRFrame, "PixelBorder", drSize, 0)
                            fakeDRFrame.PixelBorder:Show()

                            if db.blackDRBorder then
                                fakeDRFrame.PixelBorder:SetVertexColor(0, 0, 0, 1)
                            else
                                if drIndex == 1 then
                                    fakeDRFrame.PixelBorder:SetVertexColor(1, 0, 0, 1)
                                else
                                    fakeDRFrame.PixelBorder:SetVertexColor(0, 1, 0, 1)
                                end
                            end
                            if fakeDRFrame.Icon then
                                fakeDRFrame.Icon:SetTexCoord(0.08, 0.92, 0.08, 0.92)
                            end
                            if fakeDRFrame.Cooldown then
                                fakeDRFrame.Cooldown:SetSwipeTexture(1)
                            end

                        elseif db.drBorderGlowOff then
                            if fakeDRFrame.Border then
                                fakeDRFrame.Border:Show()
                                fakeDRFrame.Border:SetTexture("Interface\\Buttons\\UI-Quickslot-Depress")

                                if db.blackDRBorder then
                                    fakeDRFrame.Border:SetVertexColor(0, 0, 0, 1)
                                    fakeDRFrame.BorderImmune:SetVertexColor(0, 0, 0, 1)
                                else
                                    if drIndex == 1 then
                                        fakeDRFrame.Border:SetVertexColor(1, 0, 0, 1)
                                        fakeDRFrame.BorderImmune:SetVertexColor(1, 0, 0, 1)
                                    else
                                        fakeDRFrame.Border:SetVertexColor(0, 1, 0, 1)
                                        fakeDRFrame.BorderImmune:SetVertexColor(0, 1, 0, 1)
                                    end
                                end
                            end
                            if fakeDRFrame.PixelBorder then
                                fakeDRFrame.PixelBorder:Hide()
                            end
                            if not fakeDRFrame.Mask then
                                fakeDRFrame.Mask = fakeDRFrame:CreateMaskTexture()
                            end
                            fakeDRFrame.Mask:SetPoint("TOPLEFT", fakeDRFrame.Icon, "TOPLEFT", 0.5, -0.5)
                            fakeDRFrame.Mask:SetPoint("BOTTOMRIGHT", fakeDRFrame.Icon, "BOTTOMRIGHT", -0.5, 0.5)
                            if fakeDRFrame.Cooldown then
                                fakeDRFrame.Cooldown:SetSwipeTexture("Interface\\AddOns\\sArena_Reloaded\\Textures\\squarecutcornermask")
                            end
                            fakeDRFrame.Mask:SetTexture("Interface\\AddOns\\sArena_Reloaded\\Textures\\squarecutcornermask", "CLAMPTOBLACKADDITIVE", "CLAMPTOBLACKADDITIVE")
                            if fakeDRFrame.Icon then
                                fakeDRFrame.Icon:SetDrawLayer("OVERLAY", 7)
                                fakeDRFrame.Icon:SetTexCoord(0.05, 0.95, 0.05, 0.9)
                                fakeDRFrame.Icon:AddMaskTexture(fakeDRFrame.Mask)
                            end

                            local borderSize = 1.5
                            if fakeDRFrame.Border then
                                fakeDRFrame.Border:SetPoint("TOPLEFT", fakeDRFrame, "TOPLEFT", -borderSize, borderSize)
                                fakeDRFrame.Border:SetPoint("BOTTOMRIGHT", fakeDRFrame, "BOTTOMRIGHT", borderSize, -borderSize)
                            end
                            
                        elseif db.brightDRBorder then

                            if fakeDRFrame.Border then
                                fakeDRFrame.Border:Show()
                                fakeDRFrame.Border:SetTexture("Interface\\AddOns\\sArena_Reloaded\\Textures\\UI-HUD-ActionBar-PetAutoCast-Mask.tga")
                                if db.blackDRBorder then
                                    fakeDRFrame.Border:SetVertexColor(0, 0, 0, 1)
                                else
                                    if drIndex == 1 then
                                        fakeDRFrame.Border:SetVertexColor(1, 0, 0, 1)
                                    else
                                        fakeDRFrame.Border:SetVertexColor(0, 1, 0, 1)
                                    end
                                end
                            end
                            if fakeDRFrame.PixelBorder then
                                fakeDRFrame.PixelBorder:Hide()
                            end
                            if not fakeDRFrame.Mask then
                                fakeDRFrame.Mask = fakeDRFrame:CreateMaskTexture()
                            end
                            fakeDRFrame.Mask:SetPoint("TOPLEFT", fakeDRFrame.Icon, "TOPLEFT", -1, 1)
                            fakeDRFrame.Mask:SetPoint("BOTTOMRIGHT", fakeDRFrame.Icon, "BOTTOMRIGHT", 1, -1)
                            if isRetail then
                                if fakeDRFrame.Cooldown then
                                    fakeDRFrame.Cooldown:SetSwipeTexture("Interface\\TalentFrame\\talentsmasknodechoiceflyout")
                                end
                                fakeDRFrame.Mask:SetTexture("Interface\\TalentFrame\\talentsmasknodechoiceflyout", "CLAMPTOBLACKADDITIVE", "CLAMPTOBLACKADDITIVE")
                            else
                                if fakeDRFrame.Cooldown then
                                    fakeDRFrame.Cooldown:SetSwipeTexture("Interface\\AddOns\\sArena_Reloaded\\Textures\\talentsmasknodechoiceflyout")
                                end
                                fakeDRFrame.Mask:SetTexture("Interface\\AddOns\\sArena_Reloaded\\Textures\\talentsmasknodechoiceflyout", "CLAMPTOBLACKADDITIVE", "CLAMPTOBLACKADDITIVE")
                            end
                            fakeDRFrame.Icon:SetTexCoord(0.05, 0.95, 0.05, 0.9)
                            fakeDRFrame.Icon:AddMaskTexture(fakeDRFrame.Mask)
                            if not fakeDRFrame.Boverlay then
                                fakeDRFrame.Boverlay = CreateFrame("Frame", nil, fakeDRFrame)
                                fakeDRFrame.Boverlay:SetFrameStrata("MEDIUM")
                                fakeDRFrame.Boverlay:SetFrameLevel(6)
                            end
                            fakeDRFrame.Boverlay:Show()
                            if fakeDRFrame.Border then
                                fakeDRFrame.Border:SetParent(fakeDRFrame.Boverlay)
                            end

                            local borderSize = 1
                            if fakeDRFrame.Border then
                                fakeDRFrame.Border:SetPoint("TOPLEFT", fakeDRFrame, "TOPLEFT", -borderSize, borderSize)
                                fakeDRFrame.Border:SetPoint("BOTTOMRIGHT", fakeDRFrame, "BOTTOMRIGHT", borderSize, -borderSize)
                            end
                        else
                            if fakeDRFrame.Border then
                                fakeDRFrame.Border:SetTexture("Interface\\Buttons\\UI-Quickslot-Depress")
                                fakeDRFrame.Border:Show()

                                if db.blackDRBorder then
                                    fakeDRFrame.Border:SetVertexColor(0, 0, 0, 1)
                                else
                                    if drIndex == 1 then
                                        fakeDRFrame.Border:SetVertexColor(1, 0, 0, 1)
                                    else
                                        fakeDRFrame.Border:SetVertexColor(0, 1, 0, 1)
                                    end
                                end

                                local borderSize = db.borderSize or 1
                                fakeDRFrame.Border:SetPoint("TOPLEFT", fakeDRFrame, "TOPLEFT", -borderSize, borderSize)
                                fakeDRFrame.Border:SetPoint("BOTTOMRIGHT", fakeDRFrame, "BOTTOMRIGHT", borderSize, -borderSize)
                            end
                            if fakeDRFrame.Icon then
                                fakeDRFrame.Icon:SetTexCoord(0.08, 0.92, 0.08, 0.92)
                            end
                            if fakeDRFrame.Cooldown then
                                fakeDRFrame.Cooldown:SetSwipeTexture(1)
                            end
                        end

                        if fakeDRFrame.DRTextFrame then
                            fakeDRFrame.DRTextFrame:SetShown(db.showDRText == true)
                        end
                        if fakeDRFrame.DRText2 then
                            fakeDRFrame.DRText2:SetShown(db.showDRText == true)
                        end
                    end
                end
            end
        end
        
        local currentLayout = self.db and self.db.profile and self.db.profile.currentLayout
        local layoutSettings = self.db and self.db.profile and self.db.profile.layoutSettings and self.db.profile.layoutSettings[currentLayout]
        if layoutSettings and layoutSettings.textSettings then
            self:UpdateDRTextPositions(layoutSettings.textSettings)
        end
        
        return
    end

    -- Legacy system for non-Midnight
    local categories = sArenaMixin.drCategories
    local categorySizeOffsets = db.drCategorySizeOffsets or {}

    sArenaMixin.drBaseSize = db.size

    for i = 1, sArenaMixin.maxArenaOpponents do
        local frame = self["arena" .. i]
        if not frame then return end

        if frame.UpdateDRPositions then
            frame:UpdateDRPositions()
        end

        for n = 1, #categories do
            local category = categories[n]
            local dr = frame[category]
            -- Skip if DR frame doesn't exist yet (not initialized)
            if not dr then
                return
            end

            local offset = categorySizeOffsets[category] or 0
            local borderSize = (db.drBorderGlowOff and 1.5) or (db.brightDRBorder and 1) or db.borderSize or 1
            local size = db.size + offset

            dr:SetFrameLevel(20)
            dr:SetSize(size, size)
            dr.Border:SetPoint("TOPLEFT", dr, "TOPLEFT", -borderSize, borderSize)
            dr.Border:SetPoint("BOTTOMRIGHT", dr, "BOTTOMRIGHT", borderSize, -borderSize)
            dr.Cooldown:SetSwipeColor(0, 0, 0, 0.55)

            local text = dr.Cooldown.Text
            local fontToUse = text.fontFile
            if layoutCF then
                fontToUse = LSM:Fetch(LSM.MediaType.FONT, self.layoutdb.cdFont)
            end
            text:SetFont(fontToUse, db.fontSize, "OUTLINE")
            local sArenaText = dr.Cooldown.sArenaText
            if sArenaText then
                sArenaText:SetFont(fontToUse, db.fontSize, "OUTLINE")
            end

            -- Handle DR swipe settings (global setting)
            local disableSwipeEdge = self.db.profile.disableSwipeEdge
            local disableDRSwipe = self.db.profile.disableDRSwipe
            local reverseDR = self.db.profile.invertDRCooldown

            dr.Cooldown:SetReverse(reverseDR)
            if disableDRSwipe then
                dr.Cooldown:SetDrawSwipe(false)
                dr.Cooldown:SetDrawEdge(false)
            else
                dr.Cooldown:SetDrawSwipe(true)
                dr.Cooldown:SetDrawEdge(not disableSwipeEdge)
            end

            if db.showDRText then
                dr.DRTextFrame:Show()
            else
                dr.DRTextFrame:Hide()
            end

            dr.Icon:SetDrawLayer("ARTWORK", 0)

            if dr.Boverlay then
                dr.Border:SetParent(dr)
                dr.Boverlay:Hide()
            end
            if dr.Mask then
                dr.Icon:RemoveMaskTexture(dr.Mask)
            end
            if dr.PixelBorder then
                dr.PixelBorder:Hide()
            end

            dr.Border:SetTexture("Interface\\Buttons\\UI-Quickslot-Depress")
            dr.Border:Show()
            dr.Icon:SetTexCoord(0.08, 0.92, 0.08, 0.92)
            dr.Cooldown:SetSwipeTexture(1)

            local currentLayout = self.db and self.db.profile and self.db.profile.currentLayout
            local layoutSettings = self.db and self.db.profile and self.db.profile.layoutSettings and self.db.profile.layoutSettings[currentLayout]
            local cropIcons = layoutSettings and layoutSettings.cropIcons or false

            if db.disableDRBorder then
                dr.Border:Hide()
                if dr.PixelBorder then
                    dr.PixelBorder:Hide()
                end
                if cropIcons then
                    dr.Icon:SetTexCoord(0.08, 0.92, 0.08, 0.92)
                else
                    dr.Icon:SetTexCoord(0, 1, 0, 1)
                end
            elseif db.thinPixelBorder then
                dr.Border:Show()
                if dr.PixelBorder then
                    dr.PixelBorder:Hide()
                end
                dr.Border:SetAtlas("communities-create-avatar-border-selected")
                dr.Icon:SetTexCoord(0.05, 0.95, 0.07, 0.9)
            elseif db.thickPixelBorder then
                dr.Border:Hide()
                local drSize = 2
                CreatePixelTextureBorder(dr, dr, "PixelBorder", drSize, 0)
                dr.PixelBorder:Show()

                if db.blackDRBorder then
                    dr.PixelBorder:SetVertexColor(0, 0, 0, 1)
                else
                    if frame:GetID() == 1 then
                        dr.PixelBorder:SetVertexColor(1, 0, 0, 1)
                    else
                        dr.PixelBorder:SetVertexColor(0, 1, 0, 1)
                    end
                end
            elseif db.drBorderGlowOff then
                dr.Border:Show()
                if dr.PixelBorder then
                    dr.PixelBorder:Hide()
                end
                if not dr.Mask then
                    dr.Mask = dr:CreateMaskTexture()
                end
                dr.Mask:SetPoint("TOPLEFT", dr.Icon, "TOPLEFT", 0.5, -0.5)
                dr.Mask:SetPoint("BOTTOMRIGHT", dr.Icon, "BOTTOMRIGHT", -0.5, 0.5)
                dr.Border:SetTexture("Interface\\Buttons\\UI-Quickslot-Depress")
                dr.Cooldown:SetSwipeTexture("Interface\\AddOns\\sArena_Reloaded\\Textures\\squarecutcornermask")
                dr.Mask:SetTexture("Interface\\AddOns\\sArena_Reloaded\\Textures\\squarecutcornermask", "CLAMPTOBLACKADDITIVE", "CLAMPTOBLACKADDITIVE")
                dr.Icon:SetDrawLayer("OVERLAY", 7)
                dr.Icon:SetTexCoord(0.05, 0.95, 0.05, 0.9)
                dr.Icon:AddMaskTexture(dr.Mask)
            elseif db.brightDRBorder then
                dr.Border:Show()
                if dr.PixelBorder then
                    dr.PixelBorder:Hide()
                end
                if not dr.Mask then
                    dr.Mask = dr:CreateMaskTexture()
                end
                dr.Mask:SetPoint("TOPLEFT", dr.Icon, "TOPLEFT", -1, 1)
                dr.Mask:SetPoint("BOTTOMRIGHT", dr.Icon, "BOTTOMRIGHT", 1, -1)
                if isRetail then
                    dr.Border:SetTexture("Interface\\AddOns\\sArena_Reloaded\\Textures\\UI-HUD-ActionBar-PetAutoCast-Mask.tga")
                    dr.Cooldown:SetSwipeTexture("Interface\\TalentFrame\\talentsmasknodechoiceflyout")
                    dr.Mask:SetTexture("Interface\\TalentFrame\\talentsmasknodechoiceflyout", "CLAMPTOBLACKADDITIVE", "CLAMPTOBLACKADDITIVE")
                else
                    dr.Border:SetTexture("Interface\\AddOns\\sArena_Reloaded\\Textures\\UI-HUD-ActionBar-PetAutoCast-Mask.tga")
                    dr.Cooldown:SetSwipeTexture("Interface\\AddOns\\sArena_Reloaded\\Textures\\talentsmasknodechoiceflyout")
                    dr.Mask:SetTexture("Interface\\AddOns\\sArena_Reloaded\\Textures\\talentsmasknodechoiceflyout", "CLAMPTOBLACKADDITIVE", "CLAMPTOBLACKADDITIVE")
                end
                dr.Icon:SetTexCoord(0.05, 0.95, 0.05, 0.9)

                dr.Icon:AddMaskTexture(dr.Mask)

                if not dr.Boverlay then
                    dr.Boverlay = CreateFrame("Frame", nil, dr)
                    dr.Boverlay:SetFrameStrata("MEDIUM")
                    dr.Boverlay:SetFrameLevel(26)
                end
                dr.Boverlay:Show()
                dr.Border:SetParent(dr.Boverlay)
            end
        end
    end

    local currentLayout = self.db and self.db.profile and self.db.profile.currentLayout
    local layoutSettings = self.db and self.db.profile and self.db.profile.layoutSettings and self.db.profile.layoutSettings[currentLayout]
    if layoutSettings and layoutSettings.textSettings then
        self:UpdateDRTextPositions(layoutSettings.textSettings)
    end
end

function sArenaMixin:UpdateSpecIconSettings(db, info, val)
    if (val) then
        db[info[#info]] = val
    end

    for i = 1, sArenaMixin.maxArenaOpponents do
        local frame = self["arena" .. i]

        frame.SpecIcon:ClearAllPoints()
        frame.SpecIcon:SetPoint("CENTER", frame, "CENTER", db.posX, db.posY)
        frame.SpecIcon:SetScale(db.scale)
    end
end

function sArenaMixin:UpdateTrinketSettings(db, info, val)
    if (val) then
        db[info[#info]] = val
    end

    local layoutCF = (self.layoutdb and self.layoutdb.changeFont)

    for i = 1, sArenaMixin.maxArenaOpponents do
        local frame = self["arena" .. i]

        frame.Trinket:ClearAllPoints()
        frame.Trinket:SetPoint("CENTER", frame, "CENTER", db.posX, db.posY)
        frame.Trinket:SetScale(db.scale)

        local text = self["arena" .. i].Trinket.Cooldown.Text
        local fontToUse = text.fontFile
        if layoutCF then
            fontToUse = LSM:Fetch(LSM.MediaType.FONT, self.layoutdb.cdFont)
        end
        text:SetFont(fontToUse, db.fontSize, "OUTLINE")
    end
end

function sArenaMixin:UpdateRacialSettings(db, info, val)
    if (val) then
        db[info[#info]] = val
    end

    for i = 1, sArenaMixin.maxArenaOpponents do
        local frame = self["arena" .. i]

        frame.Racial:ClearAllPoints()
        frame.Racial:SetPoint("CENTER", frame, "CENTER", db.posX, db.posY)
        frame.Racial:SetScale(db.scale)

        local text = self["arena" .. i].Racial.Cooldown.Text
        local layoutCF = (self.layoutdb and self.layoutdb.changeFont)
        local fontToUse = text.fontFile
        if layoutCF then
            fontToUse = LSM:Fetch(LSM.MediaType.FONT, self.layoutdb.cdFont)
        end
        text:SetFont(fontToUse, db.fontSize, "OUTLINE")
    end
end

function sArenaMixin:UpdateDispelSettings(db, info, val)
    if (val ~= nil) then
        db[info[#info]] = val
    end

    local layoutCF = (self.layoutdb and self.layoutdb.changeFont)

    for i = 1, sArenaMixin.maxArenaOpponents do
        local frame = self["arena" .. i]

        frame.Dispel:ClearAllPoints()
        frame.Dispel:SetPoint("CENTER", frame, "CENTER", db.posX, db.posY)
        frame.Dispel:SetScale(db.scale)

        local text = self["arena" .. i].Dispel.Cooldown.Text
        local fontToUse = text.fontFile
        if layoutCF then
            fontToUse = LSM:Fetch(LSM.MediaType.FONT, self.layoutdb.cdFont)
        end
        text:SetFont(fontToUse, db.fontSize, "OUTLINE")

        frame.Dispel:SetShown(self.db.profile.showDispels)
    end
end

function sArenaMixin:UpdateTextPositions(db, info, val)
    for i = 1, sArenaMixin.maxArenaOpponents do
        local frame = info.handler["arena" .. i]
        local layout = info.handler.layouts[info.handler.db.profile.currentLayout]

        if frame and layout and layout.UpdateOrientation then
            layout:UpdateOrientation(frame)
        end
    end
end

function sArenaMixin:UpdateDRTextPositions(db, info, val)
    if (val) then
        db[info[#info]] = val
    end

    for i = 1, sArenaMixin.maxArenaOpponents do
        local frame = info and info.handler["arena" .. i] or self["arena" .. i]
        if not frame then return end
        
        -- Update real DR frames for Midnight
        if sArenaMixin.isMidnight and frame.drFrames then
            for drIndex, drFrame in ipairs(frame.drFrames) do
                if drFrame and drFrame.DRText then
                    drFrame.DRText:ClearAllPoints()
                    drFrame.DRText:SetPoint(db.drTextAnchor or "BOTTOMRIGHT", 
                        (db.drTextOffsetX or 4), 
                        (db.drTextOffsetY or -4))
                    drFrame.DRText:SetScale(db.drTextSize or 1.0)
                end
                if drFrame and drFrame.DRText2 then
                    drFrame.DRText2:ClearAllPoints()
                    drFrame.DRText2:SetPoint("CENTER", drFrame.DRText, "CENTER", 0, 0)
                    drFrame.DRText2:SetScale(db.drTextSize or 1.0)
                end
            end
        end
        
        -- Update Retail DR frames (non-Midnight)
        if not sArenaMixin.isMidnight then
            for _, category in ipairs(sArenaMixin.drCategories) do
                local drFrame = frame[category]
                if drFrame and drFrame.DRTextFrame and drFrame.DRTextFrame.DRText then
                    local drText = drFrame.DRTextFrame.DRText
                    drText:ClearAllPoints()
                    drText:SetPoint(db.drTextAnchor or "BOTTOMRIGHT", 
                        (db.drTextOffsetX or 4), 
                        (db.drTextOffsetY or -4))
                    drText:SetScale(db.drTextSize or 1.0)
                end
            end
        end
        
        -- Update fake DR frames (test mode)
        if frame.fakeDRFrames then
            for drIndex, fakeDRFrame in ipairs(frame.fakeDRFrames) do
                if fakeDRFrame and fakeDRFrame.DRText then
                    fakeDRFrame.DRText:ClearAllPoints()
                    fakeDRFrame.DRText:SetPoint(db.drTextAnchor or "BOTTOMRIGHT", 
                        (db.drTextOffsetX or 4), 
                        (db.drTextOffsetY or -4))
                    fakeDRFrame.DRText:SetScale(db.drTextSize or 1.0)
                end
            end
        end
    end
end

function sArenaMixin:UpdateWidgetSettings(db, info, val)
    if info and val ~= nil then
        db[info[#info]] = val
    end

    self:UnregisterWidgetEvents()
    self:RegisterWidgetEvents()

    for i = 1, sArenaMixin.maxArenaOpponents do
        local frame = self["arena" .. i]


        frame.WidgetOverlay.combatIndicator:SetScale(db.combatIndicator.scale or 1)
        frame.WidgetOverlay.targetIndicator:SetScale(db.targetIndicator.scale or 1)
        frame.WidgetOverlay.focusIndicator:SetScale(db.focusIndicator.scale or 1)
        frame.WidgetOverlay.partyTarget1:SetScale(db.partyTargetIndicators.scale or 1)
        frame.WidgetOverlay.partyTarget2:SetScale(db.partyTargetIndicators.scale or 1)

        -- Only try to update orientation if called from config (with info parameter)
        if info and info.handler then
            local layout = info.handler.layouts[info.handler.db.profile.currentLayout]
            if frame and layout and layout.UpdateOrientation then
                layout:UpdateOrientation(frame)
            end
        else
            -- Called from layout Initialize, get current layout directly
            local currentLayout = self.db.profile.currentLayout
            local layout = self.layouts[currentLayout]
            if frame and layout and layout.UpdateOrientation then
                layout:UpdateOrientation(frame)
            end
        end
    end
end

function sArenaFrameMixin:UpdateClassIconCooldownReverse()
    local reverse = self.parent.db.profile.invertClassIconCooldown

    self.ClassIcon.Cooldown:SetReverse(reverse)
end

function sArenaFrameMixin:UpdateTrinketRacialCooldownReverse()
    local reverse = self.parent.db.profile.invertTrinketRacialCooldown

    self.Trinket.Cooldown:SetReverse(reverse)
    self.Racial.Cooldown:SetReverse(reverse)
end

function sArenaFrameMixin:UpdateClassIconSwipeSettings()
    local disableSwipe = self.parent.db.profile.disableClassIconSwipe
    local disableSwipeEdge = self.parent.db.profile.disableSwipeEdge

    if self.ClassIcon.Cooldown then
        if disableSwipe then
            self.ClassIcon.Cooldown:SetDrawSwipe(false)
            self.ClassIcon.Cooldown:SetDrawEdge(false)
        else
            self.ClassIcon.Cooldown:SetDrawSwipe(true)
            self.ClassIcon.Cooldown:SetDrawEdge(not disableSwipeEdge)
        end
    end
end

function sArenaFrameMixin:UpdateTrinketRacialSwipeSettings()
    local disableSwipe = self.parent.db.profile.disableTrinketRacialSwipe
    local disableSwipeEdge = self.parent.db.profile.disableSwipeEdge

    if self.Trinket and self.Trinket.Cooldown then
        if disableSwipe then
            self.Trinket.Cooldown:SetDrawSwipe(false)
            self.Trinket.Cooldown:SetDrawEdge(false)
        else
            self.Trinket.Cooldown:SetDrawSwipe(true)
            self.Trinket.Cooldown:SetDrawEdge(not disableSwipeEdge)
        end
    end

    if self.Racial and self.Racial.Cooldown then
        if disableSwipe then
            self.Racial.Cooldown:SetDrawSwipe(false)
            self.Racial.Cooldown:SetDrawEdge(false)
        else
            self.Racial.Cooldown:SetDrawSwipe(true)
            self.Racial.Cooldown:SetDrawEdge(not disableSwipeEdge)
        end
    end
end

function sArenaFrameMixin:UpdateSwipeEdgeSettings()
    local disableEdge = self.parent.db.profile.disableSwipeEdge

    self.ClassIcon.Cooldown:SetDrawEdge(not disableEdge)
    self.Trinket.Cooldown:SetDrawEdge(not disableEdge)
    self.Racial.Cooldown:SetDrawEdge(not disableEdge)
end

local function setDRIcons()
    local inputs = {
        drIconsTitle = {
            order = 1,
            type = "description",
            name = function(info)
                local db = info.handler.db
                if db.profile.drStaticIconsPerSpec then
                    local className = select(1, UnitClass("player")) or L["Unknown"]
                    local classKey = select(2, UnitClass("player"))
                    local specName = sArenaMixin.playerSpecName or L["Unknown"]
                    local classColor = RAID_CLASS_COLORS[classKey]
                    local coloredText = specName .. " " .. className
                    if classColor then
                        coloredText = "|c" .. classColor.colorStr .. coloredText .. "|r"
                    end
                    return string.format(L["DR_IconsPerSpec"], coloredText)
                elseif db.profile.drStaticIconsPerClass then
                    local className = select(1, UnitClass("player")) or L["Unknown"]
                    local classKey = select(2, UnitClass("player"))
                    local classColor = RAID_CLASS_COLORS[classKey]
                    local coloredText = className
                    if classColor then
                        coloredText = "|c" .. classColor.colorStr .. coloredText .. "|r"
                    end
                    return string.format(L["DR_IconsPerClass"], coloredText)
                else
                    return L["DR_IconsGlobal"]
                end
            end,
            fontSize = "medium",
        }
    }

    local order = 2

    for category, defaultIcon in pairs(drIcons) do
        inputs[category] = {
            order = order,
            name = function(info)
                local db = info.handler.db
                local icon = nil
                if db.profile.drStaticIconsPerSpec then
                    local specKey = sArenaMixin.playerSpecID or 0
                    local perSpec = db.profile.drIconsPerSpec or {}
                    local specIcons = perSpec[specKey] or {}
                    icon = specIcons[category]
                elseif db.profile.drStaticIconsPerClass then
                    local classKey = sArenaMixin.playerClass
                    local perClass = db.profile.drIconsPerClass or {}
                    local classIcons = perClass[classKey] or {}
                    icon = classIcons[category]
                end
                if not icon then
                    local dbIcons = db.profile.drIcons or {}
                    icon = dbIcons[category] or defaultIcon
                end
                local textureString = ""
                if type(icon) == "number" then
                    textureString = "|T" .. icon .. ":24:24:0:0:64:64:5:59:5:59|t "
                elseif type(icon) == "string" then
                    textureString = "|T" .. icon .. ":24|t "
                end
                return textureString .. (L["DR_" .. category] or category) .. ":"
            end,
            desc = string.format(L["Option_DefaultIcon_Desc"], defaultIcon, defaultIcon),
            type = "input",
            width = "full",
            get = function(info)
                local db = info.handler.db
                -- If per-spec is enabled, prefer the spec-specific value when present.
                -- If the spec-specific value is missing, show the global saved icon or the default icon
                -- so the edit box isn't empty and the user sees the effective icon.
                if db.profile.drStaticIconsPerSpec then
                    local perSpec = db.profile.drIconsPerSpec or {}
                    local specIcons = perSpec[sArenaMixin.playerSpecID or 0] or {}
                    local specVal = specIcons[category]
                    if specVal ~= nil and specVal ~= "" then
                        return tostring(specVal)
                    end
                    -- fallback to global saved icon or default icon
                    local dbIcons = db.profile.drIcons or {}
                    return tostring(dbIcons[category] or defaultIcon or "")
                elseif db.profile.drStaticIconsPerClass then
                    local perClass = db.profile.drIconsPerClass or {}
                    local classIcons = perClass[sArenaMixin.playerClass] or {}
                    local classVal = classIcons[category]
                    if classVal ~= nil and classVal ~= "" then
                        return tostring(classVal)
                    end
                    -- fallback to global saved icon or default icon
                    local dbIcons = db.profile.drIcons or {}
                    return tostring(dbIcons[category] or defaultIcon or "")
                else
                    local dbIcons = db.profile.drIcons or {}
                    return tostring(dbIcons[category] or defaultIcon or "")
                end
            end,
            set = function(info, value)
                local db = info.handler.db
                if db.profile.drStaticIconsPerSpec then
                    db.profile.drIconsPerSpec = db.profile.drIconsPerSpec or {}
                    local specKey = sArenaMixin.playerSpecID or 0
                    db.profile.drIconsPerSpec[specKey] = db.profile.drIconsPerSpec[specKey] or {}
                    -- treat empty string as removal of the spec-specific override so we fall back
                    -- to the global saved icon/default.
                    if value == nil or tostring(value) == "" then
                        db.profile.drIconsPerSpec[specKey][category] = nil
                    else
                        local num = tonumber(value)
                        db.profile.drIconsPerSpec[specKey][category] = num or value
                    end
                elseif db.profile.drStaticIconsPerClass then
                    db.profile.drIconsPerClass = db.profile.drIconsPerClass or {}
                    db.profile.drIconsPerClass[sArenaMixin.playerClass] = db.profile.drIconsPerClass[sArenaMixin.playerClass] or {}
                    -- treat empty string as removal of the class-specific override so we fall back
                    -- to the global saved icon/default.
                    if value == nil or tostring(value) == "" then
                        db.profile.drIconsPerClass[sArenaMixin.playerClass][category] = nil
                    else
                        local num = tonumber(value)
                        db.profile.drIconsPerClass[sArenaMixin.playerClass][category] = num or value
                    end
                else
                    db.profile.drIcons = db.profile.drIcons or {}
                    if value == nil or tostring(value) == "" then
                        db.profile.drIcons[category] = nil
                    else
                        local num = tonumber(value)
                        db.profile.drIcons[category] = num or value
                    end
                end
                LibStub("AceConfigRegistry-3.0"):NotifyChange("sArena")
            end,
        }

        order = order + 1
    end

    return inputs
end


function sArenaMixin:CompatibilityIssueExists()
    -- List of known sArena addon variants that will conflict
    local otherSArenaVersions = {
        "sArena", -- Original
        "sArena Updated",
        "sArena_MoP",
        "sArena_Pinaclonada",
        "sArena_Updated2_by_sammers",
    }

    -- Check each known version to see if it's loaded
    for _, addonName in ipairs(otherSArenaVersions) do
        if C_AddOns.IsAddOnLoaded(addonName) then
            return true, addonName  -- Return true and the name of the first conflicting addon found
        end
    end

    return false, nil  -- No conflicts found
end


if sArenaMixin:CompatibilityIssueExists() then
    sArenaMixin.optionsTable = {
        type = "group",
        childGroups = "tab",
        validate = validateCombat,
        args = {
            ImportOtherForkSettings = {
                order = 1,
                name = L["Option_AddonConflict"],
                desc = L["Conflict_MultipleVersions"],
                type = "group",
                args = {
                    warningTitle = {
                        order = 1,
                        type = "description",
                        name = L["Conflict_Warning"],
                        fontSize = "large",
                    },
                    spacer1 = {
                        order = 1.1,
                        type = "description",
                        name = " ",
                    },
                    explanation = {
                        order = 1.2,
                        type = "description",
                        name = L["Conflict_Explanation"],
                        fontSize = "medium",
                    },
                    spacer2 = {
                        order = 1.3,
                        type = "description",
                        name = " ",
                    },
                    option1 = {
                        order = 2,
                        type = "execute",
                        name = L["Conflict_UseOther"],
                        desc = L["Conflict_UseOther_Desc"],
                        func = function()
                            C_AddOns.DisableAddOn("sArena_Reloaded")
                            ReloadUI()
                        end,
                        width = "full",
                        confirm = true,
                        confirmText = L["Conflict_UseOther_Confirm"],
                    },
                    option2 = {
                        order = 3,
                        type = "execute",
                        name = L["Conflict_UseReloaded_Import"],
                        desc = L["Conflict_UseReloaded_Import_Desc"],
                        func = function()
                            if sArenaMixin.ImportOtherForkSettings then
                                sArenaMixin:ImportOtherForkSettings()
                            end
                        end,
                        width = "full",
                        confirm = true,
                        confirmText = L["Conflict_UseReloaded_Import_Confirm"],
                    },
                    option3 = {
                        order = 4,
                        type = "execute",
                        name = L["Conflict_UseReloaded_NoImport"],
                        desc = L["Conflict_UseReloaded_NoImport_Desc"],
                        func = function()
                            sArenaMixin:CompatibilityEnsurer()
                            ReloadUI()
                        end,
                        width = "full",
                        confirm = true,
                        confirmText = L["Conflict_UseReloaded_NoImport_Confirm"],
                    },
                    spacer3 = {
                        order = 4.5,
                        type = "description",
                        name = " ",
                    },
                    conversionStatus = {
                        order = 5,
                        type = "description",
                        name = function() return sArenaMixin.conversionStatusText or "" end,
                        fontSize = "large",
                        hidden = function() return not sArenaMixin.conversionStatusText end,
                    },
                },
            },
        },
    }
else
    sArenaMixin.optionsTable = {
        type = "group",
        childGroups = "tab",
        validate = validateCombat,
        args = {
            setLayout = {
                order = 1,
                name = L["Option_Layout"],
                type = "select",
                style = "dropdown",
                get = function(info) return info.handler.db.profile.currentLayout end,
                set = "SetLayout",
                values = getLayoutTable,
            },
            test = {
                order = 2,
                name = L["Option_Test"],
                type = "execute",
                func = "Test",
                width = "half",
            },
            hide = {
                order = 3,
                name = L["Option_Hide"],
                type = "execute",
                func = function(info)
                    for i = 1, sArenaMixin.maxArenaOpponents do
                        info.handler["arena" .. i]:OnEvent("PLAYER_ENTERING_WORLD")
                    end
                end,
                width = "half",
            },
            dragNotice = {
                order = 4,
                name = ("|T132961:16|t |cffff3300"..L["Drag_Hint"].."|r"),
                type = "description",
                fontSize = "medium",
                width = 1.5,
            },
            layoutSettingsGroup = {
                order = 5,
                name = L["Layout_Settings"],
                desc = L["Layout_Settings_Desc"],
                type = "group",
                args = {},
            },
            globalSettingsGroup = {
                order = 6,
                name = L["Global_Settings"],
                desc = L["Global_Settings_Desc"],
                type = "group",
                childGroups = "tree",
                args = {
                    framesGroup = {
                        order = 1,
                        name = L["Option_ArenaFrames"],
                        type = "group",
                        args = {
                            statusText = {
                                order = 5,
                                name = L["Option_StatusText"],
                                type = "group",
                                inline = true,
                                args = {
                                    alwaysShow = {
                                        order = 1,
                                        name = L["Option_AlwaysShow"],
                                        desc = L["Text_ShowOnMouseover_Desc"],
                                        type = "toggle",
                                        get = function(info) return info.handler.db.profile.statusText.alwaysShow end,
                                        set = function(info, val)
                                            info.handler.db.profile.statusText.alwaysShow = val
                                            for i = 1, sArenaMixin.maxArenaOpponents do
                                                info.handler["arena" .. i]:UpdateStatusTextVisible()
                                            end
                                        end,
                                    },
                                    usePercentage = {
                                        order = 2,
                                        name = L["Option_UsePercentage"],
                                        type = "toggle",
                                        get = function(info) return info.handler.db.profile.statusText.usePercentage end,
                                        set = function(info, val)
                                            info.handler.db.profile.statusText.usePercentage = val
                                            if val then
                                                info.handler.db.profile.statusText.formatNumbers = false
                                            end

                                            local _, instanceType = IsInInstance()
                                            if (instanceType ~= "arena" and info.handler.arena1:IsShown()) then
                                                info.handler:Test()
                                            end
                                        end,
                                    },
                                    formatNumbers = {
                                        order = 3,
                                        name = L["Option_FormatNumbers"],
                                        desc = L["Text_FormatLargeNumbers_Desc"],
                                        type = "toggle",
                                        get = function(info) return info.handler.db.profile.statusText.formatNumbers end,
                                        set = function(info, val)
                                            info.handler.db.profile.statusText.formatNumbers = val
                                            if val then
                                                info.handler.db.profile.statusText.usePercentage = false
                                            end

                                            local _, instanceType = IsInInstance()
                                            if (instanceType ~= "arena" and info.handler.arena1:IsShown()) then
                                                info.handler:Test()
                                            end
                                        end,
                                    },
                                    hidePowerText = {
                                        order = 4,
                                        name = L["Text_HidePowerText"],
                                        desc = L["Text_HidePowerText_Desc"],
                                        type = "toggle",
                                        get = function(info) return info.handler.db.profile.hidePowerText end,
                                        set = function(info, val)
                                            info.handler.db.profile.hidePowerText = val
                                            for i = 1, sArenaMixin.maxArenaOpponents do
                                                info.handler["arena" .. i]:UpdateStatusTextVisible()
                                            end
                                        end,
                                    },
                                },
                            },
                            darkModeGroup = {
                                order = 5.5,
                                name = L["Option_DarkMode"],
                                type = "group",
                                inline = true,
                                args = {
                                    darkMode = {
                                        order = 1,
                                        name = L["DarkMode_Enable"],
                                        type = "toggle",
                                        width = 1,
                                        desc = function(info)
                                            local baseDesc = L["DarkMode_Enable_Desc"]
                                            local layout = info.handler.db.profile.currentLayout
                                            if layout == "BlizzCompact" then
                                                return baseDesc .. "\n\nCan be combined with Class Color FrameTexture. When combined, class colors take priority - use 'Only Class Icon' to apply class color to the icon while Dark Mode colors the rest."
                                            end
                                            return baseDesc
                                        end,
                                        get = function(info) return info.handler.db.profile.darkMode end,
                                        set = function(info, val)
                                            info.handler.db.profile.darkMode = val
                                            info.handler:RefreshConfig()
                                            info.handler:Test()
                                        end,
                                    },
                                    darkModeValue = {
                                        order = 2,
                                        name = L["DarkMode_Value"],
                                        type = "range",
                                        width = 0.75,
                                        desc = L["DarkMode_Value_Desc"],
                                        min = 0,
                                        max = 1,
                                        step = 0.01,
                                        disabled = function(info)
                                            return not info.handler.db.profile.darkMode
                                        end,
                                        get = function(info) return info.handler.db.profile.darkModeValue end,
                                        set = function(info, val)
                                            info.handler.db.profile.darkModeValue = val
                                            for i = 1, sArenaMixin.maxArenaOpponents do
                                                local frame = info.handler["arena"..i]
                                                if frame then
                                                    frame:UpdateFrameColors()
                                                end
                                            end
                                        end,
                                    },
                                    darkModeDesaturate = {
                                        order = 3,
                                        name = L["Option_Desaturate"],
                                        type = "toggle",
                                        width = 0.75,
                                        desc = L["DarkMode_Desaturate_Desc"],
                                        disabled = function(info)
                                            return not info.handler.db.profile.darkMode
                                        end,
                                        get = function(info) return info.handler.db.profile.darkModeDesaturate end,
                                        set = function(info, val)
                                            info.handler.db.profile.darkModeDesaturate = val
                                            for i = 1, sArenaMixin.maxArenaOpponents do
                                                local frame = info.handler["arena"..i]
                                                if frame then
                                                    frame:UpdateFrameColors()
                                                end
                                            end
                                        end,
                                    },
                                },
                            },
                            misc = {
                                order = 6,
                                name = L["Option_Miscellaneous"],
                                type = "group",
                                inline = true,
                                args = {
                                    classColors = {
                                        order = 1,
                                        name = L["ClassColor_Healthbars"],
                                        desc = L["ClassColor_Healthbars_Desc"],
                                        type = "toggle",
                                        width = "full",
                                        get = function(info) return info.handler.db.profile.classColors end,
                                        set = function(info, val)
                                            local db = info.handler.db
                                            db.profile.classColors = val

                                            for i = 1, sArenaMixin.maxArenaOpponents do
                                                local frame = info.handler["arena" .. i]
                                                local class = frame.tempClass
                                                local color = RAID_CLASS_COLORS[class]

                                                if val and color then
                                                    frame.HealthBar:SetStatusBarColor(color.r, color.g, color.b, 1)
                                                else
                                                    frame.HealthBar:SetStatusBarColor(0, 1, 0, 1)
                                                end
                                            end
                                        end,
                                    },
                                    classColorFrameTexture = {
                                        order = 1.05,
                                        name = L["ClassColor_FrameTexture"],
                                        desc = L["ClassColor_FrameTexture_Desc"],
                                        type = "toggle",
                                        width = 1.1,
                                        get = function(info) return info.handler.db.profile.classColorFrameTexture end,
                                        set = function(info, val)
                                            info.handler.db.profile.classColorFrameTexture = val
                                            for i = 1, sArenaMixin.maxArenaOpponents do
                                                local frame = info.handler["arena"..i]
                                                if frame then
                                                    frame:UpdateFrameColors()
                                                end
                                            end
                                        end,
                                    },
                                    classColorFrameTextureOnlyClassIcon = {
                                        order = 1.06,
                                        name = L["ClassColor_OnlyClassIcon"],
                                        desc = L["ClassColor_OnlyClassIcon_Desc"],
                                        type = "toggle",
                                        width = 0.8,
                                        hidden = function(info)
                                            local layout = info.handler.db.profile.currentLayout
                                            return layout ~= "BlizzCompact"
                                        end,
                                        disabled = function(info) return not info.handler.db.profile.classColorFrameTexture end,
                                        get = function(info) return info.handler.db.profile.classColorFrameTextureOnlyClassIcon end,
                                        set = function(info, val)
                                            info.handler.db.profile.classColorFrameTextureOnlyClassIcon = val
                                            for i = 1, sArenaMixin.maxArenaOpponents do
                                                local frame = info.handler["arena"..i]
                                                if frame then
                                                    frame:UpdateFrameColors()
                                                end
                                            end
                                        end,
                                    },
                                    classColorFrameTextureHealerGreen = {
                                        order = 1.07,
                                        name = L["ClassColor_HealerGreen"],
                                        desc = L["ClassColor_HealerGreen_Desc"],
                                        type = "toggle",
                                        disabled = function(info) return not info.handler.db.profile.classColorFrameTexture end,
                                        get = function(info) return info.handler.db.profile.classColorFrameTextureHealerGreen end,
                                        set = function(info, val)
                                            info.handler.db.profile.classColorFrameTextureHealerGreen = val
                                            for i = 1, sArenaMixin.maxArenaOpponents do
                                                local frame = info.handler["arena"..i]
                                                if frame then
                                                    frame:UpdateFrameColors()
                                                end
                                            end
                                        end,
                                    },
                                    classColorNames = {
                                        order = 1.1,
                                        name = L["Option_ClassColorNames"],
                                        desc = L["ClassColor_NameText_Desc"],
                                        type = "toggle",
                                        width = "full",
                                        get = function(info) return info.handler.db.profile.classColorNames end,
                                        set = function(info, val)
                                            info.handler.db.profile.classColorNames = val
                                            for i = 1, sArenaMixin.maxArenaOpponents do
                                                local frame = info.handler["arena" .. i]
                                                if frame.Name:IsShown() then
                                                    frame:UpdateNameColor()
                                                end
                                            end
                                        end,
                                    },
                                    replaceHealerIcon = {
                                        order = 2,
                                        name = L["Option_ReplaceHealerIcon"],
                                        type = "toggle",
                                        width = "full",
                                        desc = L["Icon_ReplaceHealerWithHealerIcon_Desc"],
                                        get = function(info) return info.handler.db.profile.replaceHealerIcon end,
                                        set = function(info, val)
                                            info.handler.db.profile.replaceHealerIcon = val
                                            info.handler:Test()
                                        end,
                                    },
                                    showNames = {
                                        order = 4,
                                        name = L["Option_ShowNames"],
                                        type = "toggle",
                                        width = "full",
                                        get = function(info) return info.handler.db.profile.showNames end,
                                        set = function(info, val)
                                            info.handler.db.profile.showNames = val
                                            info.handler.db.profile.showArenaNumber = false
                                            for i = 1, sArenaMixin.maxArenaOpponents do
                                                local frame = info.handler["arena" .. i]
                                                frame.Name:SetShown(val)
                                                frame.Name:SetText(frame.tempName or "name")
                                            end
                                        end,
                                    },
                                    showArenaNumber = {
                                        order = 5,
                                        name = L["Option_ShowArenaNumber"],
                                        type = "toggle",
                                        width = "full",
                                        get = function(info) return info.handler.db.profile.showArenaNumber end,
                                        set = function(info, val)
                                            info.handler.db.profile.showArenaNumber = val
                                            info.handler.db.profile.showNames = false
                                            for i = 1, sArenaMixin.maxArenaOpponents do
                                                info.handler["arena" .. i].Name:SetShown(val)
                                                info.handler["arena" .. i].Name:SetText("arena"..i)
                                            end
                                        end,
                                    },
                                    reverseBarsFill = {
                                        order = 6,
                                        name = L["Option_ReverseBarsFill"],
                                        desc = L["Healthbar_ReverseFill_Desc"],
                                        type = "toggle",
                                        width = "full",
                                        get = function(info) return info.handler.db.profile.reverseBarsFill end,
                                        set = function(info, val)
                                            info.handler.db.profile.reverseBarsFill = val
                                            for i = 1, sArenaMixin.maxArenaOpponents do
                                                local frame = info.handler["arena" .. i]
                                                frame.HealthBar:SetReverseFill(val)
                                                frame.PowerBar:SetReverseFill(val)
                                            end
                                        end,
                                    },
                                    hideClassIcon = {
                                        order = 6,
                                        name = L["Option_HideClassIconShowAurasOnly"],
                                        type = "toggle",
                                        width = "full",
                                        desc = L["ClassIcon_HideAndShowOnlyAuras_Desc"],
                                        get = function(info) return info.handler.db.profile.hideClassIcon end,
                                        set = function(info, val)
                                            info.handler.db.profile.hideClassIcon = val
                                            for i = 1, sArenaMixin.maxArenaOpponents do
                                                if val then
                                                    info.handler["arena" .. i].ClassIcon.Texture:SetTexture(nil)
                                                else
                                                    if info.handler["arena" .. i].replaceClassIcon then
                                                        info.handler["arena" .. i].ClassIcon.Texture:SetTexture(info.handler["arena" .. i].tempSpecIcon)
                                                    else
                                                        info.handler["arena" .. i].ClassIcon.Texture:SetTexture(info.handler.classIcons[info.handler["arena" .. i].tempClass])
                                                    end
                                                end
                                            end
                                            info.handler:Test()
                                        end,
                                    },
                                    disableAurasOnClassIcon = {
                                        order = 7,
                                        name = L["Option_DisableAurasOnClassIcon"],
                                        type = "toggle",
                                        width = "full",
                                        desc = L["ClassIcon_DontShowAuras_Desc"],
                                        get = function(info) return info.handler.db.profile.disableAurasOnClassIcon end,
                                        set = function(info, val)
                                            info.handler.db.profile.disableAurasOnClassIcon = val
                                            info.handler:Test()
                                        end,
                                    },
                                    shadowSightTimer = {
                                        order = 7.5,
                                        name = L["Option_ShadowsightTimer"],
                                        desc = L["Option_ShadowsightTimer_Desc"],
                                        type = "toggle",
                                        width = "full",
                                        get = function(info) return info.handler.db.profile.shadowSightTimer end,
                                        set = function(info, val)
                                            info.handler.db.profile.shadowSightTimer = val
                                        end,
                                    },
                                    colorTrinket = {
                                        order = 8,
                                        name = L["Option_ColorTrinket"],
                                        type = "toggle",
                                        width = "full",
                                        desc = L["Trinket_MinimalistDesign_Desc"],
                                        get = function(info) return info.handler.db.profile.colorTrinket end,
                                        set = function(info, val)
                                            info.handler.db.profile.colorTrinket = val
                                            for i = 1, sArenaMixin.maxArenaOpponents do
                                                if val then
                                                    if i <= 2 then
                                                        info.handler["arena" .. i].Trinket.Texture:SetColorTexture(0,1,0)
                                                        info.handler["arena" .. i].Trinket.Cooldown:Clear()
                                                    else
                                                        info.handler["arena" .. i].Trinket.Texture:SetColorTexture(1,0,0)
                                                    end
                                                else
                                                    info.handler["arena" .. i].Trinket.Texture:SetTexture(sArenaMixin.trinketTexture)
                                                end
                                            end
                                        end,
                                    },
                                    colorMysteryGray = {
                                        order = 9,
                                        name = L["Option_ColorNonVisibleFramesGray"],
                                        type = "toggle",
                                        width = "full",
                                        desc = L["MysteryPlayer_GrayBars_Desc"],
                                        get = function(info) return info.handler.db.profile.colorMysteryGray end,
                                        set = function(info, val)
                                            info.handler.db.profile.colorMysteryGray = val
                                        end,
                                    },
                                    showDecimalsClassIcon = {
                                        order = 10,
                                        name = L["Option_ShowDecimalsOnClassIcon"],
                                        desc = L["Option_ShowDecimalsOnClassIcon_Desc"],
                                        type = "toggle",
                                        width = 1.4,
                                        get = function(info) return info.handler.db.profile.showDecimalsClassIcon end,
                                        set = function(info, val)
                                            info.handler.db.profile.showDecimalsClassIcon = val
                                            info.handler:SetupCustomCD()
                                        end
                                    },
                                    decimalThreshold = {
                                        order = 11,
                                        name = L["Option_DecimalThreshold"],
                                        desc = L["Cooldown_ShowDecimalsThreshold_Desc"],
                                        type = "range",
                                        min = 1,
                                        max = 10,
                                        step = 0.1,
                                        width = 0.75,
                                        disabled = function(info) return not info.handler.db.profile.showDecimalsClassIcon end,
                                        get = function(info) return info.handler.db.profile.decimalThreshold or 6 end,
                                        set = function(info, val)
                                            info.handler.db.profile.decimalThreshold = val
                                            info.handler:UpdateDecimalThreshold()
                                            info.handler:SetupCustomCD()
                                        end
                                    },

                                },
                            },
                            swipeAnimations = {
                                order = 7,
                                name = L["Option_SwipeAnimations"],
                                type = "group",
                                inline = true,
                                args = {
                                    disableSwipeEdge = {
                                        order = 0,
                                        name = L["Option_DisableCooldownSwipeEdge"],
                                        type = "toggle",
                                        width = "full",
                                        desc = L["Cooldown_DisableBrightEdge_Desc"],
                                        get = function(info) return info.handler.db.profile.disableSwipeEdge end,
                                        set = function(info, val)
                                            info.handler.db.profile.disableSwipeEdge = val
                                            for i = 1, sArenaMixin.maxArenaOpponents do
                                                info.handler["arena" .. i]:UpdateSwipeEdgeSettings()
                                            end
                                            -- Update DR settings for current layout
                                            local currentLayout = info.handler.db.profile.currentLayout
                                            if currentLayout and info.handler.db.profile.layoutSettings[currentLayout] then
                                                local drSettings = info.handler.db.profile.layoutSettings[currentLayout].dr
                                                if drSettings then
                                                    info.handler:UpdateDRSettings(drSettings, info)
                                                end
                                            end
                                        end,
                                    },
                                    disableClassIconSwipe = {
                                        order = 1,
                                        name = L["Option_DisableClassIconSwipe"],
                                        type = "toggle",
                                        width = "full",
                                        desc = L["Cooldown_DisableClassIconSwipe_Desc"],
                                        get = function(info) return info.handler.db.profile.disableClassIconSwipe end,
                                        set = function(info, val)
                                            info.handler.db.profile.disableClassIconSwipe = val
                                            for i = 1, sArenaMixin.maxArenaOpponents do
                                                info.handler["arena" .. i]:UpdateClassIconSwipeSettings()
                                            end
                                        end,
                                    },
                                    disableDRSwipe = {
                                        order = 2,
                                        name = L["Option_DisableDRSwipeAnimation"],
                                        desc = L["Cooldown_DisableDRSwipe_Desc"],
                                        type = "toggle",
                                        width = "full",
                                        get = function(info)
                                            return info.handler.db.profile.disableDRSwipe
                                        end,
                                        set = function(info, val)
                                            info.handler.db.profile.disableDRSwipe = val
                                            -- Update DR settings for current layout
                                            local currentLayout = info.handler.db.profile.currentLayout
                                            if currentLayout and info.handler.db.profile.layoutSettings[currentLayout] then
                                                local drSettings = info.handler.db.profile.layoutSettings[currentLayout].dr
                                                if drSettings then
                                                    info.handler:UpdateDRSettings(drSettings, info)
                                                end
                                            end
                                        end,
                                    },
                                    disableTrinketRacialSwipe = {
                                        order = 3,
                                        name = L["Option_DisableTrinketRacialSwipe"],
                                        type = "toggle",
                                        width = "full",
                                        desc = L["Cooldown_DisableTrinketRacialSwipe_Desc"],
                                        get = function(info) return info.handler.db.profile.disableTrinketRacialSwipe end,
                                        set = function(info, val)
                                            info.handler.db.profile.disableTrinketRacialSwipe = val
                                            for i = 1, sArenaMixin.maxArenaOpponents do
                                                info.handler["arena" .. i]:UpdateTrinketRacialSwipeSettings()
                                            end
                                        end,
                                    },
                                    invertClassIconCooldown = {
                                        order = 4,
                                        name = L["Option_ReverseClassIconSwipe"],
                                        type = "toggle",
                                        width = "full",
                                        desc = L["Cooldown_ReverseClassIcon_Desc"],
                                        disabled = function(info) return info.handler.db.profile.disableClassIconSwipe end,
                                        get = function(info) return info.handler.db.profile.invertClassIconCooldown end,
                                        set = function(info, val)
                                            info.handler.db.profile.invertClassIconCooldown = val
                                            for i = 1, sArenaMixin.maxArenaOpponents do
                                                info.handler["arena" .. i]:UpdateClassIconCooldownReverse()
                                            end
                                        end,
                                    },
                                    invertDRCooldown = {
                                        order = 5,
                                        name = L["Option_ReverseDRSwipeAnimation"],
                                        desc = L["Cooldown_ReverseDR_Desc"],
                                        type = "toggle",
                                        width = "full",
                                        disabled = function(info) return info.handler.db.profile.drSwipeOff end,
                                        get = function(info) return info.handler.db.profile.invertDRCooldown end,
                                        set = function(info, val)
                                            info.handler.db.profile.invertDRCooldown = val
                                            -- Update DR settings which now handles cooldown reverse
                                            local layoutdb = info.handler.layoutdb
                                            if layoutdb and layoutdb.dr then
                                                info.handler:UpdateDRSettings(layoutdb.dr)
                                            end
                                        end
                                    },
                                    invertTrinketRacialCooldown = {
                                        order = 6,
                                        name = L["Option_ReverseTrinketRacialSwipe"],
                                        type = "toggle",
                                        width = "full",
                                        desc = L["Cooldown_ReverseTrinketRacial_Desc"],
                                        disabled = function(info) return info.handler.db.profile.disableTrinketRacialSwipe end,
                                        get = function(info) return info.handler.db.profile.invertTrinketRacialCooldown end,
                                        set = function(info, val)
                                            info.handler.db.profile.invertTrinketRacialCooldown = val
                                            for i = 1, sArenaMixin.maxArenaOpponents do
                                                info.handler["arena" .. i]:UpdateTrinketRacialCooldownReverse()
                                            end
                                        end,
                                    },
                                },
                            },
                            masque = {
                                order = 8,
                                name = L["Option_Miscellaneous"],
                                type = "group",
                                inline = true,
                                args = {
                                    enableMasque = {
                                        order = 1,
                                        name = L["Option_EnableMasqueSupport"],
                                        desc = L["Masque_Support_Desc"],
                                        type = "toggle",
                                        width = "full",
                                        get = function(info) return info.handler.db.profile.enableMasque end,
                                        set = function(info, val)
                                            info.handler.db.profile.enableMasque = val
                                            info.handler:AddMasqueSupport()
                                            info.handler:Test()
                                        end
                                    },
                                    removeUnequippedTrinketTexture = {
                                        order = 2,
                                        name = L["Option_RemoveUnEquippedTrinketTexture"],
                                        desc = L["Trinket_HideWhenNoTrinket_Desc"],
                                        type = "toggle",
                                        width = "full",
                                        get = function(info) return info.handler.db.profile.removeUnequippedTrinketTexture end,
                                        set = function(info, val)
                                            info.handler.db.profile.removeUnequippedTrinketTexture = val
                                            info.handler:UpdateNoTrinketTexture()
                                        end
                                    },
                                    desaturateTrinketCD = {
                                        order = 2.1,
                                        name = L["Option_DesaturateTrinketCD"],
                                        desc = L["Trinket_DesaturateOnCD_Desc"],
                                        type = "toggle",
                                        width = "full",
                                        get = function(info) return info.handler.db.profile.desaturateTrinketCD end,
                                        set = function(info, val)
                                            info.handler.db.profile.desaturateTrinketCD = val
                                        end
                                    },
                                    desaturateDispelCD = {
                                        order = 2.2,
                                        name = L["Option_DesaturateDispelCD"],
                                        desc = L["Dispel_DesaturateOnCD_Desc"],
                                        type = "toggle",
                                        width = "full",
                                        get = function(info) return info.handler.db.profile.desaturateDispelCD end,
                                        set = function(info, val)
                                            info.handler.db.profile.desaturateDispelCD = val
                                        end
                                    },
                                    disableOvershields = {
                                        order = 2.3,
                                        name = L["Option_DisableOvershields"],
                                        desc = L["Option_DisableOvershields_Desc"],
                                        type = "toggle",
                                        width = "full",
                                        get = function(info) return info.handler.db.profile.disableOvershields end,
                                        set = function(info, val)
                                            info.handler.db.profile.disableOvershields = val
                                        end
                                    },
                                },
                            },
                        },
                    },
                    drGroup = {
                        order = 2,
                        name = L["Category_DiminishingReturns"],
                        type = "group",
                        args = {
                            drOptions = {
                                order = 1,
                                type = "group",
                                name = L["Option_Miscellaneous"],
                                inline = true,
                                args = {
                                    drResetTime = {
                                        order = 1,
                                        name = L["Option_DRResetTime"],
                                        disabled = function() return isMidnight end,
                                        desc = isRetail and
                                        "Blizzard no longer uses a dynamic timer for DR resets, it is 18 seconds\n\nBy default sArena has a 0.5 leeway added so a total of 18.5 seconds." or
                                        "Blizzard uses a dynamic timer for DR resets, ranging between 15 and 20 seconds.\n\nSetting this to 20 seconds is the safest option, but you can lower it slightly (e.g., 18.5) for more aggressive tracking.",
                                        type = "range",
                                        min = isRetail and 18 or 15,
                                        max = 20,
                                        step = 0.1,
                                        width = "normal",
                                        get = function(info)
                                            return info.handler.db.profile.drResetTime or (isRetail and 18.5 or 20)
                                        end,
                                        set = function(info, val)
                                            info.handler.db.profile.drResetTime = val
                                            info.handler:UpdateDRTimeSetting()
                                        end,
                                    },
                                    drResetTime_break = {
                                        order = 1.1,
                                        type = "description",
                                        name = " ",
                                        width = "full",
                                    },
                                    showDecimalsDR = {
                                        order = 2,
                                        name = L["Option_ShowDecimalsOnDRs"],
                                        desc = L["Option_ShowDecimalsOnDRs_Desc"],
                                        type = "toggle",
                                        width = 1.2,
                                        get = function(info) return info.handler.db.profile.showDecimalsDR end,
                                        set = function(info, val)
                                            info.handler.db.profile.showDecimalsDR = val
                                            info.handler:SetupCustomCD()
                                        end
                                    },
                                    decimalThresholdDR = {
                                        order = 2.5,
                                        name = L["Option_DecimalThreshold"],
                                        desc = L["Cooldown_ShowDecimalsThreshold_Desc"],
                                        type = "range",
                                        min = 1,
                                        max = 10,
                                        step = 0.1,
                                        width = 0.75,
                                        disabled = function(info) return not info.handler.db.profile.showDecimalsDR end,
                                        get = function(info) return info.handler.db.profile.decimalThreshold or 6 end,
                                        set = function(info, val)
                                            info.handler.db.profile.decimalThreshold = val
                                            info.handler:UpdateDecimalThreshold()
                                            info.handler:SetupCustomCD()
                                        end
                                    },
                                    colorDRCooldownText = {
                                        order = 3,
                                        name = L["Option_ColorDRCooldownText"],
                                        desc = isMidnight and L["Option_ColorDRCooldownText_Desc_Midnight"] or L["Option_ColorDRCooldownText_Desc"],
                                        type = "toggle",
                                        width = "full",
                                        get = function(info) return info.handler.db.profile.colorDRCooldownText end,
                                        set = function(info, val)
                                            info.handler.db.profile.colorDRCooldownText = val
                                            if not val then
                                                for i = 1, sArenaMixin.maxArenaOpponents do
                                                    local frame = info.handler["arena" .. i]
                                                    frame:ResetDRCooldownTextColors()
                                                end
                                            end
                                            info.handler:SetupCustomCD()
                                            info.handler:Test()
                                        end
                                    },
                                },
                            },
                            categories = {
                                order = 2,
                                name = L["Option_DRCategories"],
                                type = "group",
                                disabled = function() return isMidnight end,
                                inline = true,
                                args = {
                                    drCategoriesPerClass = {
                                        order = 1,
                                        name = L["Option_PerClass"],
                                        desc = L["DR_ClassSpecific_Desc"],
                                        type = "toggle",
                                        get = function(info) return info.handler.db.profile.drCategoriesPerClass end,
                                        set = function(info, val)
                                            info.handler.db.profile.drCategoriesPerClass = val
                                            if val then
                                                info.handler.db.profile.drCategoriesPerSpec = false
                                            end
                                            LibStub("AceConfigRegistry-3.0"):NotifyChange("sArena")
                                        end,
                                    },
                                    drCategoriesPerSpec = {
                                        order = 2,
                                        name = L["Option_PerSpec"],
                                        desc = L["DR_SpecSpecific_Desc"],
                                        type = "toggle",
                                        get = function(info) return info.handler.db.profile.drCategoriesPerSpec end,
                                        set = function(info, val)
                                            info.handler.db.profile.drCategoriesPerSpec = val
                                            if val then
                                                info.handler.db.profile.drCategoriesPerClass = false
                                            end
                                            LibStub("AceConfigRegistry-3.0"):NotifyChange("sArena")
                                        end,
                                    },

                                    categoriesMultiselect = {
                                        order = 4,
                                        name = function(info)
                                            local db = info.handler.db
                                            if db.profile.drCategoriesPerSpec then
                                                local className = select(1, UnitClass("player")) or L["Unknown"]
                                                local classKey = select(2, UnitClass("player"))
                                                local specName = sArenaMixin.playerSpecName or L["Unknown"]
                                                local classColor = RAID_CLASS_COLORS[classKey]
                                                local coloredText = specName .. " " .. className
                                                if classColor then
                                                    coloredText = "|c" .. classColor.colorStr .. coloredText .. "|r"
                                                end
                                                return string.format(L["DR_CategoriesPerSpec"], coloredText)
                                            elseif db.profile.drCategoriesPerClass then
                                                local className = select(1, UnitClass("player")) or L["Unknown"]
                                                local classKey = select(2, UnitClass("player"))
                                                local classColor = RAID_CLASS_COLORS[classKey]
                                                local coloredText = className
                                                if classColor then
                                                    coloredText = "|c" .. classColor.colorStr .. coloredText .. "|r"
                                                end
                                                return string.format(L["DR_CategoriesPerClass"], coloredText)
                                            else
                                                return L["DR_CategoriesGlobal"]
                                            end
                                        end,
                                        type = "multiselect",
                                        get = function(info, key) 
                                            local db = info.handler.db
                                            if db.profile.drCategoriesPerSpec then
                                                local specKey = sArenaMixin.playerSpecID or 0
                                                local perSpec = db.profile.drCategoriesSpec or {}
                                                local specCategories = perSpec[specKey] or {}
                                                if specCategories[key] ~= nil then
                                                    return specCategories[key]
                                                else
                                                    return db.profile.drCategories[key]
                                                end
                                            elseif db.profile.drCategoriesPerClass then
                                                local classKey = sArenaMixin.playerClass
                                                local perClass = db.profile.drCategoriesClass or {}
                                                local classCategories = perClass[classKey] or {}
                                                if classCategories[key] ~= nil then
                                                    return classCategories[key]
                                                else
                                                    return db.profile.drCategories[key]
                                                end
                                            else
                                                return db.profile.drCategories[key]
                                            end
                                        end,
                                        set = function(info, key, val) 
                                            local db = info.handler.db
                                            if db.profile.drCategoriesPerSpec then
                                                db.profile.drCategoriesSpec = db.profile.drCategoriesSpec or {}
                                                local specKey = sArenaMixin.playerSpecID or 0
                                                db.profile.drCategoriesSpec[specKey] = db.profile.drCategoriesSpec[specKey] or {}
                                                db.profile.drCategoriesSpec[specKey][key] = val
                                            elseif db.profile.drCategoriesPerClass then
                                                db.profile.drCategoriesClass = db.profile.drCategoriesClass or {}
                                                local classKey = sArenaMixin.playerClass
                                                db.profile.drCategoriesClass[classKey] = db.profile.drCategoriesClass[classKey] or {}
                                                db.profile.drCategoriesClass[classKey][key] = val
                                            else
                                                db.profile.drCategories[key] = val
                                            end
                                        end,
                                        values = drCategoryDisplay,
                                    },
                                },
                            },
                            dynamicIcons = {
                                order = 3,
                                name = L["Option_DRIcons"],
                                disabled = function() return isMidnight end,
                                type = "group",
                                inline = true,
                                args = {
                                    drStaticIcons = {
                                        order = 1,
                                        name = L["Option_EnableStaticIcons"],
                                        desc = L["DR_FixedIcons_Desc"],
                                        type = "toggle",
                                        get = function(info) return info.handler.db.profile.drStaticIcons end,
                                        set = function(info, val)
                                            info.handler.db.profile.drStaticIcons = val
                                            LibStub("AceConfigRegistry-3.0"):NotifyChange("sArena")
                                        end,
                                    },
                                    dynamicIconsPerClass = {
                                        order = 2,
                                        name = L["Option_PerClass"],
                                        desc = L["DR_ClassSpecificIcons_Desc"],
                                        type = "toggle",
                                        disabled = function(info) return not info.handler.db.profile.drStaticIcons end,
                                        get = function(info) return info.handler.db.profile.drStaticIconsPerClass end,
                                        set = function(info, val)
                                            info.handler.db.profile.drStaticIconsPerClass = val
                                            if val then
                                                info.handler.db.profile.drStaticIconsPerSpec = false
                                            end
                                            LibStub("AceConfigRegistry-3.0"):NotifyChange("sArena")
                                        end,
                                    },
                                    dynamicIconsPerSpec = {
                                        order = 3,
                                        name = L["Option_PerSpec"],
                                        desc = L["DR_SpecSpecificIcons_Desc"],
                                        type = "toggle",
                                        disabled = function(info) return not info.handler.db.profile.drStaticIcons end,
                                        get = function(info) return info.handler.db.profile.drStaticIconsPerSpec end,
                                        set = function(info, val)
                                            info.handler.db.profile.drStaticIconsPerSpec = val
                                            if val then
                                                info.handler.db.profile.drStaticIconsPerClass = false
                                            end
                                            LibStub("AceConfigRegistry-3.0"):NotifyChange("sArena")
                                        end,
                                    },
                                    staticIconsSeparator = {
                                        order = 4,
                                        name = "",
                                        type = "header",
                                    },
                                                                drIconsSection = {
                                order = 4,
                                type = "group",
                                name = "",
                                inline = true,
                                disabled = function(info) return not info.handler.db.profile.drStaticIcons end,
                                get = function(info)
                                    local key = info[#info]
                                    local db = info.handler.db
                                    if db.profile.drStaticIconsPerSpec then
                                        local specKey = sArenaMixin.playerSpecID or 0
                                        local perSpec = db.profile.drIconsPerSpec or {}
                                        local specIcons = perSpec[specKey] or {}
                                        return tostring(specIcons[key] or "")
                                    elseif db.profile.drStaticIconsPerClass then
                                        local classKey = sArenaMixin.playerClass
                                        local perClass = db.profile.drIconsPerClass or {}
                                        local classIcons = perClass[classKey] or {}
                                        return tostring(classIcons[key] or "")
                                    else
                                        return tostring(db.profile.drIcons[key] or drIcons[key])
                                    end
                                end,
                                set = function(info, value)
                                    local key = info[#info]
                                    local db = info.handler.db
                                    local num = tonumber(value)
                                    if db.profile.drStaticIconsPerSpec then
                                        db.profile.drIconsPerSpec = db.profile.drIconsPerSpec or {}
                                        local specKey = sArenaMixin.playerSpecID or 0
                                        db.profile.drIconsPerSpec[specKey] = db.profile.drIconsPerSpec[specKey] or {}
                                        db.profile.drIconsPerSpec[specKey][key] = num or value
                                    elseif db.profile.drStaticIconsPerClass then
                                        db.profile.drIconsPerClass = db.profile.drIconsPerClass or {}
                                        local classKey = sArenaMixin.playerClass
                                        db.profile.drIconsPerClass[classKey] = db.profile.drIconsPerClass[classKey] or {}
                                        db.profile.drIconsPerClass[classKey][key] = num or value
                                    else
                                        db.profile.drIcons = db.profile.drIcons or {}
                                        db.profile.drIcons[key] = num or value
                                    end
                                    LibStub("AceConfigRegistry-3.0"):NotifyChange("sArena")
                                end,
                                args = setDRIcons(),
                            },
                                },
                            },
                        },
                    },
                    racialGroup = {
                        order = 3,
                        name = L["Category_Racials"],
                        type = "group",
                        args = (function()
                            local args = {
                                categories = {
                                    order = 1,
                                    name = L["Option_Categories"],
                                    type = "multiselect",
                                    get = function(info, key) return info.handler.db.profile.racialCategories[key] end,
                                    set = function(info, key, val) info.handler.db.profile.racialCategories[key] = val end,
                                    values = racialCategories,
                                },
                            }
                            args.racialOptions = {
                                order = 2,
                                type = "group",
                                name = L["Options"],
                                inline = true,
                                args = {
                                    swapRacialTrinket = {
                                        order = 1,
                                        name = L["Option_SwapMissingTrinketWithRacial"],
                                        desc = L["Racial_ShowInTrinketSlot_Desc"],
                                        type = "toggle",
                                        width = "full",
                                        get = function(info) return info.handler.db.profile.swapRacialTrinket end,
                                        set = function(info, val)
                                            info.handler.db.profile.swapRacialTrinket = val
                                        end,
                                    },
                                    forceShowTrinketOnHuman = {
                                        order = 2,
                                        name = L["Option_ForceShowTrinketOnHuman"],
                                        desc = L["Human_AlwaysShowTrinket_Desc"],
                                        type = "toggle",
                                        width = "full",
                                        hidden = function() return isRetail end,
                                        get = function(info) return info.handler.db.profile.forceShowTrinketOnHuman end,
                                        set = function(info, val)
                                            info.handler.db.profile.forceShowTrinketOnHuman = val
                                            if val then
                                                info.handler.db.profile.replaceHumanRacialWithTrinket = false
                                            end
                                        end,
                                    },
                                    replaceHumanRacialWithTrinket = {
                                        order = 3,
                                        name = L["Option_ReplaceHumanRacialWithTrinket"],
                                        desc = L["Option_ReplaceHumanRacialWithTrinket_Desc"],
                                        type = "toggle",
                                        width = "full",
                                        hidden = function() return isRetail end,
                                        get = function(info) return info.handler.db.profile.replaceHumanRacialWithTrinket end,
                                        set = function(info, val)
                                            info.handler.db.profile.replaceHumanRacialWithTrinket = val
                                            if val then
                                                info.handler.db.profile.forceShowTrinketOnHuman = false
                                            end
                                        end,
                                    },
                                }
                            }

                            return args
                        end)(),
                    },
                    dispelGroup = {
                        order = 4,
                        name = L["Category_Dispels"],
                        disabled = function() return isMidnight end,
                        type = "group",
                        args = (function()
                            local args = {
                                showDispels = {
                                    order = 0,
                                    name = L["Option_ShowDispels"],
                                    desc = L["Option_ShowDispels_Desc"],
                                    type = "toggle",
                                    width = "full",
                                    get = function(info) return info.handler.db.profile.showDispels end,
                                    set = function(info, val)
                                        info.handler.db.profile.showDispels = val
                                        info.handler:Test()
                                    end,
                                },
                                spacer0 = {
                                    order = 0.5,
                                    type = "description",
                                    name = "",
                                    width = "full",
                                },
                            }

                            local healerDispels = {}
                            local dpsDispels = {}

                            for spellID, data in pairs(sArenaMixin.dispelData or {}) do
                                if data.healer or data.sharedSpecSpellID then
                                    healerDispels[spellID] = data
                                end
                                if not data.healer or data.sharedSpecSpellID then
                                    dpsDispels[spellID] = data
                                end
                            end

                            local order = 1

                            if next(healerDispels) then
                                args["healer_dispels"] = {
                                    order = order,
                                    name = L["Option_HealerDispels"],
                                    type = "group",
                                    inline = true,
                                    disabled = function(info) return not info.handler.db.profile.showDispels end,
                                    args = {}
                                }
                                order = order + 1

                                local healerOrder = 1
                                for spellID, data in pairs(healerDispels) do
                                    -- For MoP shared spells, use separate setting key
                                    local settingKey = spellID
                                    if not isRetail and data.sharedSpecSpellID then
                                        settingKey = spellID .. "_healer"
                                    end

                                    args["healer_dispels"].args["spell_" .. spellID] = {
                                        order = healerOrder,
                                        name = function()
                                            local spellName = GetSpellInfoCompat(spellID)
                                            return "|T" .. (data.texture or "") .. ":16|t " .. (spellName or data.name)
                                        end,
                                        type = "toggle",
                                        disabled = function(info) return not info.handler.db.profile.showDispels end,
                                        get = function(info) return info.handler.db.profile.dispelCategories[settingKey] end,
                                        set = function(info, val)
                                            info.handler.db.profile.dispelCategories[settingKey] = val
                                            for i = 1, 3 do
                                                local frame = info.handler["arena" .. i]
                                                if frame then
                                                    frame:UpdateDispel()
                                                end
                                            end
                                        end,
                                        desc = function()
                                            local spellName = GetSpellInfoCompat(spellID)
                                            local spellDesc = GetSpellDescriptionCompat(spellID)

                                            spellName = spellName or data.name or L["Unknown_Spell"]
                                            local cooldownText = data.cooldown and string.format(L["Cooldown_Seconds"], data.cooldown) or ""

                                            local tooltipLines = {}
                                            table.insert(tooltipLines, "|cFFFFD700" .. spellName .. "|r")
                                            table.insert(tooltipLines, "|cFF87CEEB" .. data.classes .. "|r")
                                            if spellDesc and spellDesc ~= "" then
                                                table.insert(tooltipLines, spellDesc)
                                            end
                                            if cooldownText ~= "" then
                                                table.insert(tooltipLines, "|cFF00FF00" .. cooldownText .. "|r")
                                            end
                                            table.insert(tooltipLines, "|cFF808080Spell ID: " .. spellID .. "|r")

                                            return table.concat(tooltipLines, "\n\n")
                                        end,
                                    }
                                    healerOrder = healerOrder + 1
                                end
                            end

                            if next(dpsDispels) then
                                args["dps_dispels"] = {
                                    order = order,
                                    name = L["Option_DPSDispels"],
                                    type = "group",
                                    inline = true,
                                    disabled = function(info) return not info.handler.db.profile.showDispels end,
                                    args = {
                                        description = {
                                            order = 1,
                                            type = "description",
                                            name = L["Option_DPSDispelsNote"],
                                            fontSize = "medium",
                                        }
                                    }
                                }
                                order = order + 1

                                local dpsOrder = 2
                                for spellID, data in pairs(dpsDispels) do

                                    local settingKey = spellID
                                    if not sArenaMixin.isRetail and data.sharedSpecSpellID then
                                        settingKey = spellID .. "_dps"
                                    end

                                    args["dps_dispels"].args["spell_" .. spellID] = {
                                        order = dpsOrder,
                                        name = function()
                                            local spellName = GetSpellInfoCompat(spellID)
                                            return "|T" .. (data.texture or "134400") .. ":16|t " .. (spellName or data.name)
                                        end,
                                        type = "toggle",
                                        disabled = function(info) return not info.handler.db.profile.showDispels end,
                                        get = function(info) return info.handler.db.profile.dispelCategories[settingKey] end,
                                        set = function(info, val)
                                            info.handler.db.profile.dispelCategories[settingKey] = val
                                            for i = 1, 3 do
                                                local frame = info.handler["arena" .. i]
                                                if frame then
                                                    frame:UpdateDispel()
                                                end
                                            end
                                        end,
                                        desc = function()
                                            local spellName = GetSpellInfoCompat(spellID)
                                            local spellDesc = GetSpellDescriptionCompat(spellID)

                                            spellName = spellName or data.name or L["Unknown_Spell"]
                                            local cooldownText = data.cooldown and string.format(L["Cooldown_Seconds"], data.cooldown) or ""

                                            local tooltipLines = {}
                                            table.insert(tooltipLines, "|cFFFFD700" .. spellName .. "|r")
                                            table.insert(tooltipLines, "|cFF87CEEB" .. data.classes .. "|r")
                                            if spellDesc and spellDesc ~= "" then
                                                table.insert(tooltipLines, spellDesc)
                                            end
                                            if cooldownText ~= "" then
                                                table.insert(tooltipLines, "|cFF00FF00" .. cooldownText .. "|r")
                                            end
                                            table.insert(tooltipLines, "|cFF808080Spell ID: " .. spellID .. "|r")
                                            table.insert(tooltipLines, "|cFFFFA500" .. L["Dispel_ShowsAfterUse"] .. "|r")

                                            return table.concat(tooltipLines, "\n\n")
                                        end,
                                    }
                                    dpsOrder = dpsOrder + 1
                                end
                            end

                            args["betaNotice"] = {
                                order = 999,
                                type = "description",
                                name = L["Option_DispelsBetaNotice"],
                                fontSize = "medium",
                                width = "full",
                            }

                            return args
                        end)(),
                    },
                },
            },
            ImportOtherForkSettings = {
                order = 7,
                name = L["Option_OthersArena"],
                desc = L["Option_OthersArena_Desc"],
                type = "group",
                args = {
                    description = {
                        order = 1,
                        type = "description",
                        name = L["Option_ImportDescription"],
                        fontSize = "medium",
                    },
                    convertButton = {
                        order = 2,
                        type = "execute",
                        name = L["Option_ImportSettings"],
                        desc = L["Option_ImportSettings_Desc"],
                        func = sArenaMixin.ImportOtherForkSettings,
                        width = "normal",
                        disabled = function() return sArenaMixin.conversionInProgress end,
                    },
                    conversionStatus = {
                        order = 2.5,
                        type = "description",
                        name = function() return sArenaMixin.conversionStatusText or "" end,
                        fontSize = "medium",
                        hidden = function() return not sArenaMixin.conversionStatusText or sArenaMixin.conversionStatusText == "" end,
                    },
                },
            },
            midnightExpansion = {
                order = 8,
                name = "|cffcc66ffMidnight|r |T136221:16:16|t",
                desc = L["Option_MidnightPlans_Desc"],
                type = "group",
                args = {
                    description = {
                        order = 1,
                        type = "description",
                        name = midnightInfo,
                        fontSize = "medium",
                        width = "full",
                    },
                },
            },
            shareProfile = {
                order = 9,
                name = L["Option_ShareProfile"],
                desc = L["Option_ShareProfile_Desc"],
                type = "group",
                args = {
                    exportHeader = {
                        order = 0,
                        type = "description",
                        name = L["Option_ExportProfileHeader"],
                        fontSize = "large",
                    },
                    exportButton = {
                        order = 1,
                        name = L["Option_ExportCurrentProfile"],
                        type = "execute",
                        func = function(info)
                            local exportString, err = sArenaMixin:ExportProfile()
                            if not err then
                                sArenaMixin.exportString = exportString
                                sArenaMixin.importInputText = ""
                                LibStub("AceConfigRegistry-3.0"):NotifyChange("sArena")
                                C_Timer.After(0.1, function()
                                    local AceGUI = LibStub("AceGUI-3.0")
                                    for i = 1, AceGUI:GetWidgetCount("MultiLineEditBox") do
                                        local editBox = _G[("MultiLineEditBox%dEdit"):format(i)]
                                        if editBox and editBox:IsVisible() then
                                            local text = editBox:GetText()
                                            if text and text:match("^!sArena:") then
                                                editBox:SetFocus()
                                                editBox:HighlightText(0, text:len())
                                                break
                                            end
                                        end
                                    end
                                end)
                            else
                                sArenaMixin:Print(L["Message_ExportFailed"], err)
                            end
                        end,
                        width = "normal",
                    },
                    exportText = {
                        order = 2,
                        name = L["Option_ExportString"],
                        type = "input",
                        desc = L["Option_ExportString_Desc"],
                        width = "full",
                        multiline = 5,
                        get = function()
                            return sArenaMixin.exportString or ""
                        end,
                        set = function() end,
                    },
                    spacer = {
                        order = 3,
                        type = "description",
                        name = " ",
                    },
                    importHeader = {
                        order = 4,
                        type = "description",
                        name = L["Option_ImportProfileHeader"],
                        fontSize = "large",
                    },
                    importInput = {
                        order = 5,
                        name = L["Option_PasteProfileString"],
                        desc = L["Option_PasteProfileString_Desc"],
                        type = "input",
                        width = "full",
                        multiline = 5,
                        get = function()
                            return sArenaMixin.importInputText or ""
                        end,
                        set = function(info, val)
                            sArenaMixin.importInputText = val
                            local str = sArenaMixin.importInputText
                            local success, err = sArenaMixin:ImportProfile(str)
                            if not success then
                                sArenaMixin:Print(L["Message_ImportFailed"], err)
                            else
                                sArena_ReloadedDB.reOpenOptions = true
                            end
                        end,
                    },
                    spacer2 = {
                        order = 6,
                        type = "description",
                        name = " ",
                    },
                    streamerProfilesHeader = {
                        order = 7,
                        type = "description",
                        name = L["Option_StreamerProfilesHeader"],
                        fontSize = "large",
                    },
                    streamerProfilesDesc = {
                        order = 8,
                        type = "description",
                        name = function(info)
                            local name, realm = UnitName("player")
                            realm = realm or GetRealmName()
                            local fullKey = name .. " - " .. realm
                            local currentProfileKey = sArena_ReloadedDB.profileKeys[fullKey] or "Default"
                            return string.format(L["Option_StreamerProfiles_Desc"], currentProfileKey)
                        end,
                        fontSize = "medium",
                    },
                    streamerProfilesGroup = {
                        order = 9,
                        type = "group",
                        name = "",
                        inline = true,
                        args = (function()
                            local args = {}
                            
                            -- Class colors and icons
                            local CLASS_COLORS = {
                                ROGUE = "|cfffff569",
                                WARRIOR = "|cffc79c6e",
                                MAGE = "|cff40c7eb",
                                DRUID = "|cffff7d0a",
                                HUNTER = "|cffabd473",
                                PRIEST = "|cffffffff",
                                WARLOCK = "|cff8787ed",
                                SHAMAN = "|cff0070de",
                                PALADIN = "|cfff58cba",
                                DEATHKNIGHT = "|cffc41f3b",
                                MONK = "|cff00ff96",
                                DEMONHUNTER = "|cffa330c9",
                                EVOKER = "|cff33937f",
                            }
                            
                            local CLASS_ICONS = {
                                ROGUE = "groupfinder-icon-class-rogue",
                                WARRIOR = "groupfinder-icon-class-warrior",
                                MAGE = "groupfinder-icon-class-mage",
                                DRUID = "groupfinder-icon-class-druid",
                                HUNTER = "groupfinder-icon-class-hunter",
                                PRIEST = "groupfinder-icon-class-priest",
                                WARLOCK = "groupfinder-icon-class-warlock",
                                SHAMAN = "groupfinder-icon-class-shaman",
                                PALADIN = "groupfinder-icon-class-paladin",
                                DEATHKNIGHT = "groupfinder-icon-class-deathknight",
                                MONK = "groupfinder-icon-class-monk",
                                DEMONHUNTER = "groupfinder-icon-class-demonhunter",
                                EVOKER = "groupfinder-icon-class-evoker",
                            }
                            
                            -- Create a sorted copy of profiles (alphabetically by name)
                            local sortedProfiles = {}
                            for _, profile in ipairs(sArenaMixin.streamProfiles) do
                                table.insert(sortedProfiles, profile)
                            end
                            table.sort(sortedProfiles, function(a, b)
                                return a.name < b.name
                            end)
                            
                            -- Dynamically generate buttons from sorted streamProfiles table
                            for order, profile in ipairs(sortedProfiles) do
                                local key = profile.name:gsub(" ", ""):lower()
                                local color = CLASS_COLORS[profile.class] or "|cffffffff"
                                local icon = CLASS_ICONS[profile.class] or "groupfinder-icon-role-leader"
                                
                                args[key] = {
                                    order = order,
                                    name = string.format("|A:%s:16:16|a %s%s|r", icon, color, profile.name),
                                    desc = string.format(L["Option_ImportProfile_Desc"], profile.name, color, profile.stream),
                                    type = "execute",
                                    func = function(info)
                                        info.handler:ImportStreamerProfile(profile.name:gsub(" ", ""), profile.profileString, profile.name, color)
                                    end,
                                    width = "normal",
                                }
                            end
                            return args
                        end)(),
                    },
                },
            }
        },
    }
end

