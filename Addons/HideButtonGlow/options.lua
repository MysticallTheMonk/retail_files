local addonName, HideButtonGlow = ...

local tonumber, GetSpellName, GetSpellInfo = tonumber, C_Spell.GetSpellName, C_Spell.GetSpellInfo
local L = LibStub("AceLocale-3.0"):GetLocale("HideButtonGlow")

LibStub("AceConfigRegistry-3.0"):RegisterOptionsTable(addonName, {
    order = 1,
    type = "group",
    name = addonName,
    args = {
        general = {
            order = 1,
            type = "group",
            name = L.options,
            args = {
                spacer = {
                    order = 1,
                    type = "description",
                    name = ""
                },
                hideAll = {
                    order = 2,
                    type = "toggle",
                    name = L.hide_all,
                    desc = L.hide_all_desc,
                    get = function()
                        return HideButtonGlowDB.hideAll
                    end,
                    set = function()
                        HideButtonGlowDB.hideAll = not HideButtonGlowDB.hideAll
                    end
                },
                debugMode = {
                    order = 3,
                    type = "toggle",
                    name = L.debug_mode,
                    desc = L.debug_mode_desc,
                    get = function()
                        return HideButtonGlowDB.debugMode
                    end,
                    set = function()
                        HideButtonGlowDB.debugMode = not HideButtonGlowDB.debugMode
                    end
                },
                hiddenSpellHeader = {
                    order = 4,
                    type = "header",
                    name = L.filtered_spells,
                    hidden = function()
                        return HideButtonGlowDB.hideAll
                    end
                },
                hiddenSpellDescription = {
                    order = 5,
                    type = "description",
                    name = L.filtered_spells_desc,
                    hidden = function()
                        return HideButtonGlowDB.hideAll
                    end
                },
                hiddenSpellAdd = {
                    order = 6,
                    type = "input",
                    width = "full",
                    name = L.add_filter,
                    desc = L.add_filter_desc,
                    get = function() return "" end,
                    set = function(_, value)
                        local spellID = tonumber(value)
                        if spellID ~= nil then
                            local name = GetSpellName(spellID)
                            if name then
                                if HideButtonGlowDB.filtered[spellID] then
                                    HideButtonGlow:AddMessage(L.spell_already_filtered:format(name, spellID))
                                else
                                    HideButtonGlow:AddMessage(L.spell_filtered:format(name, spellID))
                                    HideButtonGlowDB.filtered[spellID] = name
                                end
                            else
                                HideButtonGlow:AddMessage(L.invalid_spell_id:format(value))
                            end
                        else
                            local spellInfo = GetSpellInfo(value)
                            if spellInfo and spellInfo.spellID then
                                if HideButtonGlowDB.filtered[spellInfo.spellID] then
                                    HideButtonGlow:AddMessage(L.spell_text_already_filtered:format(spellInfo.name, spellInfo.spellID, value))
                                else
                                    HideButtonGlow:AddMessage(L.spell_text_filtered:format(spellInfo.name, spellInfo.spellID, value))
                                    HideButtonGlowDB.filtered[spellInfo.spellID] = spellInfo.name
                                end
                            else
                                HideButtonGlow:AddMessage(L.invalid_spell_name:format(value))
                            end
                        end
                    end,
                    hidden = function()
                        return HideButtonGlowDB.hideAll
                    end
                },
                hiddenSpellDelete = {
                    order = 7,
                    type = "multiselect",
                    width = "full",
                    name = L.delete_filter,
                    desc = L.delete_filter_desc,
                    get = false,
                    set = function(_, spellID)
                        HideButtonGlow:AddMessage(L.spell_filter_removed:format(HideButtonGlowDB.filtered[spellID], spellID))
                        HideButtonGlowDB.filtered[spellID] = nil
                    end,
                    values = function()
                        return HideButtonGlowDB.filtered
                    end,
                    hidden = function()
                        return HideButtonGlowDB.hideAll or not next(HideButtonGlowDB.filtered)
                    end
                },
                allowedSpellHeader = {
                    order = 9,
                    type = "header",
                    name = L.allowed_spells,
                    hidden = function()
                        return not HideButtonGlowDB.hideAll
                    end
                },
                allowedSpellDescription = {
                    order = 10,
                    type = "description",
                    name = L.allowed_spells_desc,
                    hidden = function()
                        return not HideButtonGlowDB.hideAll
                    end
                },
                allowedSpellAdd = {
                    order = 11,
                    type = "input",
                    width = "full",
                    name = L.add_allow,
                    desc = L.add_allow_desc,
                    get = function() return "" end,
                    set = function(_, value)
                        local spellID = tonumber(value)
                        if spellID ~= nil then
                            local name = GetSpellName(spellID)
                            if name then
                                if HideButtonGlowDB.allowed[spellID] then
                                    HideButtonGlow:AddMessage(L.spell_already_allowed:format(name, spellID))
                                else
                                    HideButtonGlow:AddMessage(L.spell_allowed:format(name, spellID))
                                    HideButtonGlowDB.allowed[spellID] = name
                                end
                            else
                                HideButtonGlow:AddMessage(L.invalid_spell_id:format(value))
                            end
                        else
                            local spellInfo = GetSpellInfo(value)
                            if spellInfo and spellInfo.spellID then
                                if HideButtonGlowDB.allowed[spellInfo.spellID] then
                                    HideButtonGlow:AddMessage(L.spell_text_already_allowed:format(spellInfo.name, spellInfo.spellID, value))
                                else
                                    HideButtonGlow:AddMessage(L.spell_text_allowed:format(spellInfo.name, spellInfo.spellID, value))
                                    HideButtonGlowDB.allowed[spellInfo.spellID] = spellInfo.name
                                end
                            else
                                HideButtonGlow:AddMessage(L.invalid_spell_name:format(value))
                            end
                        end
                    end,
                    hidden = function()
                        return not HideButtonGlowDB.hideAll
                    end
                },
                allowedSpellDelete = {
                    order = 12,
                    type = "multiselect",
                    width = "full",
                    name = L.delete_allow,
                    desc = L.delete_allow_desc,
                    get = false,
                    set = function(_, spellID)
                        HideButtonGlow:AddMessage(L.spell_allow_removed:format(HideButtonGlowDB.allowed[spellID], spellID))
                        HideButtonGlowDB.allowed[spellID] = nil
                    end,
                    values = function()
                        return HideButtonGlowDB.allowed
                    end,
                    hidden = function()
                        return not HideButtonGlowDB.hideAll or not next(HideButtonGlowDB.allowed)
                    end
                }
            }
        }
    }
})
local _, categoryId = LibStub("AceConfigDialog-3.0"):AddToBlizOptions(addonName, nil, nil, "general")
HideButtonGlow.categoryId = categoryId