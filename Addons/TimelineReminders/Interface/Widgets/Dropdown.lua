local _, LRP = ...

function LRP:CreateDropdown(parent, title, _infoTable, OnValueChanged, initialValue)
    local infoTable, i, selectedIndices
    local width, height = 150, 24
    local dropdown = CreateFrame("DropdownButton", nil, parent, "WowStyle1DropdownTemplate")

    dropdown:SetSize(width, height)

    -- Tooltip purposes
    dropdown.OnEnter = function() end
    dropdown.OnLeave = function() end

    dropdown:SetScript("OnEnter", function(_self) _self.OnEnter() end)
    dropdown:SetScript("OnLeave", function(_self) _self.OnLeave() end)

    -- Title
    local dropdownTitle = dropdown:CreateFontString(nil, "OVERLAY")

    dropdownTitle:SetFontObject(LRFont13)
    dropdownTitle:SetPoint("BOTTOMLEFT", dropdown, "TOPLEFT")
    dropdownTitle:SetText(string.format("|cFFFFCC00%s|r", title or ""))

    local function IsSelected(index)
        if not selectedIndices then return end

        return selectedIndices[index]
    end

    local function SetSelected(indices, values, text)
        selectedIndices = indices

        dropdown:OverrideText(text)

        OnValueChanged(unpack(values))
    end

    local function MakeSubmenu(parentButton, subInfoTable, values, parentSelectionIndices)
        local selectionIndices = CopyTable(parentSelectionIndices)

        i = i + 1
        subInfoTable.selectionIndex = i
        selectionIndices[i] = true

        local text = subInfoTable.text
        local icon = subInfoTable.icon
        local iconString = icon and LRP:IconString(icon)

        if iconString then
            text = string.format("%s %s", iconString, text)
        end

        local button = parentButton:CreateRadio(
            subInfoTable.text,
            IsSelected,
            subInfoTable.children and function() end or
            function()
                selectedIndices = selectionIndices

                SetSelected(selectionIndices, values, text)
            end,
            i
        )

        button:AddInitializer(
            function(_button)
                -- Text
                local fontString = _button.fontString

                fontString:SetFontObject(LRFont13)

                -- Icon
                local iconTexture = _button:AttachTexture()

                iconTexture:SetTexCoord(0.08, 0.92, 0.08, 0.92)
                iconTexture:SetSize(18, 18)
                iconTexture:SetPoint("RIGHT", _button, "RIGHT", subInfoTable.children and -20 or 0, 0)

                if subInfoTable.icon then
                    if C_Texture.GetAtlasInfo(subInfoTable.icon) then
                        iconTexture:SetAtlas(subInfoTable.icon)
                    else
                        iconTexture:SetTexture(subInfoTable.icon)
                    end
                end
                
                -- Calculate size
                local arrowWidth = subInfoTable.children and 20 or 0
                local padding = 32

                local buttonWidth = padding + arrowWidth + fontString:GetUnboundedStringWidth() + iconTexture:GetWidth()

                return buttonWidth, 20
            end
        )

        parentButton:SetScrollMode(20 * 24);

        if not subInfoTable.children then return end

        for index, childInfoTable in ipairs(subInfoTable.children) do
            local value = childInfoTable.value or index
            local childValues = CopyTable(values)
            
            table.insert(childValues, value)

            MakeSubmenu(button, childInfoTable, childValues, selectionIndices)
        end
    end

    function dropdown:SetValue(infoTableIndices)
        if not next(infoTable) then return end

        local values = {}
        local node = infoTable
        local newSelectionIndices = {}
        local text

        for _, index in ipairs(infoTableIndices) do
            if not node then break end
            if not node[index] then break end

            table.insert(values, node[index].value or index)

            text = node[index].text

            local icon = node[index].icon
            local iconString = icon and LRP:IconString(icon)

            if iconString then
                text = string.format("%s %s", iconString, text)
            end

            newSelectionIndices[node[index].selectionIndex] = true
            node = node[index].children
        end

        if not next(newSelectionIndices) then return end

        SetSelected(newSelectionIndices, values, text)

        dropdown:GenerateMenu()
    end

    -- Effectively the same as SetValue, except it keeps choosing index 1 until it reaches a leaf node
    function dropdown:SetDefaultValue()
		if not next(infoTable) then return end

        local values = {}
        local node = infoTable
        local newSelectionIndices = {}
        local text

        while node and node[1] do
            table.insert(values, node[1].value or 1)

            text = node[1].text

            local icon = node[1].icon
            local iconString = icon and LRP:IconString(icon)

            if iconString then
                text = string.format("%s %s", iconString, text)
            end

            newSelectionIndices[node[1].selectionIndex] = true
            node = node[1].children
        end

        if not next(newSelectionIndices) then return end

        SetSelected(newSelectionIndices, values, text)

        dropdown:GenerateMenu()
	end

    function dropdown:SetInfoTable(__infoTable)
        infoTable = __infoTable

        dropdown:SetupMenu(
            function(_, rootNode)
                i = 0
    
                for index, childInfoTable in ipairs(infoTable) do
                    local value = childInfoTable.value or index
    
                    MakeSubmenu(rootNode, childInfoTable, {value}, {})
                end
            end
        )
    end

    dropdown:SetInfoTable(_infoTable)

    if initialValue then
        dropdown:SetValue(initialValue)
	else
        dropdown:SetDefaultValue()
    end

    -- Skinning
    local borderColor = LRP.gs.visual.borderColor

    LRP:AddBorder(dropdown, 1, 0)
    dropdown:SetBorderColor(borderColor.r, borderColor.g, borderColor.b)

    dropdown.Background:Hide()
    dropdown.Arrow:Hide()

    -- Background
    dropdown.LRBackground = dropdown:CreateTexture(nil, "BACKGROUND")
    dropdown.LRBackground:SetAllPoints(dropdown)
    dropdown.LRBackground:SetColorTexture(0, 0, 0, 0.5)

    -- Arrow
    dropdown.LRArrowFrame = CreateFrame("Frame", nil, dropdown)
    dropdown.LRArrowFrame:SetSize(height, height)
    dropdown.LRArrowFrame:SetPoint("RIGHT")

    dropdown:SetNormalTexture(134532)

    local arrow = dropdown:GetNormalTexture()

    arrow:SetAllPoints(dropdown.LRArrowFrame)

    LRP:AddBorder(dropdown.LRArrowFrame)
    dropdown.LRArrowFrame:SetBorderColor(borderColor.r, borderColor.g, borderColor.b)

    dropdown:ClearHighlightTexture()
    dropdown:ClearDisabledTexture()

    dropdown:SetNormalTexture("Interface\\AddOns\\TimelineReminders\\Media\\Textures\\ArrowDown.tga")
    dropdown:GetNormalTexture():SetAllPoints(dropdown.LRArrowFrame)

    dropdown:SetPushedTexture("Interface\\AddOns\\TimelineReminders\\Media\\Textures\\ArrowDownPushed.tga")
    dropdown:GetPushedTexture():SetAllPoints(dropdown.LRArrowFrame)

    LRP:AddHoverHighlight(dropdown, dropdown.LRArrowFrame)

    -- Text
    dropdown.Text:AdjustPointsOffset(0, -1)
    dropdown.Text:SetFontObject(LRFont13)

    dropdown.Text:ClearAllPoints()
    dropdown.Text:SetPoint("LEFT", dropdown, "LEFT", 6, 0)
    dropdown.Text:SetPoint("RIGHT", dropdown, "RIGHT", -height - 6, 0)
    dropdown.Text:SetJustifyH("RIGHT")

    return dropdown
end
