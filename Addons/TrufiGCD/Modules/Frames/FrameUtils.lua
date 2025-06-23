---@type string, Namespace
local _, ns = ...

---@class FrameUtils
local frameUtils = {}
ns.frameUtils = frameUtils

---@param frame any
---@param title? string
---@param text? string
frameUtils.addTooltip = function(frame, title, text)
    frame:SetScript("OnEnter", function(self)
        GameTooltip:SetOwner(self, "ANCHOR_RIGHT")
        GameTooltip:ClearLines()
        if title then
            GameTooltip:AddLine(title)
        end
        if text then
            GameTooltip:AddLine(text, 1, 1, 1)
        end
        GameTooltip:Show()
    end)
    frame:SetScript("OnLeave", function()
        GameTooltip:Hide()
    end)
end

---@class CheckButtonOptions
---@field frame any
---@field x number
---@field y number
---@field position Point
---@field text string
---@field name string
---@field checked boolean
---@field tooltip? string
---@field onClick fun(button: any): nil

---@param opts CheckButtonOptions
frameUtils.createCheckButton = function(opts)
    local button = CreateFrame("CheckButton", opts.name, opts.frame, "ChatConfigCheckButtonTemplate")
    button:SetPoint(opts.position, opts.x, opts.y)
    button:SetChecked(opts.checked)
    _G[opts.name .. 'Text']:SetText(opts.text)
    if opts.tooltip then
        frameUtils.addTooltip(button, opts.text, opts.tooltip)
    end
    button:SetScript("OnClick", function()
        opts.onClick(button)
    end)
    return button
end
