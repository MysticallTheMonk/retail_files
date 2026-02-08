--[[
    Copyright (c) 2023 Krowi
    Licensed under the terms of the LICENSE file in this repository.
]]

---@diagnostic disable: undefined-global

local sub, parent = KROWI_LIBMAN:NewSubmodule('Colors', 0)
if not sub or not parent then return end

local colorCodePattern = '|c[0-9A-Fa-f][0-9A-Fa-f][0-9A-Fa-f][0-9A-Fa-f][0-9A-Fa-f][0-9A-Fa-f][0-9A-Fa-f][0-9A-Fa-f]'
local colorResetPattern = '|r'
local hexFormatPattern = '%02x%02x%02x%02x'
local colorTextFormatPattern = '|c%s%%s|r'

function sub.SetTextColor(text, color)
    return string.format(color, text)
end

function sub.RemoveColor(text)
    if not text then return end
    text = string.gsub(text, colorCodePattern, '')
    text = string.gsub(text, colorResetPattern, '')
    return text
end

function sub.RGBPrct2HEX(r, g, b, a)
    if type(r) == 'table' then
        -- r = RBG table, g = optional alpha
        a = r.A or g or 1
        b = r.B
        g = r.G
        r = r.R
    end
    return string.format(hexFormatPattern,
        math.floor(a * 255),
        math.floor(r * 255),
        math.floor(g * 255),
        math.floor(b * 255)
    )
end

function sub.UnpackRGB(rgb)
    return rgb.R, rgb.G, rgb.B
end

sub.AddonBlueRGB = { R = 0.11, G = 0.57, B = 0.76 }
sub.TpInstrRGB = { R = 0.5, G = 0.8, B = 1.0 } -- Tooltip Instructions Color

sub.GreenRGB = { R = QuestDifficultyColors['standard'].r, G = QuestDifficultyColors['standard'].g, B = QuestDifficultyColors['standard'].b }
sub.LightGreenRGB = { R = QuestDifficultyHighlightColors['standard'].r, G = QuestDifficultyHighlightColors['standard'].g, B = QuestDifficultyHighlightColors['standard'].b }
sub.GreyRGB = { R = QuestDifficultyColors['trivial'].r, G = QuestDifficultyColors['trivial'].g, B = QuestDifficultyColors['trivial'].b }
sub.LightGreyRGB = { R = QuestDifficultyHighlightColors['trivial'].r, G = QuestDifficultyHighlightColors['trivial'].g, B = QuestDifficultyHighlightColors['trivial'].b }
sub.RedRGB = { R = QuestDifficultyColors['impossible'].r, G = QuestDifficultyColors['impossible'].g, B = QuestDifficultyColors['impossible'].b }
sub.LightRedRGB = { R = QuestDifficultyHighlightColors['impossible'].r, G = QuestDifficultyHighlightColors['impossible'].g, B = QuestDifficultyHighlightColors['impossible'].b }
sub.OrangeRGB = { R = QuestDifficultyColors['verydifficult'].r, G = QuestDifficultyColors['verydifficult'].g, B = QuestDifficultyColors['verydifficult'].b }
sub.LightOrangeRGB = { R = QuestDifficultyHighlightColors['verydifficult'].r, G = QuestDifficultyHighlightColors['verydifficult'].g, B = QuestDifficultyHighlightColors['verydifficult'].b }
sub.YellowRGB = { R = GetFontInfo(GameFontNormal).color.r, G = GetFontInfo(GameFontNormal).color.g, B = GetFontInfo(GameFontNormal).color.b }
sub.WhiteRGB = { R = GetFontInfo(GameFontHighlight).color.r, G = GetFontInfo(GameFontHighlight).color.g, B = GetFontInfo(GameFontHighlight).color.b }

sub.PoorRGB = { R = ITEM_QUALITY_COLORS[0].r, G = ITEM_QUALITY_COLORS[0].g, B = ITEM_QUALITY_COLORS[0].b }
sub.CommonRGB = { R = ITEM_QUALITY_COLORS[1].r, G = ITEM_QUALITY_COLORS[1].g, B = ITEM_QUALITY_COLORS[1].b }
sub.UncommonRGB = { R = ITEM_QUALITY_COLORS[2].r, G = ITEM_QUALITY_COLORS[2].g, B = ITEM_QUALITY_COLORS[2].b }
sub.RareRGB = { R = ITEM_QUALITY_COLORS[3].r, G = ITEM_QUALITY_COLORS[3].g, B = ITEM_QUALITY_COLORS[3].b }
sub.EpicRGB = { R = ITEM_QUALITY_COLORS[4].r, G = ITEM_QUALITY_COLORS[4].g, B = ITEM_QUALITY_COLORS[4].b }

-- Adding functions dynamically to string
local tmpColors = {}
for colorName, color in next, sub do
    if type(color) == 'table' and colorName:sub(-3) == 'RGB' then
        local baseName = colorName:sub(1, -4)
        color.Hex = sub.RGBPrct2HEX(color)
        local colorFormat = string.format(colorTextFormatPattern, color.Hex)
        tmpColors[baseName] = colorFormat
        string['SetColor' .. baseName] = function(self)
            return sub.SetTextColor(self, colorFormat)
        end
    end
end
parent.DeepCopyTable(tmpColors, sub)
tmpColors = nil