local _, addon = ...

local TEXTURE_SIZE = 14
local currency = KROWI_LIBMAN:GetLibrary('Krowi_Currency_2')

KrowiEVU_TokenMixin = {}

local function GetOptionsForLib()
	local options = addon.Options.db.profile.TokenBanner
	return {
		MoneyLabel = options.MoneyLabel,
		MoneyAbbreviate = options.MoneyAbbreviate,
		ThousandsSeparator = options.ThousandsSeparator,
		MoneyGoldOnly = options.MoneyGoldOnly,
		MoneyColored = options.MoneyColored,
		CurrencyAbbreviate = options.CurrencyAbbreviate,
		TextureSize = TEXTURE_SIZE
	}
end

function KrowiEVU_TokenMixin:OnEnter()
    GameTooltip:SetOwner(self, 'ANCHOR_RIGHT')
    if self.IsGold then
        GameTooltip:AddLine('Total Gold Cost')
    elseif self.IsCurrency or self.IsItem then
        GameTooltip:SetHyperlink(self.Link)
    end
    GameTooltip_AddBlankLineToTooltip(GameTooltip)
    GameTooltip:AddDoubleLine('Have', self.Have, 1, 1, 1, 1, 1, 1)
    GameTooltip:AddDoubleLine('Need', self.Need, 1, 1, 1, 1, 1, 1)
    GameTooltip:Show()
end

function KrowiEVU_TokenMixin:OnLeave()
    GameTooltip:Hide()
end

function KrowiEVU_TokenMixin:Draw()
    if not self.Need then
        return
    end

    local text = self.Need
    if self.Have then
        text = self.Have .. ' / ' .. text
    end
    if self.IconTexture then
        text = text .. ' |T' .. self.IconTexture .. ':' .. TEXTURE_SIZE .. ':' .. TEXTURE_SIZE .. ':2:0|t'
    end
    self.Text:SetText(text)
    self:SetWidth(self.Text:GetStringWidth())

    self:Show()
end

function KrowiEVU_TokenMixin:SetGold(value)
    self.IsGold = true
    self.IsCurrency = false
    self.IsItem = false

    self.Need, self.IconTexture = currency:FormatMoney(value, GetOptionsForLib())
    self.Have = currency:FormatMoney(GetMoney(), GetOptionsForLib())
end

function KrowiEVU_TokenMixin:SetCurrency(texture, value, link)
    self.IsGold = false
    self.IsCurrency = true
    self.IsItem = false

	local options = GetOptionsForLib()
    self.Need, self.IconTexture = currency:FormatCurrency(value, options), texture or 'Interface\\Icons\\Inv_Misc_QuestionMark'
    self.Link = link

    local currencyInfo = C_CurrencyInfo.GetCurrencyInfoFromLink(link)
    if not currencyInfo then
        return
    end

    self.Have = currency:FormatCurrency(currencyInfo.quantity, options)
end

function KrowiEVU_TokenMixin:SetItem(texture, value, link)
    self.IsGold = false
    self.IsCurrency = false
    self.IsItem = true

	local options = GetOptionsForLib()
    self.Need, self.IconTexture = currency:FormatCurrency(value, options), texture or 'Interface\\Icons\\Inv_Misc_QuestionMark'
    self.Link = link

    local itemId = tonumber(link:match('item:(%d+)'))
    if not itemId then
        return
    end

    self.Have = currency:FormatCurrency(C_Item.GetItemCount(link, true, false, true, true), options)
end

function KrowiEVU_TokenMixin:OnShow()
    -- print('Token shown', self.Have, self.Need)
end