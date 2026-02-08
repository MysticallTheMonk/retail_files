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
        swatchFrame:SetFrameStrata(frame:GetFrameStrata())

        swatchFrame.Wheel = swatchFrame:AttachTexture()
        swatchFrame.Wheel:SetTexture("WheelTexture")
        swatchFrame.Wheel:SetSize(128, 128)
        swatchFrame.Wheel:SetPoint("TOPLEFT", 3, -10)
        swatchFrame:SetColorWheelTexture(swatchFrame.Wheel)

        swatchFrame.WheelThumb = swatchFrame:AttachTexture()
        swatchFrame.WheelThumb:SetTexture("Interface\\Buttons\\UI-ColorPicker-Buttons")
        swatchFrame.WheelThumb:SetTexCoord(0, 0.15625, 0, 0.625)
        swatchFrame.WheelThumb:SetSize(10, 10)
        swatchFrame:SetColorWheelThumbTexture(swatchFrame.WheelThumb)

        swatchFrame.Value = swatchFrame:AttachTexture()
        swatchFrame.Value:SetTexture("ValueTexture")
        swatchFrame.Value:SetSize(32, 128)
        swatchFrame.Value:SetPoint("LEFT", swatchFrame.Wheel, "RIGHT", 24, 0)
        swatchFrame:SetColorValueTexture(swatchFrame.Value)

        swatchFrame.ValueThumb = swatchFrame:AttachTexture()
        swatchFrame.ValueThumb:SetTexture("Interface\\Buttons\\UI-ColorPicker-Buttons")
        swatchFrame.ValueThumb:SetTexCoord(0.25, 1.0, 0, 0.875)
        swatchFrame.ValueThumb:SetSize(48, 14)
        swatchFrame:SetColorValueThumbTexture(swatchFrame.ValueThumb)

        -- don't hook scripts since the texture gets reused
        swatchFrame:SetScript("OnMouseDown", function()
            swatchFrame.WheelThumb:Show()
            swatchFrame.ValueThumb:Show()
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
        swatchFrame.WheelThumb:SetShown(isSet)
        swatchFrame.ValueThumb:SetShown(isSet)
        if isSet then
            swatchFrame:SetColorRGB(filter[1] / 255, filter[2] / 255, filter[3] / 255)
        end

        swatchFrame:SetScript("OnColorSelect", function(_, r, g, b)
            ADDON.settings.filter.color = { r * 255, g * 255, b * 255 }
            ADDON:FilterMounts()
        end)
    end)

    -- better cleanup some stuff
    swatch:AddResetter(function(frame)
        local swatchFrame = frame.swatch
        swatchFrame:ClearColorWheelTexture()
        swatchFrame.Wheel = nil
        swatchFrame.WheelThumb = nil
        swatchFrame.ValueThumb = nil
        swatchFrame:SetScript("OnMouseDown", nil)
        swatchFrame:SetScript("OnMouseUp", nil)
        swatchFrame:SetScript("OnColorSelect", nil)

        frame.swatch = nil
    end)
end