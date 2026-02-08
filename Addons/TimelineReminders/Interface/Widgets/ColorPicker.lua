local _, LRP = ...

function LRP:CreateColorPicker(parent, title, OnValueChanged, hasOpacity, labelLeft)
    local colorPicker = CreateFrame("Button", nil, parent)

    local options
    local colorOnOpen = {} -- The chosen color on opening the color picker, so we can revert to it on cancel

    colorPicker:SetSize(20, 20)

    function colorPicker:SetColor(r, g, b, a)
        options.r = r
        options.g = g
        options.b = b
        options.opacity = a

        colorPicker.tex:SetColorTexture(r, g, b)

        OnValueChanged(r, g, b, a)
    end

    local function OnColorChanged()
        local r, g, b = ColorPickerFrame:GetColorRGB()
        local a = ColorPickerFrame:GetColorAlpha()

        colorPicker:SetColor(r, g, b, a)
    end

    local function OnCancel()
        colorPicker:SetColor(colorOnOpen.r, colorOnOpen.g, colorOnOpen.b, colorOnOpen.opacity)
    end

    options = {
        swatchFunc = OnColorChanged,
        opacityFunc = OnColorChanged,
        cancelFunc = OnCancel,
        hasOpacity = hasOpacity,
        opacity = 1,
        r = 1,
        g = 1,
        b = 1
    }

    colorPicker:SetScript(
        "OnClick",
        function()
            colorOnOpen = {
                r = options.r,
                g = options.g,
                b = options.b,
                opacity = options.opacity
            }

            ColorPickerFrame:SetupColorPickerAndShow(options)
        end
    )

    colorPicker.OnEnter = function()
        colorPicker.tex:SetColorTexture(options.r + 0.1, options.g + 0.1, options.b + 0.1)
    end

    colorPicker.OnLeave = function()
        colorPicker.tex:SetColorTexture(options.r, options.g, options.b)
    end

    colorPicker:SetScript("OnEnter", function(_self) _self.OnEnter() end)
    colorPicker:SetScript("OnLeave", function(_self) _self.OnLeave() end)

    -- Texture
    colorPicker.tex = colorPicker:CreateTexture(nil, "OVERLAY")
    colorPicker.tex:SetAllPoints(colorPicker)
    colorPicker.tex:SetColorTexture(options.r, options.g, options.b)

    -- Label
    colorPicker.title = colorPicker:CreateFontString(nil, "OVERLAY")

    colorPicker.title:SetFontObject(LRFont13)
    colorPicker.title:SetText(string.format("|cFFFFCC00%s|r", title))

    if labelLeft then
        colorPicker.title:SetPoint("RIGHT", colorPicker, "LEFT", -4, 0)
    else
        colorPicker.title:SetPoint("LEFT", colorPicker, "RIGHT", 4, 0)
    end

    -- Border
    LRP:AddBorder(colorPicker, 1, 1, 1)

    return colorPicker
end