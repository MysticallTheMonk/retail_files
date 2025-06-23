local _, ADDON = ...

function ADDON.UI.FDD:AddColorMenu(root)
    ADDON.UI:CenterDropdownButton(root:CreateButton(NEWBIE_TOOLTIP_STOPWATCH_RESETBUTTON, function()
        ADDON.settings.filter.color = { }
        ADDON:FilterMounts()

        return MenuResponse.Close
    end))

    local swatch = root:CreateFrame()
    swatch:AddInitializer(function(frame, elementDescription, menu)
        local swatchFrame = frame:AttachFrame("ColorSelect")
        swatchFrame:SetAllPoints()
        swatchFrame:SetPropagateMouseMotion(true);

        swatchFrame.wheel = swatchFrame:AttachTexture()
        swatchFrame.wheel:SetTexture("WheelTexture")
        swatchFrame.wheel:SetSize(128, 128)
        swatchFrame.wheel:SetPoint("TOPLEFT", 3, -10)
        swatchFrame:SetColorWheelTexture(swatchFrame.wheel)

        swatchFrame.wheelThumb = swatchFrame:AttachTexture()
        swatchFrame.wheelThumb:SetTexture("Interface\\Buttons\\UI-ColorPicker-Buttons")
        swatchFrame.wheelThumb:SetTexCoord(0, 0.15625, 0, 0.625)
        swatchFrame.wheelThumb:SetSize(10, 10)
        swatchFrame:SetColorWheelThumbTexture(swatchFrame.wheelThumb)

        swatchFrame.value = swatchFrame:AttachTexture()
        swatchFrame.value:SetTexture("ValueTexture")
        swatchFrame.value:SetSize(32, 128)
        swatchFrame.value:SetPoint("LEFT", swatchFrame.wheel, "RIGHT", 24, 0)
        swatchFrame:SetColorValueTexture(swatchFrame.value)

        swatchFrame.valueThumb = swatchFrame:AttachTexture()
        swatchFrame.valueThumb:SetTexture("Interface\\Buttons\\UI-ColorPicker-Buttons")
        swatchFrame.valueThumb:SetTexCoord(0.25, 1.0, 0, 0.875)
        swatchFrame.valueThumb:SetSize(48, 14)
        swatchFrame:SetColorValueThumbTexture(swatchFrame.valueThumb)

        -- don't hook scripts since the texture gets reused
        swatchFrame:SetScript("OnMouseDown", function()
            swatchFrame.wheelThumb:Show()
            swatchFrame.valueThumb:Show()
        end)
        swatchFrame:SetScript("OnMouseUp", function()
            menu:SendResponse(elementDescription, MenuResponse.Refresh)
        end)
        swatchFrame:Show()

        frame.swatch = swatchFrame
    end)
    swatch:AddInitializer(function(frame)
        local swatchFrame = frame.swatch

        local filter = ADDON.settings.filter.color
        local isSet = (#filter == 3)
        swatchFrame.wheelThumb:SetShown(isSet)
        swatchFrame.valueThumb:SetShown(isSet)
        if isSet then
            swatchFrame:SetColorRGB(filter[1] / 255, filter[2] / 255, filter[3] / 255)
        end

        swatchFrame:SetScript("OnColorSelect", function(_, r, g, b)
            ADDON.settings.filter.color = { r * 255, g * 255, b * 255 }
            ADDON:FilterMounts()
        end)
    end)
end