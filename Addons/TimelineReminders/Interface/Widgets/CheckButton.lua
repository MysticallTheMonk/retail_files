local _, LRP = ...

function LRP:CreateCheckButton(parent, title, OnValueChanged, labelLeft)
    local checkButton = CreateFrame("Button", nil, parent)
    local enabled = true

    checkButton.OnEnter = function() end
    checkButton.OnLeave = function() end

    checkButton:SetScript("OnEnter", function(_self) _self.OnEnter() end)
    checkButton:SetScript("OnLeave", function(_self) _self.OnLeave() end)

    local isChecked = false

    checkButton:SetSize(20, 20)
    LRP:AddHoverHighlight(checkButton)

    checkButton.OnValueChanged = OnValueChanged

    -- Background
    checkButton.tex = checkButton:CreateTexture(nil, "BACKGROUND")
    checkButton.tex:SetAllPoints()
    checkButton.tex:SetColorTexture(0, 0, 0, 0.5)

    function checkButton:SetBackgroundColor(r, g, b, a)
        checkButton.tex:SetColorTexture(r, g, b, a)
    end

    -- Border
    local borderColor = LRP.gs.visual.borderColor

    LRP:AddBorder(checkButton)
    checkButton:SetBorderColor(borderColor.r, borderColor.g, borderColor.b)

    -- Title
    checkButton.title = checkButton:CreateFontString(nil, "OVERLAY")

    checkButton.title:SetFontObject(LRFont13)
    checkButton.title:SetText(string.format("|cFFFFCC00%s|r", title))

    if labelLeft then
        checkButton.title:SetPoint("RIGHT", checkButton, "LEFT", -4, -1)
    else
        checkButton.title:SetPoint("LEFT", checkButton, "RIGHT", 4, -1)
    end

    -- Check
    checkButton.checkmark = checkButton:CreateTexture(nil, "OVERLAY")
    checkButton.checkmark:SetAllPoints()
    checkButton.checkmark:SetAtlas("common-icon-checkmark-yellow")
    checkButton.checkmark:Hide()

    function checkButton:SetChecked(checked)
        isChecked = checked

        checkButton.checkmark:SetShown(checked)
    end

    checkButton:SetScript(
        "OnClick",
        function()
            if enabled then
                checkButton:SetChecked(not isChecked)
            end
        end
    )

    hooksecurefunc(
        checkButton,
        "SetChecked",
        function(_, checked, dontRun)
            if dontRun then return end -- To avoid recursion

            checkButton.OnValueChanged(checked)
        end
    )

    -- Enable/disable
    function checkButton:Enable()
        enabled = true

        checkButton.checkmark:SetDesaturated(false)
        checkButton.title:SetText(string.format("|cFFFFCC00%s|r", title))

        LRP:AddHoverHighlight(checkButton)
    end

    function checkButton:Disable()
        enabled = false
        
        checkButton.checkmark:SetDesaturated(true)
        checkButton.title:SetText(string.format("|cFFBBBBBB%s|r", title))

        LRP:AddHoverHighlight(checkButton, nil, nil, 0.5, 0.5, 0.5)
    end

    return checkButton
end