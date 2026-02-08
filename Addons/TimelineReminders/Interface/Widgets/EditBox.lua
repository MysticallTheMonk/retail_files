local _, LRP = ...

function LRP:CreateEditBox(parent, title, OnValueChanged)
    local editBox = CreateFrame("EditBox", nil, parent, "InputBoxTemplate")

    local OnTextSet, minValue

    editBox.OnEnter = function() end
    editBox.OnLeave = function() end

    editBox:SetScript("OnEnter", function(_self) _self.OnEnter() end)
    editBox:SetScript("OnLeave", function(_self) _self.OnLeave() end)

    editBox:SetAutoFocus(false)
    editBox:SetHeight(18)
    editBox:SetTextInsets(4, 4, 1, 0)
    editBox:SetFontObject(LRFont15)

    editBox.currentValue = ""

    -- Background
    editBox.tex = editBox:CreateTexture(nil, "BACKGROUND")
    editBox.tex:SetPoint("TOPLEFT", editBox, "TOPLEFT", 1, -1)
    editBox.tex:SetPoint("BOTTOMRIGHT", editBox, "BOTTOMRIGHT", -1, 1)
    editBox.tex:SetColorTexture(0, 0, 0, 0.5)

    function editBox:SetBackgroundColor(r, g, b, a)
        editBox.tex:SetColorTexture(r, g, b, a)
    end

    editBox.Left:Hide()
    editBox.Middle:Hide()
    editBox.Right:Hide()

    -- Highlight
    LRP:AddHoverHighlight(editBox)

    -- Border
    local borderColor = LRP.gs.visual.borderColor

    LRP:AddBorder(editBox)
    editBox:SetBorderColor(borderColor.r, borderColor.g, borderColor.b)

    -- Title
    editBox.title = editBox:CreateFontString(nil, "OVERLAY")
    editBox.title:SetFontObject(LRFont13)
    editBox.title:SetPoint("BOTTOMLEFT", editBox, "TOPLEFT")
    editBox.title:SetText(string.format("|cFFFFCC00%s|r", title))

    -- Ensures that if the edit box is (FullRange)Numeric, that currentValue is numeric too
    -- Also makes sure the currentValue respects the minValue
    -- Should be called everytime before OnValueChanged is called
    local function EnsureNumeric()
        if editBox:IsNumeric() or editBox:IsNumericFullRange() then
            -- Ensure value is numeric
            editBox.currentValue = tonumber(editBox.currentValue)

            if not editBox.currentValue then
                editBox.currentValue = minValue or 0
            end

            -- Respect the min value
            if minValue then
                editBox.currentValue = math.max(minValue, editBox.currentValue)
            end
        end
    end

    -- Calls OnValueChanged with the currentValue
    -- Mostly used for updating the highlight when it has a dependency on outside information
    function editBox:Refresh()
        EnsureNumeric()
        OnValueChanged(editBox.currentValue)
    end

    -- Highlight functions
    function editBox:ShowHighlight(r, g, b)
        editBox:SetBorderColor(r, g, b)
    end

    function editBox:HideHighlight()
        editBox:SetBorderColor(borderColor.r, borderColor.g, borderColor.b)
    end

    function editBox:SetHighlightShown(shown, r, g, b)
        if shown then
            editBox:ShowHighlight(r, g, b)
        else
            editBox:HideHighlight()
        end
    end

    -- For (FullRange)Numeric edit boxes, sets the minimum possible value
    -- The value that is passed to OnValueChanged is guaranteed to be at least equal to this value
    -- The value displayed by the edit box can be below this while editing it, but on focus lost it will be clamped
    function editBox:SetMinimum(value)
        minValue = value
    end

    OnTextSet = function()
        local text = editBox:GetText()

        editBox.currentValue = text

        EnsureNumeric()
        OnValueChanged(editBox.currentValue)
    end

    editBox:SetScript(
        "OnTextSet",
        OnTextSet
    )

    editBox:SetScript(
        "OnTextChanged",
        function(_, userInput)
            if not userInput then return end -- Handled OnTextSet

            OnTextSet()
        end
    )

    editBox:SetScript(
        "OnEnterPressed",
        function()
            editBox:ClearFocus()
        end
    )

    editBox:SetScript(
        "OnEditFocusLost",
        function()
            if editBox:IsNumeric() or editBox:IsNumericFullRange() then
                EnsureNumeric()
                editBox:SetText(editBox.currentValue)
            end
        end
    )

    editBox:HideHighlight()

    C_Timer.After(0, function() editBox:Refresh() end)

    return editBox
end