local _, NS = ...
local Widgets = {}
NS.Widgets = Widgets

-- Helper functions for Widgets
function Widgets:ToggleState(widget, state)
    if state then widget:Enable() else widget:Disable() end

    if widget:IsObjectType("Slider") then
        widget.labelText:SetFontObject(state and "GameFontNormalLeft" or "GameFontDisableSmall")
        widget.valueText:SetFontObject(state and "GameFontHighlightSmall" or "GameFontDisableSmall")
    end
end

function Widgets:CopyTable(src, dest)
    if type(dest) ~= "table" then dest = {} end
    if type(src) == "table" then
        for k, v in pairs(src) do
            if type(v) == "table" then
                v = self:CopyTable(v, dest[k])
            end
            dest[k] = v
        end
    end
    return dest
end

function Widgets:ShowError(text)
    local name = self.ADDON_NAME .. "_ERRORMESSAGE"
    if not StaticPopupDialogs[name] then
        StaticPopupDialogs[name] = {
            button1 = OKAY or "Okay",
            timeout = 0,
            whileDead = true,
            hideOnEscape = true,
            preferredIndex = 4,
        }
    end

    StaticPopupDialogs[name].text = text or "nil"
    StaticPopup_Show(name)
end

function Widgets:RefreshWidgets(db, panel)
    local frames = panel.frames

    -- refresh every single db value for all frames found in panel.frames
    -- db key has to match frame key
    for setting, value in pairs(db) do
        if frames[setting] then
            if frames[setting].IsObjectType then
                if frames[setting]:IsObjectType("Slider") then
                    frames[setting]:SetValue(value)
                elseif frames[setting]:IsObjectType("CheckButton") then
                    frames[setting]:SetChecked(value)
                elseif frames[setting].items then -- WardzConfigDropdown-1.0 dropdown
                    frames[setting]:SetValue(type(value) == "table" and value.name or value)
                end
            end
        end
    end
end

function Widgets.OnEnter(self)
    if self.tooltipText and not GameTooltip:IsForbidden() then
        GameTooltip:SetOwner(self, "ANCHOR_RIGHT")
        GameTooltip:SetText(self.tooltipText, nil, nil, nil, nil, true)
        GameTooltip:Show()
    end
end
