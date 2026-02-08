--[[
    Copyright (c) 2023 Krowi
    Licensed under the terms of the LICENSE file in this repository.
]]

---@diagnostic disable: undefined-global

local sub = KROWI_LIBMAN:NewSubmodule('Credits', 0)
if not sub then	return end

local specialThanks = {
    {Name = 'Bur', Realm = 'Frostmane EU', Class = 'DRUID', Text = 'Continuous support and helpful input and answers on questions that make this addon better It wouldn\'t be as good without you :)'},
    {Name = 'Malivil', Realm = 'Defias Brotherhood EU', Class = 'ROGUE', Text = 'Active community member who has been very helpful with answers to questions of other users'},
    {Name = 'Silden', Class = '', Text = 'Contributed a lot of tooltip data, especially related to pet battles'},
}

function sub.GetSpecialThanksAsTable()
    local texts, text = {}, ''
    for _, specialTnx in next, specialThanks do
        local argbHex = specialTnx.Class ~= '' and select(4, GetClassColor(specialTnx.Class)) or 'FFC0C0C0'
        text = '|c' .. argbHex .. specialTnx.Name .. '|r'
        if specialTnx.Realm then
            text = text .. ' - ' .. specialTnx.Realm
        end
        if specialTnx.Text then
            text = text .. ' - ' .. specialTnx.Text
        end
        tinsert(texts, text)
    end
    return texts
end

local donations = {
    {Name = 'Bur', Realm = 'Frostmane EU', Class = 'DRUID'},
    {Name = 'Ta', Realm = 'Der Rat von Dalaran EU', Class = 'SHAMAN'},
    {Name = 'Estellar', Realm = 'Bronze Dragonflight EU', Class = 'PALADIN'},
    {Name = 'Seby', Realm = 'TwistingNether EU', Class = 'HUNTER'},
    {Name = 'Swiftstrider (mains everything)', Realm = 'Frostmourne NA', Class = ''},
    {Name = 'Orderic', Realm = 'Gul\'dan EU', Class = 'WARLOCK'},
    {Name = 'Ilyxiana', Realm = 'Ravencrest EU', Class = 'PALADIN'},
    {Name = 'Shizleh', Realm = 'Eredar EU', Class = 'WARLOCK'},
    {Name = 'Ilunk', Realm = 'Alleria EU', Class = 'MONK'},
}

function sub.GetDonationsAsTable()
    local texts, text = {}, ''
    for _, donation in next, donations do
        local argbHex = donation.Class ~= '' and select(4, GetClassColor(donation.Class)) or 'FFC0C0C0'
        text = '|c' .. argbHex .. donation.Name .. '|r'
        if donation.Realm then
            text = text .. ' - ' .. donation.Realm
        end
        tinsert(texts, text)
    end
    return texts
end

local localizations = {
    {Name = 'Ta', Realm = 'Der Rat von Dalaran EU', Class = 'SHAMAN', Language = 'German'},
    {Name = '牛奶斩', Realm = '格瑞姆巴托 CN', Class = 'DRUID', Language = 'Chinese (Simplified)'},
    {Name = 'Astiraïs', Realm = 'Elune EU', Class = 'MAGE', Language = 'French'},
    {Name = 'Griboo', Realm = 'Hyjal EU', Class = 'HUNTER', Language = 'French'},
    {Name = 'Морфей', Realm = 'Борейская тундра RU', Class = 'WARLOCK', Language = 'Russian'},
}

function sub.GetLocalizationsAsTable()
    local texts, text = {}, ''
    for _, localization in next, localizations do
        local argbHex = localization.Class ~= '' and select(4, GetClassColor(localization.Class)) or 'FFC0C0C0'
        text = '|c' .. argbHex .. localization.Name .. '|r'
        if localization.Realm then
            text = text .. ' - ' .. localization.Realm
        end
        if localization.Language then
            text = text .. ' - ' .. localization.Language
        end
        tinsert(texts, text)
    end
    return texts
end