if not BBF.isMidnight then return end
BetterBlizzFrames = nil
local LibDD = LibStub:GetLibrary("LibUIDropDownMenu-4.0")
local L = BBF.L
--local anchorPoints = {"CENTER", "TOPLEFT", "TOP", "TOPRIGHT", "LEFT", "RIGHT", "BOTTOMLEFT", "BOTTOM", "BOTTOMRIGHT"}
local anchorPoints = {"CENTER", "TOP", "LEFT", "RIGHT", "BOTTOM"}
local anchorPoints2 = {"TOP", "LEFT", "RIGHT", "BOTTOM"}
local pixelsBetweenBoxes = 6
local pixelsOnFirstBox = -1
local sliderUnderBoxX = 12
local sliderUnderBoxY = -10
local sliderUnderBox = "12, -10"
local titleText = "|A:gmchat-icon-blizz:16:16|a Better|cff00c0ffBlizz|rFrames: \n\n"

-- Font configuration for localization support
-- Custom fonts (arialn.TTF, Expressway_Free.ttf) support Latin alphabet only
-- For non-Latin languages, use WoW's default font from GameFontNormal (supports all locales)
local locale = GetLocale()

-- Check if custom fonts support the current locale (Latin-based languages only)
local useCustomFonts = (locale == "enUS" or locale == "enGB" or
                         locale == "deDE" or locale == "esES" or locale == "esMX" or
                         locale == "frFR" or locale == "itIT" or locale == "ptBR")

local fontSmall, fontMedium, fontLarge

if useCustomFonts then
    -- Use custom addon fonts for Latin-based languages
    fontSmall = "Interface\\AddOns\\BetterBlizzFrames\\media\\arialn.TTF"
    fontMedium = "Interface\\AddOns\\BetterBlizzFrames\\media\\arialn.TTF"
    fontLarge = "Interface\\AddOns\\BetterBlizzFrames\\media\\Expressway_Free.ttf"
else
    -- Get game's default font path which already supports the current locale
    local gameFont = GameFontNormal:GetFont()
    fontSmall = gameFont
    fontMedium = gameFont
    fontLarge = gameFont
end

local playerClass = select(2, UnitClass("player"))
local playerClassResourceScale = "classResource" .. playerClass .. "Scale"

BBF.squareGreenGlow = "Interface\\AddOns\\BetterBlizzFrames\\media\\blizzTex\\newplayertutorial-drag-slotgreen.tga"

local checkBoxList = {}
local sliderList = {}

local function RecolorEntireAuraWhitelist(r, g, b, a)
    if type(BetterBlizzFramesDB) ~= "table" then return false end
    local wl = BetterBlizzFramesDB.auraWhitelist
    if type(wl) ~= "table" then return false end

    for _, entry in pairs(wl) do
        if type(entry) == "table" then
            local c = entry.color
            if type(c) == "table" then
                if c[1] or c.r then
                    c[1], c[2], c[3], c[4] = r, g, b, a
                    c.r, c.g, c.b, c.a = nil, nil, nil, nil
                else
                    entry.color = { r, g, b, a }
                end
            else
                entry.color = { r, g, b, a }
            end
        end
    end

    if BBF and BBF["auraWhitelistRefresh"] then
        BBF["auraWhitelistRefresh"]()
    end

    return true
end

local function UpdateColorSquare(icon, r, g, b, a)
    if r and g and b then
        icon:SetColorTexture(r, g, b, a)
    end
end

local function OpenColorOptions(entryColors, func)
    local colorData = entryColors or {0, 1, 0, 1}
    local r, g, b = colorData[1] or 1, colorData[2] or 1, colorData[3] or 1
    local a = colorData[4] or 1

    local function updateColors(newR, newG, newB, newA)
        entryColors[1] = newR
        entryColors[2] = newG
        entryColors[3] = newB
        entryColors[4] = newA or 1

        if func then
            func()
        end
    end

    local function swatchFunc()
        r, g, b = ColorPickerFrame:GetColorRGB()
        updateColors(r, g, b, a)
    end

    local function opacityFunc()
        a = ColorPickerFrame:GetColorAlpha()
        updateColors(r, g, b, a)
    end

    local function cancelFunc(previousValues)
        if previousValues then
            r, g, b, a = previousValues.r, previousValues.g, previousValues.b, previousValues.a
            updateColors(r, g, b, a)
        end
    end

    ColorPickerFrame.previousValues = { r = r, g = g, b = b, a = a }

    ColorPickerFrame:SetupColorPickerAndShow({
        r = r, g = g, b = b, opacity = a, hasOpacity = true,
        swatchFunc = swatchFunc, opacityFunc = opacityFunc, cancelFunc = cancelFunc
    })
end







local LSM = LibStub("LibSharedMedia-3.0")


local function CreateFontDropdown(name, parentFrame, defaultText, settingKey, toggleFunc, point, dropdownWidth, maxVisibleItems)
    maxVisibleItems = maxVisibleItems or 25  -- Default to 25 visible items if not provided

    -- Create container for label and dropdown
    local container = CreateFrame("Frame", nil, parentFrame)
    container:SetSize(dropdownWidth or 155, 50)

    -- Create and position label
    local label = container:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall2")
    label:SetPoint("LEFT", container, "LEFT", -50, -12)
    label:SetText(L["Font"])
    label:SetFont(fontSmall, 13)

    -- Create the dropdown button with the new dropdown template
    local dropdown = CreateFrame("DropdownButton", nil, parentFrame, "WowStyle1DropdownTemplate")
    dropdown:SetPoint("BOTTOMLEFT", container, "BOTTOMLEFT", 0, 0)
    dropdown:SetWidth(dropdownWidth or 155)
    dropdown:SetDefaultText(BetterBlizzFramesDB[settingKey] or defaultText)
    dropdown.Background:SetVertexColor(0.9,0.9,0.9)
    dropdown.Arrow:SetVertexColor(0.9,0.9,0.9)

    -- Custom font display for the selected font
    -- dropdown.customFontText = dropdown:CreateFontString(nil, "OVERLAY", "GameFontNormal")
    -- dropdown.customFontText:SetPoint("LEFT", dropdown, "LEFT", 8, 0)
    -- dropdown.customFontText:SetText(BetterBlizzFramesDB[settingKey] or defaultText)
    -- dropdown.customFontText:SetTextColor(1,1,1)
    -- local initialFont = LSM:Fetch(LSM.MediaType.FONT, BetterBlizzFramesDB[settingKey] or "")
    -- if initialFont then
    --     dropdown.customFontText:SetFont(initialFont, 12)
    -- end

    -- Initialize a unique font pool for this dropdown
    dropdown.fontPool = {}

    -- Fetch and sort fonts
    C_Timer.After(1, function()
        local fonts = LSM:HashTable(LSM.MediaType.FONT)
        local sortedFonts = {}
        for fontName in pairs(fonts) do
            table.insert(sortedFonts, fontName)
        end
        table.sort(sortedFonts)

        -- Define the generator function for the dropdown menu
        local function GeneratorFunction(owner, rootDescription)
            local itemHeight = 20  -- Each item's height
            local maxScrollExtent = maxVisibleItems * itemHeight
            rootDescription:SetScrollMode(maxScrollExtent)

            for index, fontName in ipairs(sortedFonts) do
                local fontPath = fonts[fontName]

                -- Create each item as a button with the custom font
                local button = rootDescription:CreateButton("                                                  ", function()
                    BetterBlizzFramesDB[settingKey] = fontName
                    -- dropdown.customFontText:SetText(fontName)
                    -- dropdown.customFontText:SetFont(fontPath, 12)
                    dropdown:SetDefaultText(BetterBlizzFramesDB[settingKey] or defaultText)
                    toggleFunc(fontPath)
                end)

                -- Use the pooled font string for each button
                button:AddInitializer(function(button)
                    local fontDisplay = dropdown.fontPool[index]
                    if not fontDisplay then
                        fontDisplay = dropdown:CreateFontString(nil, "BACKGROUND")
                        dropdown.fontPool[index] = fontDisplay
                    end

                    -- Attach the font display to the button and set the font
                    fontDisplay:SetParent(button)
                    fontDisplay:SetPoint("LEFT", button, "LEFT", 5, 0)
                    fontDisplay:SetFont(fontPath, 12)
                    fontDisplay:SetText(fontName)
                    fontDisplay:Show()
                end)
            end
        end

        -- Hide any unused font strings when the menu is closed
        hooksecurefunc(dropdown, "OnMenuClosed", function()
            for _, fontDisplay in pairs(dropdown.fontPool) do
                fontDisplay:Hide()
            end
        end)

        -- Set up the dropdown menu with the generator function
        dropdown:SetupMenu(GeneratorFunction)
    end)

    -- Position the container on the specified anchor point
    container:SetPoint("TOPLEFT", point.anchorFrame, "TOPLEFT", point.x, point.y)

    return dropdown, container
end

local function CreateTextureDropdown(name, parentFrame, labelText, settingKey, toggleFunc, point, dropdownWidth, maxVisibleItems)
    maxVisibleItems = maxVisibleItems or 25  -- Default to 25 visible items if not provided

    -- Create container for label and dropdown
    local container = CreateFrame("Frame", nil, parentFrame)
    container:SetSize(dropdownWidth or 155, 50)

    -- -- Create and position label
    -- local label = container:CreateFontString(nil, "OVERLAY", "GameFontNormal")
    -- label:SetPoint("BOTTOMLEFT", container, "TOPLEFT", 0, 2)
    -- label:SetText(labelText)

    -- Create the dropdown button with the new dropdown template
    local dropdown = CreateFrame("DropdownButton", nil, parentFrame, "WowStyle1DropdownTemplate")
    dropdown:SetPoint("BOTTOMLEFT", container, "BOTTOMLEFT", 0, 0)
    dropdown:SetWidth(dropdownWidth or 155)
    dropdown:SetDefaultText(BetterBlizzFramesDB[settingKey] or L["Select_Texture"])
    dropdown.Background:SetVertexColor(0.9,0.9,0.9)
    dropdown.Arrow:SetVertexColor(0.9,0.9,0.9)

    -- Initialize a unique texture pool for this dropdown
    dropdown.texturePool = {}

    -- Fetch and sort textures
    C_Timer.After(1, function()
        local textures = LSM:HashTable(LSM.MediaType.STATUSBAR)
        local sortedTextures = {}
        for textureName in pairs(textures) do
            table.insert(sortedTextures, textureName)
        end
        table.sort(sortedTextures)

        -- Get class colors table
        local classColors = RAID_CLASS_COLORS
        local classKeys = {}
        for class in pairs(classColors) do
            table.insert(classKeys, class)
        end

        -- Define the generator function for the dropdown menu
        local function GeneratorFunction(owner, rootDescription)
            local itemHeight = 20  -- Each item's height
            local maxScrollExtent = maxVisibleItems * itemHeight
            rootDescription:SetScrollMode(maxScrollExtent)

            for index, textureName in ipairs(sortedTextures) do
                local texturePath = textures[textureName]

                -- Create each item as a button with the background texture
                local button = rootDescription:CreateButton(textureName, function()
                    BetterBlizzFramesDB[settingKey] = textureName
                    dropdown:SetDefaultText(textureName)
                    toggleFunc(texturePath)
                end)

                -- Use the pooled texture for the background on each button
                button:AddInitializer(function(button)
                    local textureBackground = dropdown.texturePool[index]
                    if not textureBackground then
                        textureBackground = dropdown:CreateTexture(nil, "BACKGROUND")
                        dropdown.texturePool[index] = textureBackground
                    end

                    -- Attach the background to the button and set the texture
                    textureBackground:SetParent(button)
                    textureBackground:SetAllPoints(button)
                    textureBackground:SetTexture(texturePath)

                    -- Pick a random class color and apply it
                    local randomClass = classKeys[math.random(#classKeys)]
                    local color = classColors[randomClass]
                    textureBackground:SetVertexColor(color.r, color.g, color.b)

                    textureBackground:Show()
                end)
            end
        end

        hooksecurefunc(dropdown, "OnMenuClosed", function()
            for _, texture in pairs(dropdown.texturePool) do
                texture:Hide()
            end
        end)

        dropdown:SetupMenu(GeneratorFunction)
    end)

    container:SetPoint("TOPLEFT", point.anchorFrame, "TOPLEFT", point.x, point.y)

    return dropdown, container
end

local function CreateSimpleDropdown(name, parentFrame, labelText, settingKey, optionsTable, toggleFunc, point, dropdownWidth)
    dropdownWidth = dropdownWidth or 155  -- Default dropdown width if not provided

    -- Create container for label and dropdown
    local container = CreateFrame("Frame", nil, parentFrame)
    container:SetSize(dropdownWidth, 50)

    -- Function to get localized text
    local function GetLocalizedText(text)
        return L[text] or text
    end

    -- Create the dropdown button with the new dropdown template
    local dropdown = CreateFrame("DropdownButton", nil, parentFrame, "WowStyle1DropdownTemplate")
    dropdown:SetPoint("BOTTOMLEFT", container, "BOTTOMLEFT", 0, 0)
    dropdown:SetWidth(dropdownWidth)
    dropdown:SetDefaultText(GetLocalizedText(BetterBlizzFramesDB[settingKey]) or (L["Select"].." "..labelText))
    dropdown.Background:SetVertexColor(0.9, 0.9, 0.9)
    dropdown.Arrow:SetVertexColor(0.9, 0.9, 0.9)

    -- Create and position label
    local label = container:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall2")
    label:SetPoint("LEFT", container, "LEFT", -50, -12)
    label:SetText(labelText)
    label:SetFont(fontSmall, 13)
    dropdown.LabelText = label

    -- Define the generator function for the dropdown menu
    local function GeneratorFunction(owner, rootDescription)
        local itemHeight = 20  -- Each item's height
        local maxScrollExtent = math.min(#optionsTable, 25) * itemHeight
        rootDescription:SetScrollMode(maxScrollExtent)

        for _, option in ipairs(optionsTable) do
            local displayText = GetLocalizedText(option)
            -- Create each item as a button
            local button = rootDescription:CreateButton(displayText, function()
                BetterBlizzFramesDB[settingKey] = option
                dropdown:SetDefaultText(displayText)
                if toggleFunc then
                    toggleFunc(option)
                end
            end)

            -- Add the text initializer for the button
            button:AddInitializer(function(button)
                --button.Text:SetText(displayText) -- 11.1 error
            end)
        end
    end

    -- Reset dropdown contents when closed
    hooksecurefunc(dropdown, "OnMenuClosed", function()
        dropdown:SetDefaultText(GetLocalizedText(BetterBlizzFramesDB[settingKey]) or (L["Select"].." "..labelText))
    end)

    dropdown:SetupMenu(GeneratorFunction)
    container:SetPoint("TOPLEFT", point.anchorFrame, "TOPLEFT", point.x, point.y)

    return dropdown, container
end

local function CreateColorBox(parent, colorVar, labelText, callback)
    local function OpenColorPicker(colorType, icon)
        -- Initialize color with default RGBA if not present
        BetterBlizzFramesDB[colorType] = BetterBlizzFramesDB[colorType] or {1, 1, 1, 1}
        local r, g, b, a = unpack(BetterBlizzFramesDB[colorType])
        if not a then a = 1 end

        local function updateColors()
            BetterBlizzFramesDB[colorType] = {r, g, b, a}
            if icon then
                UpdateColorSquare(icon, r, g, b, a)
                BBF.CastbarRecolorWidgets() --temp
            end
            ColorPickerFrame.Content.ColorSwatchCurrent:SetAlpha(a)
            if callback then
                callback()
            end
        end

        local function swatchFunc()
            r, g, b = ColorPickerFrame:GetColorRGB()
            a = ColorPickerFrame:GetColorAlpha()
            updateColors()
        end

        local function opacityFunc()
            a = ColorPickerFrame:GetColorAlpha()
            updateColors()
        end

        local function cancelFunc(previousValues)
            if previousValues then
                r, g, b, a = previousValues.r, previousValues.g, previousValues.b, previousValues.a
                updateColors()
            end
        end

        -- Setup and show the color picker
        ColorPickerFrame.previousValues = {r, g, b, a}
        ColorPickerFrame:SetupColorPickerAndShow({
            r = r, g = g, b = b, opacity = a,
            hasOpacity = true,
            swatchFunc = swatchFunc,
            opacityFunc = opacityFunc,
            cancelFunc = cancelFunc,
            previousValues = {r, g, b, a},
        })
    end

    local frame = CreateFrame("Frame", nil, parent)
    frame:SetSize(55, 20)

    -- Border Frame (slightly larger to act as a border)
    local borderFrame = CreateFrame("Frame", nil, frame)
    borderFrame:SetSize(15, 15)
    borderFrame:SetPoint("LEFT", frame, "LEFT", 4, 0)

    local border = borderFrame:CreateTexture(nil, "OVERLAY", nil, 5)
    border:SetAtlas("talents-node-square-gray")
    border:SetAllPoints()

    -- Create the color texture within the border frame
    local colorTexture = borderFrame:CreateTexture(nil, "OVERLAY")
    colorTexture:SetSize(12, 12)
    colorTexture:SetPoint("CENTER", borderFrame, "CENTER", 0, 0)
    colorTexture:SetColorTexture(unpack(BetterBlizzFramesDB[colorVar] or {1, 1, 1}))

    -- Label text for the color box
    local text = frame:CreateFontString(nil, "ARTWORK", "GameFontNormalSmall")
    text:SetText(labelText)
    text:SetPoint("LEFT", borderFrame, "RIGHT", 3, 0)
    frame.text = text

    -- Make the frame clickable and open a color picker on click
    frame:EnableMouse(true)
    frame:SetScript("OnMouseDown", function(self, button)
        if frame:GetAlpha() == 1 then
            if button == "LeftButton" then
                OpenColorPicker(colorVar, colorTexture)
            elseif button == "RightButton" and IsShiftKeyDown() then
                local defaultColor = BBF.defaultSettings[colorVar]
                if defaultColor then
                    BetterBlizzFramesDB[colorVar] = {unpack(defaultColor)}
                    colorTexture:SetColorTexture(unpack(defaultColor))
                    if callback then
                        callback()
                    end
                end
            end
        end
    end)

    local grandparent = parent:GetParent()

    if parent:GetObjectType() == "CheckButton" and (parent:GetChecked() == false or (grandparent:GetObjectType() == "CheckButton" and grandparent:GetChecked() == false)) then
        frame:SetAlpha(0.5)
    else
        frame:SetAlpha(1)
    end

    return frame
end














StaticPopupDialogs["BBF_CONFIRM_RELOAD"] = {
    text = titleText..L["Popup_Reload_Required"],
    button1 = L["Yes"],
    button2 = L["No"],
    OnAccept = function()
        BetterBlizzFramesDB.reopenOptions = true
        ReloadUI()
    end,
    timeout = 0,
    whileDead = true,
}

StaticPopupDialogs["BBF_TOT_MESSAGE"] = {
    text = titleText..L["Popup_Tot_Message_Text_Midnight"],
    button1 = L["Yes"],
    button2 = L["No"],
    OnAccept = function()
        StaticPopup_Show("BBF_CONFIRM_RELOAD")
    end,
    OnCancel = function()
        BetterBlizzFramesDB.targetToTXPos = 0
        BBF.targetToTXPos:SetValue(0)
        BetterBlizzFramesDB.focusToTXPos = 0
        BBF.focusToTXPos:SetValue(0)
        BBF.MoveToTFrames()
        StaticPopup_Show("BBF_CONFIRM_RELOAD")
    end,
    timeout = 0,
    whileDead = true,
}

StaticPopupDialogs["BBF_CONFIRM_PROFILE"] = {
    text = "",
    button1 = L["Yes"],
    button2 = L["No"],
    OnAccept = function(self)
        if self.data and self.data.func then
            self.data.func()
        end
    end,
    timeout = 0,
    whileDead = true,
}

StaticPopupDialogs["BBF_CONFIRM_PVP_WHITELIST"] = {
    text = titleText..L["Popup_PVP_Whitelist_Midnight"],
    button1 = L["Yes"],
    button2 = L["No"],
    OnAccept = function()
        local importString = "!BBFnQ1FSXr1DE2D8UElrxVetGmusWZDIEHiLtqPNJQao7S76FLw7elVoBiOwD5T7(2Dh8SZSm)y9TMC0MuQevkrjkfvrqhKFueuKOQb6PqnqsOrPbsqu26R6sc6sGyXDLRLlbzku(dk(((9nZB2NJND89x278((99EF)1NV)yMi)DPkqSjp65KJFpxjBkDsf6loszIfvjtz1I27KQRrmlrlST)w1cij7tTsvdtBIU92gnVHMH53mIuej71LTr0xe4GQvqzlenTgTHmyVUgX2wJ4FtPb75)QRUw)1DDx3G9CLU7EBW)ijh)p)1bMQUSK5Sm0CSHdKAs1vTR7YlUUl34bi3XH(yK6Byt1OMvnMaiTGskIPPk1eO3JkGEKtGwzPHxI7UxJQxsvVKsAthlsbo1bDJ84g4uo2R(Ia3ZoIPAfdZcQenqOQr9UyWI(I17T0LQa8cxWOjRdSSVnOBtnHZKtm84MsrIBzL4L6gtPrTSWlLrrLmK8MQfvZtxSlgWCIh8k97Tv4dEWRWoqD4aj2i)YTT9pboGt2RAnvDqHAtPf8UhWk87HKKC73txO8LupVkv3gVgdzysxGIeiR3Km1U4nUFtyBnQWPwYJ6EtM4QposChzCmRPwduABq3YwvpVT1IkBx9XLJS3Nc5(w3GEEIPoXw1q)UvgWHG6FD8C3SPLrE)DYxZ7Dxb2LL2LbSf5gRSHPULNGdpleNW27CmGJd3RHrfLTOQxWQL7pqPCSZVk0ppDztdDdqLzuL7sC(vj4Rg5d(uGSzgZWjFz8I)TiMviEucRfY1jYE3dQd6CE6GKG1LyIBusRYKkeFFlG6aCeJCSDIIusR8u9ce98(uFSDUqQt8OhepWLUrQDzQPLTHzfL(1iLUwxbGozPCVcqBJ)AUIn3Ri4rjTKmmRxMQMusb0tzSYuLTarp3TYiMg208OWWzDjzcrje9d3hdnbVmJtPvzXSSyPpCFbiVXt9PmriPUT6F)WKsQ5bOlkhccxwW0eBhFgZFoTbgxdAyagjPLfXrZMBk3XNfWHi197XoeuOsrjw2G3IDzvFbQ73ZLPb75)9V8fipa3Nz)7)eZn3Csj2(Uq3bFKOTysSl3k)mGy5ixylyu8MmZHg9rq0oUn8cBHFoF4N)xuy6Tt0zN9m3CFHeA5)(Ob6MBDmYX((YX(xEugebyMqtTAPY2liUhOro6n)SOeFtmZWAv6JyAxETke9ck9RA6JUDZpBa(un(ag07OgUETIiCOe24dclc4DpaW809QwSOdKeIzp5c)7EGqyuk3XMV35Xe8oJ(PNbwCNznulueeNwQGa6KB7DVu)meZ39sCTcimdsbfakn2OBTQgIRkh7NnccJUPQGtVl8ikZChPF2iIoExCB417g5lEXTfKx2TUbmhskndJcAow2T8Ecekh93JGDhoTrLCaPUbxTqQ(9gYXUWx1nkjNrfvxKfLHuRKRLmbmihtPt(LUfeP0PC026MH6VrITJjD1wkzMakCqhuiCNK26wqre)kVnUNk8WZR82bIH9iCpzx)2hjiTvUtWT4neteHlih)xvebrgMOrRzOr1fYVETcbq6JDeCNwJ7X9yhjOdt5Ym93iGLg3n0vyyiHrRnrkxwUJFm6FCyM9eWw9bUHNhWre7OdJ4eJcfpmb6lLsJmPFnhhD4q89J)rOoT6kgcu6utLwHe(rVTGDOTNBROmVCVfHF26diXwX6w2juV14wJZb9GhgchVWdJEYBauuG0NFCpwEHhw4giDxOwF67NQR0VrEhlLXO8SKWsIXohDi8QEN(6IHcdhyjYiX)v8DAjYEehzWE(LYYRNruS35G93InaPo6jzWDkUf0YoZ35Ga4ltJ934BYp3kwHle8bDTH(WSxyRjUZFPR8xxjlvLxmc80GCTw6pcTE3WOKsuoctgnXeFafbWx8x)vyi5uiDIs6Yyz6Cl9RlMAUT1ThrKr4Nclg5vpnE4lFaiFau5kuYwnvl1CQAnlehijmFVd(tybg9cx4YqEuOq76w2enFT0j7OdxT0mMMFpbTeWiyN7aDS6fCSeamGNgYb226278fN9kios)JdGH9ULZafTBYR)fwqWJkYfFgKSEjvQcEFdsyPeyY6fFMqo6iV1n5kRQuLC1Dnuty4FgWYHPOEQPzNjONusHA7YCR1tnDqw35IVo2QZfNHBJLZzHO23EAtv7145r)VT8LR452)vyOWBwZwTcb7MA(zDrceuarFVnl0jb(ta5jtvOkntOU9mEvfK47uLjVWcAAkJslQjwghSQyq6K7gX6YuXyCiM3WpZstyzGc5yNgtdwDzB0rttTyDeMldunTdxfcRlIqSeSNQzy9XGrgda9BwFHW9lPUSupRhOmvknh)yMEwFyOeXVo0XdXN6pScca6GW57Jh37gDFFUB8G9C5LTmVA9o1J9yhKz2ARef34XmDOwLnADgCGo5y)5FnkEO3VIV9TLCaud1zoi6dbvqcvFInApoxA7EqXOG1mfUXBwVSHwDH6BBHmUMPsmfcfBokPkMd3Z8o1rcrbgn2mOH8wa8c0GVrvNjjgRLfsa5TYpUYM(NBSyDAd7HS0k(CxxmEpJJraxS8(qbR4Zd7s8BZYqo9g8a4HKfQXMs0x8UPrELJvy1O6CekjpDck0HVFTBfwDt3WetHP(pCVQwaISvt3)PUCixTy76(erPGFkyFI(72iICNPmPGXek9scR6eGwzPBehhXHHoiGAqfqRGNh2vW6(XRqp8RG19hemt3VfquUuoMMgtWbK6(TcBB)r3fE5tAMNGZyWPzAhyLabYA3diRDeGQzFPk3(GqJu01WJ2J)4)dIysWprKcM2PzH3SkUKJEUxGz4tAHqw8v7JusZVZKZ9cbCxImk2Hu1BwCSc8HG8TaWiUBhqxR1ajgmn2Ga8hKMOZKc8kOMJd5BWm4ncUjq54R5PziFEZMzb9edRhwYJ4XrLo2Aoafte5lE8fkOjw(tIXZ9vJmpiLwn9LL)KaQ2qZhKBiU)QiQ59(FGe17cG2HfKJFM(Wfxf)EDM(eqYJSNtZWBnn0ZbWD8tzpHvzrhpXpm78vVUnx1cnS3vb4swAM2fd(GFke8fxhlZwit5i4uhPnhucqqyU)x2G1Ei8xM5Vr6wrPuxy1)x70(0ZBdoF8ARaAc5SI804CvZ5oaiUo7Pxxa276SXAS00AgKXzNddAzXN7w9pdA2)PD5La54NFdUbJibmihDU3erKCRZAIM5HGNly1LMjX8TdjeSdr(vFgtrc)9AphOmcNCq1OfDyylYrBSw8kU8(0nb))cqLiLGMKmj2))W5gzwoY2Fjm8zuqeR7omy)IB3(lfsK()(BaSn9WimLj0zBA)jBdRiiksDvlBZXU2pPMHFviDvtqFe7p9pH5Bsz4GyAPi8(IWfc5wC808aRgIJPbEUCStIfqFsOR08gLa34M4cWkIN8LMa3JVdFXlnraorRgHaMHnVjOpGIoc56w9qbGMgB2ddmSVm6gtuaQ1S1vyaeklDECEsnK5kMZh0KJoEj0RYTJMrGcb8o9JxkKGePupaElgel1rSG)upGi(ZB8GOMFi1IuL0g5n8vtWcHT3ZC9Z3b(6fbsYCYSE1qM2qJFUWtdzdJM)SOeoi00avyqRyP8)RRCLRxmVF(Zkh5z)EOOXkqSP6aFCihr8tDb8oZhnn8ZWiUDSzQd3xoOXIH9Q6NXv77nadU0KylmtZF9cSQU4QMjNU1hJ94SOpA(XrOWMD6zpEqhYmFP5RZ)sc68y7gNL6SBkNLkl)DM8eyl5E17ExHefTD0nz2KGIhs23lTiufYI)2GaUs8Xe8(8aE(IFmrmWFsmrZHHkElqzdp3xB0Easw0l(lyWjuBsfdZQLnSu9Nr2f)fbfGTRVmWqUrX5b53H0U(YTwiF)EqCYBsmJZ1wOX73ty(7RCwCdKNxklS5VjW6L0lXfVvoBy(uF4ZlAaHFkAavXQhnhqtTsvl)chvVlrSQpbL6QRCEVeK0G2IYQxRpnh9wxUmWSCS)WxJjfzmC0Y5ycC3lTIHUAEL0QM59lreiR5flXooAw289iQGxLJ3eD9X)2XrdrGJCOxhLjVcv4bPh61dY5E3sio0OK6OOmOrv)2Z3TuyQ05wPxn0ReRHuSg6SWP6xcD08y18tNeAUMTAteMb75SpXt8AWDyWE(Jp0dDqCxBI08wjof(U3A8iEs7PEQG8Ep3(rn0YNFn3J5yAlu09(dviw16Cx7Qh4aVMRrJvdV)KnCt0wFnUI6QKJ0dMxT6n4MsY9Lj18L(Y0Y9ulmdZEX3UvJDWjEVhmGCo1)ISS3PhK0rP3MJLbEEi7CSVX)ng4NudNz2yQvw8(nbosmekotNcGkyVszZMh2q1csJx)841F7CTB9ZVqIUTBhjzIf74VTBh8WAdj9h47W1wyAU357IxvVouDX3AzmhqSCSNBPOPAz9vbQld6fpTrLko6cLJ8ClnSJ7zUkMHiPL74Nk7wmbBVFMRgcM(RIDimlZQbLNLSqTMVVtynbyN4tItiFFzifPLCAwKa84WmY9YEBSDmai(QeaEhoJ(QKtJYH5bccH92gFcMkHvZVArvOW1bmHs)8FL8JpHaQN0zrqe3VFanxCHgIv7HeilLgFNp7lLrH6CXiCVoGHBJ9oC(2Uh6T1zyY7SJYqzG)IrD4ap0i5PvWeMPOK8GXK3Q(VbFBVnEiUA83KjOSxNM92SWOdLm2nFx5NEdIG9N6smuLmvvnvTXojyvANKwYp3iqstgs8g4aENDevOlyt3VgbJw)IYaQtS17gpGBSFtQ(KQlS5bKQTE3H4J11rzD73fldauarbyJiAybqJ6yvEba8)WZH5c8(AtAzidqMCK38NJipcP54(8V5ppK7Z94MOklPcQYYJEKMKfFGxaFYr6Qyqk7b84ND2Dvmmpelm790mtAVQZBoeWsHCPNQbdiVVkSVDhqZbQVTqjvB98obwE)7f18V)9Yu8n6QvxkPB4qz5VYgOeHMF(r4kHjmNcNRxJ167MDzb)YiNFs0pRFdtBV5uNYKYhqgSyi7B0VXfZY(4A8FlC3FZx9hSyiQPoXYVM1fLG9nua1U5b2aRfMS8tpdZWafk6)nZWLRF6zcJX)Zc4r2CilzkB44fpfYuwa2KB76rKLQRWF0TELe0VQTnviMSvyta)joc(AcNHL8fLxX8Vh5HddB9c)pSegoMefVQgwaGjqJCSPUJSyhLMKsgSHhWvktDhbGyfpHc6ruJdRLqzHeL4e7HHhCcg0F09nKA(Y5mm1B1G)sCC3pkkOnXCOzvH5sz7uGNN64pEiYPuUJNvSzOChVHFsTeV8ZZ8w4ZY0nQ2BxF5NpmT3F87Ya6H)ckXXalo05hOejA(U)7VpgkZM1PUEIJsTm0QTOOmiJ7e)GchREv60eW8SLYQ2unvl7)Vd!BBF"
        local profileData, errorMessage = BBF.OldImportProfile(importString, "auraWhitelist")
        if errorMessage then
            BBF.Print(L["Print_Error_Importing_Whitelist"] .. " " .. tostring(errorMessage))
            return
        end
        BBF.DeepMergeTables(BetterBlizzFramesDB.auraWhitelist, profileData)
        BBF.auraWhitelistRefresh()
        Settings.OpenToCategory(BBF.category:GetID(), BBF.aurasSubCategory)
    end,
    timeout = 0,
    whileDead = true,
}

StaticPopupDialogs["BBF_CONFIRM_PVP_BLACKLIST"] = {
    text = titleText..L["Popup_PVP_Blacklist_Midnight"],
    button1 = L["Yes"],
    button2 = L["No"],
    OnAccept = function()
        local importString = "!BBF11xcysr5z(70h1mOGccinxXwnrCtcM1K11igJo3mWmW4mat0eDtnDxtpLt1v1wDxZqZAwdKvtIU5snhAIXDnBUmRMOHaRAmrqmXK1SPxatWdubeburCaeq8G))EpQQ7bZ)8KNNxD6V6749(67Z6o7MYAwY8RhFQPsEx3Y)4zANLGn5AM3AJTwSOLBgR0nf4xS0QkoO3iDz7A9zByn38zJXbqLyfMs3w(f9CnDSxHv209zzwAql)ugRzX8ubyLyRVhpVsPxKvPr88hQsIpBkJrBu(1rBeZWKwM9WMzSlvoT3aPBZ3RyjzmnPJPPJFmDANBqEmjw9g5XayLyRQplhN0TzLL)67Rx5RVVEX636YZyvSyTZDl6C3Y7z998ZyXJzn6mSgmdfo1El5BwYkNDM0D4oqqrBpxEd8N)tYg4p)NWGMyt4iAz5MgOG0Tw2QinKK393wqQ393gd50A1XkVLBjtN0npOPxX5LUvt)sdYdCF3GmW9DdvIT)EmxHNp2XM5OHZZu9jeSgG0UUf8H2U5sp)aFF7mMU8Uo(SNhpgabgPPahNIwL1ZZs1ZZsReRY4XFQHvDc0Fbam0M98l45B6WdDLzKHUYmyHMwh5S9nNtX0n7hy5KEreYpVPVLC4Un9WDB)npCvX4pFNYu(8Dsl2G2P7ZCyzF92TE28V82Twj2D1JvXGcfCSTa31Timz3c2UjtzStDc2jMGkJJ)YDR)PD3jrH6ZUywV8enKq)9z6iNLD2L(DDf9D7Cr6FArH)PeN97k0XZ(DXunJUmbHgNIoCl5Z060TyMVGLRLpFOxXDZ7yazod7CUHRANGdXZnLrFfLZuFfjjKwDZywOyGdyGYMUfRIGSvoLXv6l7IR0NOM9yMZI5)k7phtmsMLW4K(IYyoPVi4IBlWNzr)ubweZxdZ6byY3SEGkXU5M9wr50TzlufJDEz6b8YIoZN0xsNPVe(tZI)tp(Ll)Ph)YjE3U8Y5BcPBqO7ku(Y4BoGmKV5a0q6Zgcy6jTfZryjaJ)YYKH8xwg2InHdN3ircOnSMBvOH3ktdJDO)apwabtWY8SZoGNFEEw(dFAzw(dFAcH1ybpG(lxOee3A2Z9AcSeUOKh5RlSBh5RJHn1(8nluaO0Lwauks1ZWqEGh3MVDzCB(2ReB7T5BzTcssPpB3SSKKXlRB6xgB6T37GMzXMU1897BQY(N0xvXwFvSoNzJoedz6(8TlwkxGPFwcj0Sx(cMUGAxCq7c8h906z4PXzy)qpso8nlXYLvTWdylFgzaB5ZqyZEla9vdasw6ElavM8cx)ee1MaI5yjwqYUFhR0lZUiypy57owRiF3XAReZV3bdgyahzl)19ewUVUhM8P3NPF)MUzt3feh98XgPtRHTCasivYN6oeCZtDheoShlhmehs9yharBx0gJNMWypVOBfqqybvOOvgOcuv8zK6RklxkcdnTgl5LNKyCkNUhlaT7N0wIf5X(bYI9y)aAXQQFOvSu0OSde6VHy5bqsyO9b9cCSlo4y01MChFpzU2X3J010MnzZPu55LUjhZmdLUBVrYkYNXoGiFdyLy3F7(cEWXsWtR3swP1BrReX0y5dE(LeuYYrrYj3HII2bHIMs1vQ1HTlMXIoAcx2)HYL9Fanxn75KL035ksoB9FswMT(pbPtIvFqlOVw2bdiOU1paFwj1kMoyl09GqW3D5PmEuvQ7rPbmTwlwYcOTSILcyDbmQapkN0fRNuYk7sG(50nHLrLcmwFo9OMdC5lZEf28jTxZHhUSCmVt9yEN0gP6XSNGcLcugYeFkEZcyLyBS1LxWRi2jTH95qPm(t6(8pXheigvQKfXRPUnqkaEkw7laehp0pvSeuoybCTRPIO(jfKj5NuGMKUmbJylGl0fgBdr0g3qzzm3qzW03bWxLSn5Z)fCcY5)cGjS7VjhpVSG5cSQ8wFCI(naPfVtGvSiudH)GllS00SAxKMMv70PdNER0DB5gU3IpRFV(Z)Em9m6Fei9BjsaN)xt2uN)xJvzL1eQRggcZL8CTkczaX8FIF(O8WaKiMqOpd8KWHqHfhI0Ja(wHTn(z97Kv7S(DyZ0eMfyffACdPMfxPW2uCLKDs7SwPBeh1CPIT5NwqcB(PjZrWTGHY7btwK1GragKNCJVPIc)MafUX2DSmZtOIEmllkeZCdYKN5g45Wh)EXaObl98TCkaSfyaUkbBM4QGMPUS8ZyZknasFefx2HIS6atXK72NSZbRHbfhdk9i3SmQJaFh3igug7IaNnON4IJXRQSuV6aSHtiB2FGVlTv7iNRDO2NeZCM82fqyiPvxORG02ySdB5R3HnOxnMjJJz(inwXpYTORmuX0)Y8CCSePGN6EePGN6EGuslww44cRB5YP8i1FIMYb)enjnU2zMdyG496ZLxwTNlpPBBjJydCUjTtDlc3gICBZyTJiJBTJqCan7xUiysbzf(iMVar9PHYl147xwQX3FKJjd3GW(mCdmcrSrr8nnnc4ZnZN1MxJTR7LTt7LtTzhOeq8NT7aFsMLpPVYptoPVYpJgute9JWSyu9rYB(YcooDbhhj1uZc2T5CgkGhYQpQmKvF0WTz9tiRSZNqwWDmFsvx50JXF8B66Ln4nD9KYBq4Z7j0tAQbgl0LJ6NGLotq)CLpT8T3G(TeZ5upUVTxph1QD9tya9thi6tN0ps4RN0pIDyWtSDBMg)tLgSmKGCk3WwFn6ZaaAQBXQeeqdT4CF)wbHDF)wcxmFtFysckNYyxGiFyinS4pc)Tl(Ja(WfeKnxiP04NTszp)ZG06254NgJWEIfmdHdEbZGMAYddtkslyNTKVNtkJdOQfpaulEZ9woF)2EfTz(P6U4Fn)tacU8EdYcfsPBXZtyk3R6v5EzVk7na8AyRMfRm05Mr8d5s((YyUKVpT2KcJbGKIvTkgpYTPcl3wOI1IwwdP7DJ5k0FJ5sEgaDj(zmjNAj9un87xnJr(9RgmcluuFLUlZmdkiSugpZYLf)zwoVbpoNGejMVZxwgZ35ltmQDpOTj73jzGlIrj5oxJqC25AG(WETSy9zc3wDB47kOOn8DbDPltxt4igBXi5SEz5RM1ldTaWZq3vi4KxEeHr5LjH0P0BPaGvzswVWfl2UrkJ)8)IST(Z)lGMCfaR3DGJiAzCKsYNFKsG1B(PmA8UKH24Db0q3(25jv(qsk0UAY39xk7J39xsYdseOKUs8pzpaCLkIhC7c1gqwO1Kd2lReRGPTgNWDO(REhK3yNwpKDmARdwQsJz2sCjNTq6UKZgSLiinOZQhlZio(4)d)VcD)F4)f77g9PWkXYKh(Qzk2rUvr)nGKw(odCn9t3yEipu7YySkjMxajXokQaC6TTG73Phb750DlUmhFcIjAaRWHpBMreQxMTFPabrD4hso)h(HWoI4vHxyqllCMTiZXNC3Qq6UHq6DrMvhSGNTifMCJpM8BB8XOJdKSkmicPOBp7I6g9c(VKn6f8FrK9UqacGr0EiR5r6KG79IN7j3SopB(Xc14LCRpQ8N26JIVC6iWpZmLddoId7fkvlLHjpX26lXJfqSnA2hBrjej3qB7V0QKTXlTkIxUamU7hA3VUz3aZAbijWWMmbJcCKRh7(7Nc281vvnVou1SQEmZYAsirXBHD(gay4cUL7hyl6MQ)HfM16FyiCZsh9wG5Wt(tEs5q9tEsWE0PLzbsOQns5GiygtW1asu)EZW(jeEQjVCPrv)4)C8Oamk8tRFSSKw)yYiRV6(bhqwkJBxIwdqmRZQfw9EM0n6xAEP7YJsNehVfLrb6u9z(k8P6Z8viwl4TLFEIGXo26mCely9tqewbmYyGXJiRJXJqKSfANziEV3gCHH1s5rAVLassE0niyIJUbIZeIUUuWO1oeJSsAaaeUY07i2duIS2weyzSQRux9vgT6R)wLvF93krhBgbKaDMuQs8CZQuMK74jKmlSJNGLJrmBMSc0w8nZ55IZyRLTsz06QLfU1vt4Rfzns6fzdLuUPxK3C71f)J2UZj9siKykJrVrzSJEJySV)qB(r0SMqalRWsN)bCiMsGFEmfp9yeEQn4C1)FXtgFtvr338UiRNMJ46eL8GR6xi)0v9lOddChdhzkcsmfqZu2CquvD67Rid8v)kSVbqDu42lmraQw29QdCV0aN8ImjTPuGt(E1y1or7xGOJR9lG57Z6f0V4AXPi(GaiSBXCoPRAbO(XFdkx7nejJFFBvycUVTckm5KswwhDhIo847w8Ncqih1Ph0kNfUhioJKOTlu2fTDHGJFHEd7bnxleQfGJHSy9n93Z)oGyxoFZa4aMk98L09Xxks6j2)Jk29)WgNCmdaowcMP3s(G7xWJN4Fug2j(hXWMDFsKGP711BK0TdpcHn2axgRRzMC3BsoE7EtSzwY3K0lgUCpYGwo5dv)4UCr9JlzVEITB74AzwKKgHyh0(K8N(IYK8tFr87ZOQTAlOfl9YG)eGI7eMbKxwLbEzsg40uNDC0SI5herdnEO)DzGp0)ojSSuxFonf8XX2sIs34GQPOdsHs0dD(wcuSuuTWgBxSBDeKsmfLBR0CMGKpEvkZ5QiMZuVxlul1ptjpbTEyDtFyAtp52rC(wU5OuHfknXitNdl4bNdJLRZaG)quGAyWW6TeJgG0bVd3SWls4vac5gMQB203vt9qIziPReqoDAWVQ0KhwAUsJTjLrytuGW5lyvkq2JX1FiotkjI4aQ0ARiC5CIvSn(cYMyJVaHufR2LPXuJbXlsccfqIC3dzPLsAqB0XrLcV9FUmKB)NJHagEZ(9CGUr41rGPZFlv2Ps(gpLSYVXtXAu89YNMmLtZjLinRIvZPVXTRuMBNOmt)9m9DBxkDNWpEm2gEHjtdfGqjL6w(hxKQw(hNiRle6okniL7AvadFzMHS0CBkEGbiW0D5jrz2Bj1pNN4hj)6tGah2Fh5jYj8he2MSvSWBkUyciXveQtKo2GxUGPTmnBxsreGCkyaBdmKKUptXZGgUxjd837jWgz4muiQARwPcjhnac9RlE50gu5Pm2NkJSV)DM)NS7dMyVmclrYv)6coF1VoPnOJmuqaHsNn757huOKKcavC6buY6d8Zjxy5)0j8CYF6eEoYwlmsKrSmhWX5un06PE184aK0baxTj39RAKPlpxWhB5lCHx8efBCx8eLCAZQuB3CfwnKEMm2infuFBo2fsV4abje75v2(NhUhXrJKX3ueKtEWDihZdUdGHBSiLGSMnra2Lve4h4VkF7h4Vsm9DKZ1IwV5d2T0lb(zXcDF6ficDF6fqPdMZ7rTbRzSRFSmh76ht0PoChMZQkyRApWws)ASHonrBZqNg5bN5aq3ly6eR637HKT49Eis4S3mM(owLsZzmQQF(BAVYG20Eb1SlZC5nzLS9RBHp4we74FWTa(X299cipvhYMymrKj346Kn4nUoYabcufUqf5nkgTQ(4wu33Uf4(2gfNu7QkLj(1kkraKIzLYQQxqjs(SFpElU(dkBX1FqApeMJ2AcI6wuhSULhHiTuuD1m9gBy1YVUHvtHn6tHwuLBo5o0Z)o2lHJBIZ6qBE(PHwo4qapKJShzihzpSih5So8nT8X5R(EFvzu79vd5JtUEv386HU57VnlAlLpuFt8n0SCQ3qZuOUM(9dbfkHuYEET6EETucwTH8zn756k8UITXcuvJo1L6MLslwPY1yDCJkkBJhKgrt(cbtmX0P9aYr)n0D8B8QKd8dAwOOxwbLDvso4beeSffKVF6JbLPOU1Br36TGJ6)h)fVR4tcGSRcC41mHosQK35x7Nq25x7NaKAIloB1nD8n0QoTTgoT1v4y6j9yK9RLmyaDwXobbhx9dn2HsH3XQ5tlLoBsTdx7uOMr8y8RlfbcqCMAe)YGqsb(5Ym6nCD)vUIrxhlT2iyTmH7DwfmLspKY4q3N81h6(OLymrEsA1ee65FMcc98ptHUmqGV4gTAZrqbxSIcUyCk3cuU86QsgOV8UwqaLaqxtrbuS1EsI09ApPiFd37He1y79qCe)197(q8qaKmy4IiNljwoHDyE9CxP6i1kzt0(5iMbe9Ce6RUFKyrcqmfDAzX0RQgNF)xj9ZV)ReSPSLv48oCJM3mZ(dlBMz)HXCpZARi5sgXMtndv(DQW8XEEjutaP4PPY1NMkqslwzmf5NzpxDUMljLv7C1Bgps3icxxKNaeOk4Jo(XOStT3TlhZ9UDQcwbfhmWU6rm2bK6Sci7cULz2YvnzfFkdlZ7ugo0b9(9zJI0Vw)j)lLsrCYuktM489gjQyKiKHHqW5XeQ(MJXB8cE2oSjOfz5aNa811ybIseaHW289kbT0cs045fNuaK59ksPQN(EvDkpMBvlC4TUmEnqaAKBNwWtmFoAebh4(5us9NJgv7UW5aFRCMU1iJDKFJSnoYVHomlbg7crYfSexqIpRfWZcGGdR5uj(Asb8bK87QD4Rl4WQwiHwDZYzKVnqs9Yl(aS5ekkjbMIxL)tpvC5p9uXbowuzf47hM2Y7qv4ChqHtHPr6F7dtMeQiLo3La31fpoFNlsg57CrCseCi(KfNxQnsDUFbfb8fQOLKOiDSQE(tmSirbiHSRjnZl0oF)bCP7t(06U)PtqD3b0rnGwG76CZOZFg2IkXPmczoOkJ29)negT7)Bq5pfMQksf6J5JgVMR6XNnkaRTjjZbqYxPfxOGp5z)WwPxmiRSL(oq0XbHUZB8T1u6)ThrOE55m3IfixKh)V4Nx28V4NNvu56Api58hIrbrIeM3N7uZw7DszRDYSNnZTxpZHGstXgpVHh3dkB4X9GqJzNyB5ugeIsw51IzVEzsE51tBgWgeWX9TeVOclySDn)GB)Rc199nOTOoeYFwcMEDtq2SRBcKnqpxlOCYvlNAD79fvj6xKYTFG3vBxdJCSdksDacIuJWPbF1qCDU)Rkr6FvuK4a8dxzQQMhF7FISUV9pHCH1AapQQrvtJ47O(R8oC6MQwP0wxEbQgGAznoqmrH1bIXedkBMuZB0JvjsejLXhsSbdizsSnobf4Sx2XAEPfvqco4uuCWPuj2wQlg93syijrcqWfrzRcE8P(vAiAYaeyfob)JnAlJDPrsTlej12HlWKxhikMWagRZ5hiOhhU04H4eo2zOO2CfW)OugxV6571)8roLFQIamGKKdfQxrU1RAYR)W03B8wklXBrSetIsltPbbYaX)uL37B1JmMVvpy)rQWO2)rA1l5aUg9aUgYPyly(GoGrX0z8RNV87)65tfhD5SpvUAfBt84DliUhVBkJNWdst4WRl5vUyMi5wf5Fajv92fgehDwoM)13ETkFbC7A7H19UplZckJX(vC7()DIAyFUDdsZfnLZFRWaMxza5II1HVN7auxzuJdlVX)TmpVX)nodqS3ZVuGRTIaUEXsgGso931Lk)776sHvpolLCjstz86Fd5hEDORz)T6MdXkkjNPjZCPI9ABteqETTr7IM9SzACxMWb92Gopbzo6diBKrFa2POmCzMGrln2SzOmBZ4DPCCZsjJy6i9s3HFc53omLZWtDzEoLmrmAmUK3F0GI)BxJyl53UgYZCZIdIJVz)owNb059NuDF)jkOahymGDGv)Yy)IPjB)FX0iPhO7Oybni1A96Uo3BqX13aRjZ2jNu85Ae23SWucyKE338XL1(nFC6RyVrOIJoe75uxMs3cM4Cf)JbKC9Hq75leLTVhzd8cdyfolJwHgs7WnRxE7s0PmvYrv2TrzZnnocuXsvfBbMzTcnQy8KQTVNCJKcGtL)BRu7wKvsDlY0wc0aiAGAJ8(On4JNzrPvesSGpVSpwaPVFIT745xBTVtz0I4ZeGvgtr36DqOOxCa5HvhqEyYbKj3tqPbzd6nMlhBospWJtBOGXnkfMmuwMlqYCyYJk1kgqkj7W3BnAHSkt2JODt2J8fjKa1Iq0Vrzhji0jlJrD08f7WJXRp8ZKXlsnJPF5g6rkVxpRMddvCBbY35d9e9J)jK9Wh)tqXbtAGZR1knvYdnv53o0ubDeCpfSR2qr19JEt(hbuSxMHYiiuiHGtYgfK4ANTmdRD2vI5JOPkvsc)U(4)rX3W4uQpNIg158iDbyqKEbI2Rk4h9ui0lwbBkLoGFkJNF0seFFsXiaK2hlzq)AA6nGNKmjBizAfqQ37qamvvBgFxcso(UieO0ZKh)z9FtItgqGi4AA1BqMmEAb49e67WEqm5k458L2KquEjk7EtSwxY7gNuywxtz22PuMnjPF2kNUXmz8TIYVWtMso9pzQOKLndbBcinTDgKzOWPTfFtoOLKp0PlF1dD6KEjfLXfes4wAtvB1gzdR2(OLldMPkALy4XRNPXti1A92Z3m3CgXuMmv(BuY3Zj1nSNykHU2jrCew45Pg)MxCYrLZTPZTTZnDBHkSxROPfqAv6jWLtT6WuIVOEVuMHnOM12a0ew5)M3DhsSecixIrxzRbY6CxG0DfZw7RKzBtX7maL698AAZI94Fl(3aeyOqN7s3U6eVXZQY0pljtpJ2GGMPVnCdSRYWHHmux16eumSjDUS3wg8L92uhaZUkq5SpQKkjFP7wihV0DZkrShM6IKESO(Vo010J9)jZXX()WqoRLbDpqleHlMhceA5bfNB3W0e3o0lS8Cg2AfcUFdVGIvOudpDUbocPIKoY0WeBb1zYel46e01cUosp55iC9ts4qJpj89P6ntGJKDXoL(bNZFSF5ugFqrffGv4mPf2XHZjQQkjVNpMCgVNpgqOlZwklEZLZO954v(wYmCLVfMHzfgf0FRwSLNTdR6Co8ujEcQbqIslz30mZZzMJk7(mhLSHut3p1j5qrFEWZ1IW8UMjXx)VgMfYi5eJRuPCx5Bt4Kfj4KjRAcMml1wGKZzl)zdZbHXzRPx6SxlzzJcpOjtxTnJnE4hu2vp8dsFFRupLjvpJvPNkPRuHjaz1P4ZQMf9K7(di)4U)avKkTaRn5evqJn18huZvYbptQHSWGcSQjO74NR48mGuNuutL)QF8I1eadvOeRfP5ZbSc3GriSCXixn9tLrM3rr2VdyY71YrAXcBw1sdNbR9ea4MsFCsoRwBIehtc(gqQGRdksAvlCq8tt5bpn28PxMHO6G2vvbseN1(e89DUVkCF)ZDZPdLGkl3CAVumHkYyMqfSkq)DXbfCEyACCvhDCRiH26AwSyqnvel(L82IVwxc4fU)UHcbfFcRtcheG0biiFEQn9SC9ll9v(M1AoV5nqXS6yd9XDOT2uDBr(Y62cTXBIsyN9Xxk24Pu(Tue)sJG51tCKI8MtOztqs(dGHLLo59CUQ425sTfxuJgBCvsCDasDkc1ZcJ19)4txxTPtQ(Hoy(3Pmg0yPsuT606WFk)fzjpL)cHVQ2fQbig78MChj1W2(NzQ(2(NHGvRlFqtOrm0S16KI5ci(8zoF4v1k4if8PEKGMhQU7rYtFzXtraPn1y6KakqjhPUrPmEEPObac8WRXl0(0UlEFFpYYsGJJvPIHXJyCBVHm(B7nQWLJml8coGu10tqu)zMjUYxtXLDAINtN3fwAWADFkLXRO2OEfYg1KAKtkhHXGc6WO1tEqnVhhmb3rlEJq5CwcSQ(eApULGAqYtvkgz6Oix0YS(rMKSiFKjX4Cth416qWJxYXvZHf)mmEiP(OaY(9BoIK9OWJC8PQstKIZP2y6MdCkb77IU6M9aQSyQKR6ILD6QUyQv0SClAvTQj1FIpJSvpXNHWO25sZfHvRY9P80kBbvq0jg1g2D77L1wlx50)uYKp9pf1mkkdynnJY20lXZ2AHk)o3jsrrqA8Akf(1afEJCGfSGGTERqMVKWdazgfV8rXS1OVVxUqRPjozXGlGKoLLaFskk5AlhLp7W0R0JeDbG0Sj(F575vItJJDHcHQ(IF6QmZPZsOUu7CWIm9g2ECj3T0Gwasgswg)zjVx5ZsEVept1MOVMIRK8E(iQy8hH(UUKLlTUCP5Gklb)KasOLa9sq8mIHwaPDtxw(uELmHP(s9df38S(MNLmRV5zr6QnDZfqoCun1ugBBpknypswqiUXXu6SJQePJ2suMZ)1Ad3(RVhAsvNvR2cOnSTRv0gCTvI1tVMABre7LLwJbWkuKyEb(0vudEJcrqleJsgQ7RtzSf9IeSLBHkhO0aBDpONLR9YP5(E2dnlaqQMRTUc3H6c9DqUqFQHDqxJzV6GAU0dXe0bGyYxk5fRZyU2iV2UvMUDZw8HleSotj)QI52Rvdc(APGGJZF1oLCLayuCXJQt0O7M1sKX3RFZsCu9HD7rdPNcJLspfyPSDU0VGSmIAd7a63Fa89RxAAUA2MPLimaK6kUve4FC(qM8EUwLz6A58WBszzoYLGe7YrKj2LdL4hX7ulvUo5bL2AbqUz0YffED8jRnt)K)94xA3ZVC62ceff1jThhGeAtQph76BMYq9ipTRv91zTxiDDcjp7RY83q6zlOcegZQUCtttF8)4LCMIuoG0el3teyrTmSMhQ1oTJIlWHz79e0F5XIksSlx9W6sYv3mVFpVTjbBEEKo8PuB4yTU8cqXOLFcUp6s8K0Y2mPbWzmvYjvIkseGaILLAyCIaw93t(OsFmaiCfGDhhSqcgE17x(PvVFo1AVNc5NCu1I(ONlX8C5bZXHBDSA7wfJNuZj6ts5eDYSpurvRNAEBr493in6nGeFa5aB)b5qabsL64UPcaekERujXLoqo5oppz5355rN(oid1sJWmVW2ZT(XjSNaIth7jD)H34TdCokN75GVo9cnherWMMusynsOncMFwAhewDXwzr6TTv8btV20OshMfAdojkv4PsU3Ji7R9EKWuPg)5KE4aqsOVdxRL75t5lkDJflAc7D8M9K1n7jtYItPQ2xWNyxSA3yKu7hKKFxMPWYUyEY1JmzcYtHLOQqITxPh0aK8sq65QieVLtXs(cAm2wolrF3wiDnH8ynzsz8a(VMuwS7mjMLzeEnD15rcn5YcSKIXK8iQPHJatd3vhuNZBs6k5dxc5sUciftdLNw)S261C81(OsE1FTpkXJ0BGnzpJTwL3Mtgm2CNHUjpd60mMAfoKTFE4uiC7nrlY1PcqiGsQtc9dR(XlwOams133VE5O99RNo3VNoyo(18wI31xZBv54kpzFuVrdkD87vYHfGv4cIqxpe2urtEUbWRL7Fwcc5(Nft2Z6Xj45Y9YLBU9A6RRZqstSci1pgEoLgtgOJ1KCZHaKvTqlTqjJAk7KhudK9GFmQFh4k2UKbT8ud2R7MfS764gPES5zcipkGZvyiOIvyqy3OgYOhlBkr2zI8)i(1OrCCnV97rHeObIJNRsRn)QOAZp93BdV1OL)iLDPdxd)b2)taOJgu2Y3ctrpJAi87FIkr6eJuFqcMwoKJUr6oVj5gsbizYUr3CoWrO5qD)e3gfSl8IRijeDgawHDmQ4i8fjRBFZYHd5fL8dciLZmi7dKjf8p)JpO4XmGKkVAKheTF8y(HANu9dVtkrnrDWG0lfnSTNt0IqD60K6RSFEkh71K869kPiaqUyaXh66u2JRtAP7mdjLulmJ713G4RhGCD2DeDxnbpNyN0p4TtZ3bPKmoX57565ZEFVekT7LszSu1rXLIp(M7KYbgvct5OQmfpiXumziowYMUSc0HDr2bRWKBvhJN5dkJ6z(GuZTrT4DZMfP7naZ794Y9RaqY1FIHLYYRFEjYG6NGKUlaJAE5huLkFW6jrMfA7Y5W44st2RPMlEnGJ2)sHyxEwLrvNb)WspsaiP2sso7iHP7Fj2zjIkvxtEWRu6OkajUNoHGzwtPveHz)0uVrd2xM9)eeDQasglTRTLL2LgGYUUyElrxOwqLqyUHCYNLCxwaKoylUFQhFnDpUCQTv5AgcyLJ7gC1ShDr)Yqr(WR3MKROpG69(aA6OEUJYanR3ylNTQX8SpE1xntPZgQltU6fkZXQxiLactrTWLxecw8MPr1czJNtT86TZ5ztnVh7gLoodqiSq1TKWYH2(3VMRQ9tAlovQfHcC1efys9qapOJPIBhJsh)exm8Cya6oqVmBi26rCILyhMl9lKWRYIqhQPls3EDYxV96inxrfdHBlMS12xSpJ08vaYCZC)uKvgxn9g3lixKvazLT1CX1cVg6jNEjzitVeXdyA7ef8EY9O0K90iTx5YG2Sz09Qm5XKgzaq2AaNQEMjHc3XumuL8ruAYJSqAhaEBlepkzoSAZVDEIzwaRqPaf67X)hi1oXUfoKm30ngLuT6KHcyLO81NEjwzg01MUR7mjSIibdyLy93QRV6Dx9jKK2dion9HdAyqRsc7Ft1r538c5BTTzUahVcG3q2JJEPYEC0lTcNmMQ5RxAMEAqjYj3zBazXPAAusJ3vBf639wjVHLR9(5P6Upps390(BCUBtZfEYlqSAai1QaWZi)I6Td8yZw52Okrm5gzbkYlUZr9Y)VJhv8PPPKGkf5mAKtwG0Z4ZTDFkl1TyxSGJz5ujFNlrwP35sO4F4YkwWYuV)A1N8DeuyY3Hof)oEU1MiWGBIGP0HJta3)hl0R)YqpxNa3Gt4hvpPFuw9179KwtN)wFdZqwKgMr1f5vodzcELZGsVzyBy0O2RW7tnITVeug3yKt6UTZmK5YfzLUAtmb1vBGYVu3(50JY(vKkr(FOqZY)dPugfWnNUELat(CYfZfqQx)SZbZWPB3JaIL1njfNbWkuJiyw1pePkCE(AZejp3gaIXnZoYxG6R0Ssgzk5bHfRACqQUlC78ObKM1O(lqirv9Dj5N0xovFsFkYot66al5apLXP8jLn2P8jzRKK))uGmlcFCyBeSUHK906gIvgg27l1Mq3KhwEizaKm8t9dN4NM2QcFX7ukC7xKUf8Ng1NpMCrJt3fzRMAfuYxS46RrtC61OzQARnYPiG6kQOgRm5LwuwSlLE5pMyKl9vXmn8W89mbaSBAnJJDbCI5SxXeJRvBYGRLLq7Hr)ujn4cPAzoayEgNYenoIuBZ3agT2jgVGskFHXtn6kL5qXcnFqNVuSDaPO507nQLg4vY7vUkEasbclM)kLMlyIW7QUK8kNETTquFHxW84xX)MOt7k(3q8GWEbuDkDv8hsslnGqDsJ9dM2q7QXg5XeJHJ8yqHqNEEAX63K88Lai1ScoblNE(gkfA(6foz9mEYqWkMKcLTRPZB7tGQzKvjYj05W3wk(NhvvVmkPEz281oXmtP5rUJNUx1Md7nPEwpM6TZXyVDy1r8Mo95mFsFKOnAdYbgq2Oe1Cq2UJPftnEu1u9JEoKBC2dqQhKEAi(VuUVPaIFQnlhPliXsolDPPytMuTlnDxA(7eM(bvM(bjvlVfVux)CKV76NdLuTc(qmhUXu1rNepI0QvaYNj9oDhabLQMJnoM6C5XiNlNyn6HjNtKJ9O6gC0zrO)XZZ9DkX(ciR803NUmcKRFs)f6P9b)7kTzpGK6pQNJRjFwtHRllauEJanbglpdEbBrSObiLJzUv)Sc7LVe)kn0YF1DuTx(MOm(TnrsgGUkaWPYa9MyU))o(hbKoGHxCmOOpQmsXTLK5cyfoQl6rLGCkLIVK6f0qQBYd3LQxPlSL7gmvGaVCEl8Gk)2dYfwVrYcOO0HBer(J3R8yXaiWfDuCittFt6NjBQnmlUApaq35dCule6bDYDlLQgqWO3uGVB6sEPPB9GmR74kLFEhxjzlU9Y(EfZ4vaXVTq4MQDw(FJO0nmvUX2aGufW5TNivMI14VNMMZV3zXijpUOHWBDhhpfVxNZ3vQcMdrXN1XN1LWo2QhojbBwmBciNRRHklVylrsjhqRwXb4AhVukzyK6xj3iuAhIAS74J))uOnJ))KmLHzH8TMB4lIxPHnjPKAtuUvMu4BhdTPQwKW1OMGxZzqCtEoGM2EyIrtEyvXZHVmQIc03uLvl5ZQLJ4z)uy2NERzi7c0CZLGMktF2i)VJFbIXFaP7PvgRbceLHjAvU6TaQM08lvSFkh1S9(uX7s62kaJsx(MvoLntpnstUxkvI6ZSIKkkbjUsjVRaIrDg9MNkmKpN3pe7jJh0nl5aEGYmTmLzIEfKOBtMlxuXEcSft47u8mgWiHRnOLuydPjvplq0imvvJWuhR21MH9Zm2SZeT4576LtFDX6xfO7)cROpuiffVnYom51Vw)XrNIoRtH0ZCE8goLOYfqSH(8YW0OehLIs80RU4nI4IY3VtuVOqpShAR2PLLF0jhnXjw8Vvill(3IjU7uXpt5ABbit)SZe6R0Ott)4PrF8htKfUnvwGEd0MsTYc9yMFitiiKk2Blr(cyTnAOEJv(es8RawHFtuYBL1UMUG92K85cyf(Pcq6iIO((MZEapphtE3JaScF1OfFGiRsa1sTjQwEWr1cfpAQOdrIXjLPfqY8a7ifB2zmTR83skofGaTWVQbYlkrYxsEzRaKKnAkWzeTzh6HloaVFvrG4Z69l42z9(jPuE3lY7vFLys(oQZiVZLl2HiLjJ9kzymQ8aAaigYmRs4Np8F1BKbiVyLlxskJNrAXbajM2)i)5ZrJeAoxALOsdm2YWM4eKQ1diTrxKhCz0rVgj5J4sNPIkNjHkVe6VfBM7uO1ZCNYTjBy7H5IM2KPGfFf16WRWrWf6jv4J3w9niC0asjosAXNX0eC7uEAPaKvZvBc2BYrE1em2NMG49LKoY7xw33NUUVVA9Gl69hS(gMMUWtlkILeJtXbJJXbG3mRwby4YR2XBjFvTArV61sYZi(b(kofLzeTV6MLK4dajm1fJLjLUCPQgG0O6wC03xKZfjFgXZgajkLCnwslVCqHsihq)SdWF2zZ)TtsAeraJuE9g6WEJ3hntsy3J55QkLXfPQrVisn6P1hXafQbHVVCJuwRV8bu3HpWPhTKjFvtfryceCyRLs1KophPCYTkntkGuI4ZyPU)WZ37QmfV7SPRnd5VbDNxT6pQsRhq18EG0rlyCdPNfaKOo6nqqI)H6(x(7QtCjaqO5rt75aAhZL8OkR0rjwPz33GML4I77rDoZhgbj6LL7Ie8VXS2gBvZRZwRJzTri801Yok5KjFbP7eaSYXNOMGIsZ82H0UYasDrnHG4B5m)BTlkWaKjq2UvVcPMs)Cvxm5HocqspvvThTynGv4nwO(g0CK0WSJyTs(LL85diPLokEu6z8RA312Wm4(yda62xZfBHcamGErhKCqbyysrRZ5ouf)0Ze3zE8ob1oL8iBt5mm)YxTPd82tViI79Wr1GAp6DEApdxHlwb9iLasFT1Rn(NvW6X)SewpJ(W0WEMYh3Xl81agYQhFi5Ilai8nTJmLt3AwTtWFdrUaqUUgU588G3FHANnEEnXXp)hKipCNWf17jJxtP94p9irQp0RlAH)q0LmEAh3DRyOYq3e5cOXFufR(JKy1uIYdl8)wA8lXms8ls4vbK6U4WmAwTRoQ7TwHq9FRvqPgvUwbY7(jVB2M2MoB7nyZg5GPl43nfH(IZQH2TxjV9acty8f3s49I9MskJaKfolNEjrVKCj7sAjmajdRSJLCV)0FzY(yMOmR2YnktEl3ijetbxAlYhYTkVHlNdCdamnW5ahh(233SFvVu43HJIouzp4z8M00oCtnr5toSAHvtwNXo03gRDq9D)exSF23RRHZwE52aKez42xvQxwn3OQ4NK0)daknYbLS3AFofIpRpSQ)MUIHZO1sKPyh9TxSfBZ8Ei(x2F)eni3xiajEc4JDw7Qf5m8LUcCrLuUPsrU6UDPy7acAWLfqnah9SAWNIhxPTpo3cwnwT)uryas1mB4H4hecaO2Fx79RMT91ohn52K2Eaqw7cD1yHg2bCIE6qA404xTfaWeeEBBRjR21RpoD1pa5NM(87Y1QJ(40CGXaGJZVHh)H(cY4p0xGzhPmjszaJA2OWob)11Bq8Rt3G4jlHRpMlxb8qrFjjNZ)eP4)s5JYV6yYr5xDmovGd6bhDJ6kNg22Zk1Y6zPmm1FTx4QelqTNVaYE(u6DilhlUtI8ChYQm1tfYDkzoQgN58zjKT(iXmw3Jm2T22k7MABLPX)PVI(yW8vUl(ZOmqsOOAFfpnUkT9kVksw6uBZ3oND2J)HWl5HeFebKcZ1JYUnXpAlTDEIhrEtOaKAGfjvgldQZJEPv)YskpbKmaCl8hD6Fh5Jo9Vdv0RW3e2EmLGDmEs5HbdqSVMLCjVtpxQGEwdrveQf4Wr1xtqJdQz)5Gu2FM0sDZ4XDZznImnSg(XQfaGFsYhRTixtFaPl4Bqgek889qCFfrSK8SgxDNm(mjF)i7s0X2l9cd7BThuY3bGuoI9C8ywQUIADQNrO8pdHxOlJynLWS(XRp)nJ)6JuF)T17W13E(v(B9wBmMEM8wvC6TsVVJtL9gI9V598igoIUmJu9A(in7hGexo)IXPAG4w3uITk(RjHJci5PIpj9h9WqM8P0hs2N6hqupllhPvhc8fYXEoFzf2Z5t81uUD10Jtx3QLqLdINL)6pvML)6pLE93476e93JDuPAxasmLqNUBXbuTKvFY(QtQBgGa3ZVt4de4uZJk860qkwhfsXXvr)2IsV06KN3haReE56)1ssDaKkwlFXaQMYkJ1kjshqIxUjEsMM(GBmTRUc9WevYt9qvUc3gBtFzC2gPjKEwUOBin1oRAtg(JL9aGyNotebqbBRms2mOZo928wZdjYvR3bKR(0fpu0CS3Kp1YOIzQ38pRe4)mRATCEHpcXQws73bJvPx3Wv1t1(PO61ml5MLawaSIEtLnEeP2GawHEYsjT8PRsZmEa5vkaqnp4utQPHPVF9ngy))HQPr5j0f4jQ(NUo9pDDe3pv0rF6cmoh5QNXfji6Dy5813s3ZNkb5P2Jh7bGecXaHxhM4NI(65Dk)VKsHLu2)92uej)5AT3)5Fz6QnMVqzOXGTJQVNjBw1rS51fj(Sh9QwVNl6VbZ98dZADY7(MKV8UVjmSurV1lh3JYopJx1MLz8Q2mD)L8lxtjctl2GbKiLQQ)Xuo86NG0ylaY214lt3yJ6i5E0RI2EAa0URGUffe2mILAZ69nEZuJ5DQu3ntU8swIHyVQeV(e)JYYK4FKTvf4mqG)C7uFnlPNXhvSRDvSRDY(4xJ)BhvtX0rPumDQvF6FRn78jFA1RUNgwIUlQTb6nZGwcLm5ZkpwdasYYlYkGVMaK3CzGEHUg6JLk5g17O6gxlhyfcPYXk8zMmMP8QybifRTNpLRBOqWvlbPrMpR43CgYaBTV3UDzMRa38pPVgLoCneVuR5PlQq2JRVe(CxHmMp3vuH6lHOCGWZhLV6SwIhSX)71h5K)(MPl7lNoBqq44BPFVUFJ8qsdyLAEbCQEDs2Q08MawTTAR5DrOUf9kY3VOxHUO0uUfO7JpJkQ7hkf5PUFi05sxyR2o3ugxG(E1Eb5zfyS6REgSCPbL7PqI5PK(5r00)tElSD91kB7Bccg)u8Nwf9F3kws5cwB0eKh2tuQtV()9!BBF"
        local profileData, errorMessage = BBF.OldImportProfile(importString, "auraBlacklist")
        if errorMessage then
            BBF.Print(L["Print_Error_Importing_Blacklist"] .. " " .. tostring(errorMessage))
            return
        end
        BBF.DeepMergeTables(BetterBlizzFramesDB.auraBlacklist, profileData)
        BBF.auraBlacklistRefresh()
        Settings.OpenToCategory(BBF.category:GetID(), BBF.aurasSubCategory)
    end,
    timeout = 0,
    whileDead = true,
}

------------------------------------------------------------
-- GUI Creation Functions
------------------------------------------------------------
local function CheckAndToggleCheckboxes(frame, alpha)
    for i = 1, frame:GetNumChildren() do
        local child = select(i, frame:GetChildren())
        if child and (child:GetObjectType() == "CheckButton" or child:GetObjectType() == "Slider" or child:GetObjectType() == "Button") then
            if frame:GetChecked() then
                child:Enable()
                child:SetAlpha(1)
            else
                child:Disable()
                child:SetAlpha(alpha or 0.5)
            end
        end

        -- Check if the child has children and if it's a CheckButton or Slider
        for j = 1, child:GetNumChildren() do
            local childOfChild = select(j, child:GetChildren())
            if childOfChild and (childOfChild:GetObjectType() == "CheckButton" or childOfChild:GetObjectType() == "Slider" or childOfChild:GetObjectType() == "Button") then
                if child.GetChecked and child:GetChecked() and frame.GetChecked and frame:GetChecked() then
                    childOfChild:Enable()
                    childOfChild:SetAlpha(1)
                else
                    childOfChild:Disable()
                    childOfChild:SetAlpha(0.5)
                end
            end
        end
    end
end

local function DisableElement(element)
    element:Disable()
    element:SetAlpha(0.5)
end

local function EnableElement(element)
    element:Enable()
    element:SetAlpha(1)
end

local function CreateBorderBox(anchor)
    local contentFrame = anchor:GetParent()
    local texture = contentFrame:CreateTexture(nil, "BACKGROUND")
    texture:SetAtlas("UI-Frame-Neutral-PortraitWiderDisable")
    texture:SetDesaturated(true)
    texture:SetRotation(math.rad(90))
    texture:SetSize(295, 163)
    texture:SetPoint("CENTER", anchor, "CENTER", 0, -95)
    return texture
end

local function FormatClassName(classTag)
    local classMap = {
        DEATHKNIGHT = L["Class_Death_Knight"],
        DEMONHUNTER = L["Class_Demon_Hunter"],
        DRUID = L["Class_Druid"],
        EVOKER = L["Class_Evoker"],
        HUNTER = L["Class_Hunter"],
        MAGE = L["Class_Mage"],
        MONK = L["Class_Monk"],
        PALADIN = L["Class_Paladin"],
        PRIEST = L["Class_Priest"],
        ROGUE = L["Class_Rogue"],
        SHAMAN = L["Class_Shaman"],
        WARLOCK = L["Class_Warlock"],
        WARRIOR = L["Class_Warrior"],
    }

    return classMap[classTag] or (classTag:sub(1, 1):upper() .. classTag:sub(2):lower())
end

--[[
-- dark grey with dark bg
border:SetBackdrop({
    bgFile = "Interface\\Buttons\\UI-SliderBar-Background",
    edgeFile = "Interface\\Buttons\\UI-SliderBar-Border",
    tile = true,
    tileEdge = true,
    tileSize = 12,
    edgeSize = 12,
    insets = { left = 5, right = 5, top = 9, bottom = 9 },
})

]]

--[[
-- clean dark fancy
border:SetBackdrop({
    bgFile = "Interface\\FriendsFrame\\UI-Toast-Background",
    edgeFile = "Interface\\FriendsFrame\\UI-Toast-Border",
    tile = true,
    tileEdge = true,
    tileSize = 12,
    edgeSize = 12,
    insets = { left = 5, right = 5, top = 5, bottom = 5 },
})

]]

-- Function to update the icon texture
local function UpdateIconTexture(editBox, textureFrame)
    local iconID = tonumber(editBox:GetText())
    if iconID then
        textureFrame:SetTexture(iconID)
    end
end

local function CreateIconChangeWindow()
    local window = CreateFrame("Frame", "IconChangeWindow", UIParent, "BasicFrameTemplateWithInset")
    window:SetSize(300, 180)  -- Adjust size as needed
    window:SetPoint("CENTER")
    window:SetFrameStrata("HIGH")

    -- Make the frame movable
    window:SetMovable(true)
    window:EnableMouse(true)
    window:RegisterForDrag("LeftButton")
    window:SetScript("OnDragStart", window.StartMoving)
    window:SetScript("OnDragStop", window.StopMovingOrSizing)
    window:Hide()

    -- Edit box
    local editBox = CreateFrame("EditBox", nil, window, "InputBoxTemplate")
    editBox:SetSize(150, 20)
    editBox:SetPoint("CENTER", window, "CENTER", 20, 10)

    -- Text above the icon
    local text = window:CreateFontString(nil, "OVERLAY", "GameFontNormal")
    text:SetPoint("BOTTOM", editBox, "TOP", -10, 15)
    text:SetText(L["Enter_New_Icon_ID"])

    -- Icon texture frame
    local textureFrame = window:CreateTexture(nil, "ARTWORK")
    textureFrame:SetSize(50, 50)  -- Enlarged icon
    textureFrame:SetPoint("RIGHT", editBox, "LEFT", -10, 0)
    textureFrame:SetTexture(BetterBlizzFramesDB.auraToggleIconTexture)

    -- Text for finding icon IDs
    local findIconText = window:CreateFontString(nil, "OVERLAY", "GameFontNormal")
    findIconText:SetPoint("CENTER", window, "CENTER", 0, -40)
    findIconText:SetText(L["Find_Icon_IDs"])

    -- OK button
    local okButton = CreateFrame("Button", nil, window, "UIPanelButtonTemplate")
    okButton:SetSize(60, 20)
    okButton:SetPoint("BOTTOM", window, "BOTTOM", 30, 10)
    okButton:SetText(L["Yes"])
    okButton:SetScript("OnClick", function()
        local newIconID = tonumber(editBox:GetText())
        if newIconID then
            BetterBlizzFramesDB.auraToggleIconTexture = newIconID
            if ToggleHiddenAurasButton then
                ToggleHiddenAurasButton.Icon:SetTexture(newIconID)
            end
        end
        window:Hide()
    end)

    local resetButton = CreateFrame("Button", nil, window, "UIPanelButtonTemplate")
    resetButton:SetSize(60, 20)
    resetButton:SetPoint("BOTTOM", window, "BOTTOM", -30, 10)
    resetButton:SetText(L["Default"])
    resetButton:SetScript("OnClick", function()
        BetterBlizzFramesDB.auraToggleIconTexture = 134430
        if ToggleHiddenAurasButton then
            ToggleHiddenAurasButton.Icon:SetTexture(134430)
        end
        textureFrame:SetTexture(134430)
        editBox:SetText(134430)
    end)

    editBox:SetScript("OnTextChanged", function()
        UpdateIconTexture(editBox, textureFrame)
    end)

    editBox:SetScript("OnEnterPressed", function()
        local newIconID = tonumber(editBox:GetText())
        if newIconID then
            BetterBlizzFramesDB.auraToggleIconTexture = newIconID
            if ToggleHiddenAurasButton then
                ToggleHiddenAurasButton.Icon:SetTexture(newIconID)
            end
        end
        window:Hide()
    end)

    editBox:SetScript("OnEscapePressed", function(self)
        self:ClearFocus()
        window:Hide()
    end)

    window.editBox = editBox
    return window
end



local function CreateBorderedFrame(point, width, height, xPos, yPos, parent)
    local border = CreateFrame("Frame", nil, parent, "BackdropTemplate")
    border:SetBackdrop({
        bgFile = "Interface\\FriendsFrame\\UI-Toast-Background",
        edgeFile = "Interface\\FriendsFrame\\UI-Toast-Border",
        tile = true,
        tileEdge = true,
        tileSize = 10,
        edgeSize = 10,
        insets = { left = 5, right = 5, top = 5, bottom = 5 },
    })
    border:SetBackdropColor(1, 1, 1, 0.4)
    border:SetFrameLevel(1)
    border:SetSize(width, height)
    border:SetPoint("CENTER", point, "CENTER", xPos, yPos)

    return border
end

local function CreateSlider(parent, label, minValue, maxValue, stepValue, element, axis, sliderWidth)
    local slider = CreateFrame("Slider", nil, parent, "OptionsSliderTemplate")
    slider:SetOrientation('HORIZONTAL')
    slider:SetMinMaxValues(minValue, maxValue)
    slider:SetValueStep(stepValue)
    slider:SetObeyStepOnDrag(true)

    slider.Text:SetFontObject(GameFontHighlightSmall)
    slider.Text:SetTextColor(1, 0.81, 0, 1)
    slider.Text:SetFont(fontSmall, 11)

    slider.Low:SetText(" ")
    slider.High:SetText(" ")

    local category
    if parent.name then
        category = parent.name
    elseif parent:GetParent() and parent:GetParent().name then
        category = parent:GetParent().name
    elseif parent:GetParent() and parent:GetParent():GetParent() and parent:GetParent():GetParent().name then
        category = parent:GetParent():GetParent().name
    end

    if category == "Better|cff00c0ffBlizz|rFrames |A:gmchat-icon-blizz:16:16|a" then
        category = L["Search_Name_General"]
    end

    slider.searchCategory = category

    table.insert(sliderList, {
        slider = slider,
        label = label,
        element = element
    })

    if sliderWidth then
        slider:SetWidth(sliderWidth)
    end

    local function UpdateSliderRange(newValue, minValue, maxValue)
        newValue = tonumber(newValue) -- Convert newValue to a number

        if (axis == "X" or axis == "Y") and (newValue < minValue or newValue > maxValue) then
            -- For X or Y axis: extend the range by ±30
            local newMinValue = math.min(newValue - 30, minValue)
            local newMaxValue = math.max(newValue + 30, maxValue)
            slider:SetMinMaxValues(newMinValue, newMaxValue)
        elseif newValue < minValue or newValue > maxValue then
            -- For other sliders: adjust the range, ensuring it never goes below a specified minimum (e.g., 0)
            local nonAxisRangeExtension = 2
            local newMinValue = math.max(newValue - nonAxisRangeExtension, 0.1)  -- Prevent going below 0.1
            local newMaxValue = math.max(newValue + nonAxisRangeExtension, maxValue)
            slider:SetMinMaxValues(newMinValue, newMaxValue)
        end
    end

    local function SetSliderValue()
        if BBF.variablesLoaded then
            local initialValue = tonumber(BetterBlizzFramesDB[element]) or 1 -- Convert to number

            if initialValue then
                local currentMin, currentMax = slider:GetMinMaxValues() -- Fetch the latest min and max values

                -- Check if the initial value is outside the current range and update range if necessary
                UpdateSliderRange(initialValue, currentMin, currentMax)

                slider:SetValue(initialValue) -- Set the initial value
                local textValue = initialValue % 1 == 0 and tostring(math.floor(initialValue)) or string.format("%.2f", initialValue)
                slider.Text:SetText(label .. ": " .. textValue)
            end
        else
            C_Timer.After(0.1, SetSliderValue)
        end
    end

    SetSliderValue()

    if parent:GetObjectType() == "CheckButton" and parent:GetChecked() == false then
        slider:Disable()
        slider:SetAlpha(0.5)
    else
        if parent:GetObjectType() == "CheckButton" and parent:IsEnabled() then
            slider:Enable()
            slider:SetAlpha(1)
        elseif parent:GetObjectType() ~= "CheckButton" then
            slider:Enable()
            slider:SetAlpha(1)
        end
    end

    -- Create Input Box on Right Click
    local editBox = CreateFrame("EditBox", nil, slider, "InputBoxTemplate")
    editBox:SetAutoFocus(false)
    editBox:SetWidth(50) -- Set the width of the EditBox
    editBox:SetHeight(20) -- Set the height of the EditBox
    editBox:SetMultiLine(false)
    editBox:SetPoint("CENTER", slider, "CENTER", 0, 0) -- Position it to the right of the slider
    editBox:SetFrameStrata("DIALOG") -- Ensure it appears above other UI elements
    editBox:Hide()
    editBox:SetFontObject(GameFontHighlightSmall)

    -- Function to handle the entered value and update the slider
    local function HandleEditBoxInput()
        local inputValue = tonumber(editBox:GetText())
        if inputValue then
            -- Check if it's a non-axis slider and inputValue is <= 0
            if (axis ~= "X" and axis ~= "Y") and inputValue <= 0 then
                inputValue = 0.1  -- Set to minimum allowed value for non-axis sliders
            end

            local currentMin, currentMax = slider:GetMinMaxValues()
            if inputValue < currentMin or inputValue > currentMax then
                UpdateSliderRange(inputValue, currentMin, currentMax)
            end

            slider:SetValue(inputValue)
            BetterBlizzFramesDB[element] = inputValue
        end
        editBox:Hide()
    end


    editBox:SetScript("OnEnterPressed", HandleEditBoxInput)

    slider:SetScript("OnMouseDown", function(self, button)
        if button == "RightButton" then
            editBox:Show()
            editBox:SetFocus()
        end
    end)

    slider:SetScript("OnMouseWheel", function(slider, delta)
        if IsShiftKeyDown() then
            local currentVal = slider:GetValue()
            if delta > 0 then
                slider:SetValue(currentVal + stepValue)
            else
                slider:SetValue(currentVal - stepValue)
            end
        end
    end)

    slider:SetScript("OnValueChanged", function(self, value)
        if not BetterBlizzFramesDB.wasOnLoadingScreen then
            local textValue = value % 1 == 0 and tostring(math.floor(value)) or string.format("%.2f", value)
            self.Text:SetText(label .. ": " .. textValue)
            --if not BBF.checkCombatAndWarn() then
                -- Update the X or Y position based on the axis
                if axis == "X" then
                    BetterBlizzFramesDB[element .. "XPos"] = value
                elseif axis == "Y" then
                    BetterBlizzFramesDB[element .. "YPos"] = value
                elseif axis == "Alpha" then
                    BetterBlizzFramesDB[element .. "Alpha"] = value
                elseif axis == "Height" then
                    BetterBlizzFramesDB[element .. "Height"] = value
                end

                if not axis then
                    BetterBlizzFramesDB[element .. "Scale"] = value
                end

                local xPos = BetterBlizzFramesDB[element .. "XPos"] or 0
                local yPos = BetterBlizzFramesDB[element .. "YPos"] or 0
                local anchorPoint = BetterBlizzFramesDB[element .. "Anchor"] or "CENTER"

                --If no frames are present still adjust values
                if element == "targetToTXPos" then
                    BetterBlizzFramesDB.targetToTXPos = value
                    if not BBF.checkCombatAndWarn() then
                        BBF.MoveToTFrames()
                    end
                elseif element == "targetToTYPos" then
                    BetterBlizzFramesDB.targetToTYPos = value
                    if not BBF.checkCombatAndWarn() then
                        BBF.MoveToTFrames()
                    end
                elseif element == "targetToTScale" then
                    BetterBlizzFramesDB.targetToTScale = value
                    if not BBF.checkCombatAndWarn() then
                        BBF.MoveToTFrames()
                    end
                elseif element == "focusToTScale" then
                    BetterBlizzFramesDB.focusToTScale = value
                    if not BBF.checkCombatAndWarn() then
                        BBF.MoveToTFrames()
                    end
                elseif element == "focusToTXPos" then
                    BetterBlizzFramesDB.focusToTXPos = value
                    if not BBF.checkCombatAndWarn() then
                        BBF.MoveToTFrames()
                    end
                elseif element == "focusToTYPos" then
                    BetterBlizzFramesDB.focusToTYPos = value
                    if not BBF.checkCombatAndWarn() then
                        BBF.MoveToTFrames()
                    end
                elseif element == "partyFrameScale" then
                    BetterBlizzFramesDB.partyFrameScale = value
                    BBF.CompactPartyFrameScale()
                elseif element == "partyFrameRangeAlpha" then
                    BetterBlizzFramesDB.partyFrameRangeAlpha = value
                    BBF.HookAndUpdatePartyFrameRangeAlpha(true)
                elseif element == "darkModeColor" then
                    BetterBlizzFramesDB.darkModeColor = value
                    if not BBF.checkCombatAndWarn() then
                        BBF.DarkmodeFrames()
                    end
                elseif element == "lossOfControlScale" then
                    BetterBlizzFramesDB.lossOfControlScale = value
                    BBF.ToggleLossOfControlTestMode()
                    BBF.ChangeLossOfControlScale()
                elseif element == "targetAndFocusAuraOffsetX" then
                    BetterBlizzFramesDB.targetAndFocusAuraOffsetX = value
                    BBF.RefreshAllAuraFrames()
                elseif element == "targetAndFocusAuraOffsetY" then
                    BetterBlizzFramesDB.targetAndFocusAuraOffsetY = value
                    BBF.RefreshAllAuraFrames()
                elseif element == "targetAndFocusAuraScale" then
                    BetterBlizzFramesDB.targetAndFocusAuraScale = value
                    BBF.RefreshAllAuraFrames()
                elseif element == "targetAndFocusHorizontalGap" then
                    BetterBlizzFramesDB.targetAndFocusHorizontalGap = value
                    BBF.RefreshAllAuraFrames()
                elseif element == "targetAndFocusVerticalGap" then
                    BetterBlizzFramesDB.targetAndFocusVerticalGap = value
                    BBF.RefreshAllAuraFrames()
                elseif element == "selfAuraPurgeGlowAlpha" then
                    BetterBlizzFramesDB.selfAuraPurgeGlowAlpha = value
                    BBF.RefreshAllAuraFrames()
                elseif element == "targetAndFocusAurasPerRow" then
                    BetterBlizzFramesDB.targetAndFocusAurasPerRow = value
                    BBF.RefreshAllAuraFrames()
                    --
                elseif element == "combatIndicatorScale" then
                    BetterBlizzFramesDB.combatIndicatorScale = value
                    BBF.CombatIndicatorCaller()
                elseif element == "combatIndicatorXPos" then
                    BetterBlizzFramesDB.combatIndicatorXPos = value
                    BBF.CombatIndicatorCaller()
                elseif element == "combatIndicatorYPos" then
                    BetterBlizzFramesDB.combatIndicatorYPos = value
                    BBF.CombatIndicatorCaller()
                elseif element == "healerIndicatorScale" then
                    BetterBlizzFramesDB.healerIndicatorScale = value
                    BBF.HealerIndicatorCaller()
                elseif element == "healerIndicatorXPos" then
                    BetterBlizzFramesDB.healerIndicatorXPos = value
                    BBF.HealerIndicatorCaller()
                elseif element == "healerIndicatorYPos" then
                    BetterBlizzFramesDB.healerIndicatorYPos = value
                    BBF.HealerIndicatorCaller()
                elseif element == "absorbIndicatorScale" then
                    BetterBlizzFramesDB.absorbIndicatorScale = value
                    BBF.AbsorbCaller()
                elseif element == "playerAbsorbXPos" then
                    BetterBlizzFramesDB.playerAbsorbXPos = value
                    BBF.AbsorbCaller()
                elseif element == "playerAbsorbYPos" then
                    BetterBlizzFramesDB.playerAbsorbYPos = value
                    BBF.AbsorbCaller()
                elseif element == "targetAbsorbXPos" then
                    BetterBlizzFramesDB.targetAbsorbXPos = value
                    BBF.AbsorbCaller()
                elseif element == "targetAbsorbYPos" then
                    BetterBlizzFramesDB.targetAbsorbYPos = value
                    BBF.AbsorbCaller()
                elseif element == "partyCastBarScale" then
                    BetterBlizzFramesDB.partyCastBarScale = value
                    BBF.UpdateCastbars()
                elseif element == "partyCastBarXPos" then
                    BetterBlizzFramesDB.partyCastBarXPos = value
                    BBF.UpdateCastbars()
                elseif element == "partyCastBarYPos" then
                    BetterBlizzFramesDB.partyCastBarYPos = value
                    BBF.UpdateCastbars()
                elseif element == "partyCastbarIconXPos" then
                    BetterBlizzFramesDB.partyCastbarIconXPos = value
                    BBF.UpdateCastbars()
                elseif element == "partyCastbarIconYPos" then
                    BetterBlizzFramesDB.partyCastbarIconYPos = value
                    BBF.UpdateCastbars()
                elseif element == "partyCastBarWidth" then
                    BetterBlizzFramesDB.partyCastBarWidth = value
                    BBF.UpdateCastbars()
                elseif element == "partyCastBarHeight" then
                    BetterBlizzFramesDB.partyCastBarHeight = value
                    BBF.UpdateCastbars()
                elseif element == "partyCastBarIconScale" then
                    BetterBlizzFramesDB.partyCastBarIconScale = value
                    BBF.UpdateCastbars()
                elseif element == "targetCastBarScale" then
                    BetterBlizzFramesDB.targetCastBarScale = value
                    BBF.ChangeCastbarSizes()
                elseif element == "targetCastBarXPos" then
                    BetterBlizzFramesDB.targetCastBarXPos = value
                    BBF.CastbarAdjustCaller()
                elseif element == "targetCastBarYPos" then
                    BetterBlizzFramesDB.targetCastBarYPos = value
                    BBF.CastbarAdjustCaller()
                elseif element == "targetCastBarWidth" then
                    BetterBlizzFramesDB.targetCastBarWidth = value
                    BBF.ChangeCastbarSizes()
                elseif element == "targetCastBarHeight" then
                    BetterBlizzFramesDB.targetCastBarHeight = value
                    BBF.ChangeCastbarSizes()
                elseif element == "targetCastBarIconScale" then
                    BetterBlizzFramesDB.targetCastBarIconScale = value
                    BBF.ChangeCastbarSizes()
                elseif element == "targetCastbarIconXPos" then
                    BetterBlizzFramesDB.targetCastbarIconXPos = value
                    BBF.ChangeCastbarSizes()
                elseif element == "targetCastbarIconYPos" then
                    BetterBlizzFramesDB.targetCastbarIconYPos = value
                    BBF.ChangeCastbarSizes()
                elseif element == "focusCastBarScale" then
                    BetterBlizzFramesDB.focusCastBarScale = value
                    BBF.ChangeCastbarSizes()
                elseif element == "focusCastBarXPos" then
                    BetterBlizzFramesDB.focusCastBarXPos = value
                    BBF.CastbarAdjustCaller()
                elseif element == "focusCastBarYPos" then
                    BetterBlizzFramesDB.focusCastBarYPos = value
                    BBF.CastbarAdjustCaller()
                elseif element == "focusCastBarWidth" then
                    BetterBlizzFramesDB.focusCastBarWidth = value
                    BBF.ChangeCastbarSizes()
                elseif element == "focusCastBarHeight" then
                    BetterBlizzFramesDB.focusCastBarHeight = value
                    BBF.ChangeCastbarSizes()
                elseif element == "focusCastBarIconScale" then
                    BetterBlizzFramesDB.focusCastBarIconScale = value
                    BBF.ChangeCastbarSizes()
                elseif element == "playerCastBarScale" then
                    BetterBlizzFramesDB.playerCastBarScale = value
                    BBF.ChangeCastbarSizes()
                elseif element == "focusCastbarIconXPos" then
                    BetterBlizzFramesDB.focusCastbarIconXPos = value
                    BBF.ChangeCastbarSizes()
                elseif element == "focusCastbarIconYPos" then
                    BetterBlizzFramesDB.focusCastbarIconYPos = value
                    BBF.ChangeCastbarSizes()
                elseif element == "playerCastBarIconScale" then
                    BetterBlizzFramesDB.playerCastBarIconScale = value
                    BBF.ChangeCastbarSizes()
                elseif element == "playerCastbarIconXPos" then
                    BetterBlizzFramesDB.playerCastbarIconXPos = value
                    BBF.ChangeCastbarSizes()
                elseif element == "playerCastbarIconYPos" then
                    BetterBlizzFramesDB.playerCastbarIconYPos = value
                    BBF.ChangeCastbarSizes()
                elseif element == "playerCastBarWidth" then
                    BetterBlizzFramesDB.playerCastBarWidth = value
                    BBF.ChangeCastbarSizes()
                elseif element == "playerCastBarHeight" then
                    BetterBlizzFramesDB.playerCastBarHeight = value
                    BBF.ChangeCastbarSizes()
                elseif element == "maxTargetBuffs" then
                    BetterBlizzFramesDB.maxTargetBuffs = value
                    BBF.RefreshAllAuraFrames()
                elseif element == "maxTargetDebuffs" then
                    BetterBlizzFramesDB.maxTargetDebuffs = value
                    BBF.RefreshAllAuraFrames()
                elseif element == "maxBuffFrameBuffs" then
                    BetterBlizzFramesDB.maxBuffFrameBuffs = value
                    BBF.RefreshAllAuraFrames()
                elseif element == "maxBuffFrameDebuffs" then
                    BetterBlizzFramesDB.maxBuffFrameDebuffs = value
                    BBF.RefreshAllAuraFrames()
                elseif element == "petCastBarScale" then
                    BetterBlizzFramesDB.petCastBarScale = value
                    BBF.UpdatePetCastbar()
                elseif element == "petCastBarXPos" then
                    BetterBlizzFramesDB.petCastBarXPos = value
                    BBF.UpdatePetCastbar()
                elseif element == "petCastBarYPos" then
                    BetterBlizzFramesDB.petCastBarYPos = value
                    BBF.UpdatePetCastbar()
                elseif element == "petCastBarWidth" then
                    BetterBlizzFramesDB.petCastBarWidth = value
                    BBF.UpdatePetCastbar()
                elseif element == "petCastBarHeight" then
                    BetterBlizzFramesDB.petCastBarHeight = value
                    BBF.UpdatePetCastbar()
                elseif element == "petCastBarIconScale" then
                    BetterBlizzFramesDB.petCastBarIconScale = value
                    BBF.UpdatePetCastbar()
                elseif element == "playerAuraMaxBuffsPerRow" then
                    BetterBlizzFramesDB.playerAuraMaxBuffsPerRow = value
                    BBF.RefreshAllAuraFrames()
                elseif element == "playerAuraSpacingX" then
                    BetterBlizzFramesDB.playerAuraSpacingX = value
                    BBF.RefreshAllAuraFrames()
                elseif element == "playerAuraSpacingY" then
                    BetterBlizzFramesDB.playerAuraSpacingY = value
                    BBF.RefreshAllAuraFrames()
                elseif element == "auraTypeGap" then
                    BetterBlizzFramesDB.auraTypeGap = value
                    BBF.RefreshAllAuraFrames()
                elseif element == "auraStackSize" then
                    BetterBlizzFramesDB.auraStackSize = value
                    BBF.RefreshAllAuraFrames()
                elseif element == "auraCdTextSize" then
                    BetterBlizzFramesDB.auraCdTextSize = value
                    BBF.RefreshAllAuraFrames()
                elseif element == "targetAndFocusSmallAuraScale" then
                    BetterBlizzFramesDB.targetAndFocusSmallAuraScale = value
                    BBF.RefreshAllAuraFrames()
                elseif element == "enlargedAuraSize" then
                    BetterBlizzFramesDB.enlargedAuraSize = value
                    BBF.RefreshAllAuraFrames()
                elseif element == "compactedAuraSize" then
                    BetterBlizzFramesDB.compactedAuraSize = value
                    BBF.RefreshAllAuraFrames()
                elseif element == "racialIndicatorScale" then
                    BetterBlizzFramesDB.racialIndicatorScale = value
                    BBF.RacialIndicatorCaller()
                elseif element == "racialIndicatorXPos" then
                    BetterBlizzFramesDB.racialIndicatorXPos = value
                    BBF.RacialIndicatorCaller()
                elseif element == "racialIndicatorYPos" then
                    BetterBlizzFramesDB.racialIndicatorYPos = value
                    BBF.RacialIndicatorCaller()
                elseif element == "targetToTAdjustmentOffsetY" then
                    BetterBlizzFramesDB.targetToTAdjustmentOffsetY = value
                    BBF.CastbarAdjustCaller()
                elseif element == "focusToTAdjustmentOffsetY" then
                    BetterBlizzFramesDB.focusToTAdjustmentOffsetY = value
                    BBF.CastbarAdjustCaller()
                elseif element == "castBarInterruptIconScale" then
                    BetterBlizzFramesDB.castBarInterruptIconScale = value
                    BBF.UpdateInterruptIconSettings()
                elseif element == "castBarInterruptIconXPos" then
                    BetterBlizzFramesDB.castBarInterruptIconXPos = value
                    BBF.UpdateInterruptIconSettings()
                elseif element == "castBarInterruptIconYPos" then
                    BetterBlizzFramesDB.castBarInterruptIconYPos = value
                    BBF.UpdateInterruptIconSettings()
                elseif element == "uiWidgetPowerBarScale" then
                    BetterBlizzFramesDB.uiWidgetPowerBarScale = value
                    BBF.ResizeUIWidgetPowerBarFrame()
                elseif element == playerClassResourceScale then
                    BetterBlizzFramesDB[playerClassResourceScale] = value
                    BBF.UpdateClassComboPoints()
                    --end
                elseif element == "legacyComboScale" or element == "legacyComboXPos" or element == "legacyComboYPos" then
                    BetterBlizzFramesDB[element] = value
                    if BBF.UpdateLegacyComboPosition then
                        BBF.UpdateLegacyComboPosition()
                    end
                end
            end
        end)

    return slider
end

local function CreateTooltip(widget, tooltipText, anchor)
    widget.tooltipTitle = tooltipText
    widget:SetScript("OnEnter", function(self)
        if GameTooltip:IsShown() then
            GameTooltip:Hide()
        end

        if anchor then
            GameTooltip:SetOwner(self, anchor)
        else
            GameTooltip:SetOwner(self, "ANCHOR_RIGHT")
        end
        GameTooltip:SetText(tooltipText)

        GameTooltip:Show()
    end)

    widget:SetScript("OnLeave", function(self)
        GameTooltip:Hide()
    end)
end

local function CreateTooltipTwo(widget, title, mainText, subText, anchor, cvarName, cpuUsage, category)
    widget.tooltipTitle = title
    widget.tooltipMainText = mainText
    widget.tooltipSubText = subText
    widget.tooltipCVarName = cvarName
    widget:SetScript("OnEnter", function(self)
        -- Clear the tooltip before showing new information
        GameTooltip:ClearLines()
        if GameTooltip:IsShown() then
            GameTooltip:Hide()
        end
        if anchor then
            GameTooltip:SetOwner(self, anchor)
        else
            GameTooltip:SetOwner(self, "ANCHOR_RIGHT")
        end
        -- Set the bold title
        GameTooltip:AddLine(title)
        --GameTooltip:AddLine(" ") -- Adding an empty line as a separator
        -- Set the main text
        GameTooltip:AddLine(mainText, 1, 1, 1, true) -- true for wrap text

        if title == L["Format_Numbers"] then
            local tooltipText = "\n\n18800 K |A:glueannouncementpopup-arrow:20:20|a 18.8 M\n|cff32f795" .. L["Right_Click_Show_Extra_Decimal"] .. "|r"
            if BetterBlizzFramesDB.formatStatusBarTextExtraDecimals then
                tooltipText = "\n\n18800 K |A:glueannouncementpopup-arrow:20:20|a 18.80 M\n|cff32f795" .. L["Right_Click_Show_Extra_Decimal"] .. "|r|A:ParagonReputation_Checkmark:15:15|a"
            end
            GameTooltip:AddLine(tooltipText, 1, 1, 1, true)
        end

        if title == L["Tooltip_Class_Color_Healthbars_Title"] then
            local green = "|cff32f795"
            local babyBlue = "|cff7fc6ff"
            local reset = "|r"
            local check = " |A:ParagonReputation_Checkmark:15:15|a"

            local tooltipText = "\n"
            tooltipText = tooltipText .. green .. L["Tooltip_Class_Color_Keep_Player"] .. reset
            if BetterBlizzFramesDB.classColorFramesSkipPlayer then
                tooltipText = tooltipText .. check
            end

            tooltipText = tooltipText .. "\n\n" .. babyBlue .. L["Tooltip_Class_Color_Keep_Friendly"] .. reset
            if BetterBlizzFramesDB.classColorFramesSkipFriendly then
                tooltipText = tooltipText .. check
            end

            GameTooltip:AddLine(tooltipText, 1, 1, 1, true)
        end

        if title == L["Custom_Colors"] then
            local yellow = "|cffffff00"
            local green = "|cff32f795"
            local babyBlue = "|cff7fc6ff"
            local reset = "|r"
            local check = " |A:ParagonReputation_Checkmark:15:15|a"

            local tooltipText = "\n" .. yellow .. L["Right_Click_To_Open_Options"] .. reset
            tooltipText = tooltipText .. "\n\n" .. green .. L["Tooltip_Class_Color_Keep_Player"] .. reset
            if BetterBlizzFramesDB.classColorFramesSkipPlayer then
                tooltipText = tooltipText .. check
            end

            tooltipText = tooltipText .. "\n\n" .. babyBlue .. L["Tooltip_Class_Color_Keep_Friendly"] .. reset
            if BetterBlizzFramesDB.classColorFramesSkipFriendly then
                tooltipText = tooltipText .. check
            end

            GameTooltip:AddLine(tooltipText, 1, 1, 1, true)
        end

        if title == L["Hide_Dispel_Overlay"] then
            local green = "|cff32f795"
            local babyBlue = "|cff7fc6ff"
            local reset = "|r"
            local check = " |A:ParagonReputation_Checkmark:15:15|a"

            local tooltipText = "\n"
            tooltipText = tooltipText .. green .. L["Right_Click_Keep_Dispel_Border"] .. " |A:RaidFrame-DispelHighlight:15:30|a" .. reset
            if BetterBlizzFramesDB.hidePartyDispelOverlayKeepBorder then
                tooltipText = tooltipText .. check
            end

            tooltipText = tooltipText .. "\n\n" .. babyBlue .. L["Shift_Right_Click_Keep_Dispel_Gradient"] .. " |A:_RaidFrame-Dispel-Highlight-Horizontal:15:30|a" .. reset
            if BetterBlizzFramesDB.hidePartyDispelOverlayKeepGradient then
                tooltipText = tooltipText .. check
            end

            GameTooltip:AddLine(tooltipText, 1, 1, 1, true)
        end

        if title == L["Show_Elite_Texture"] then
            local tooltipText = L["Tooltip_Elite_Texture_Dark_Mode"]
            if BetterBlizzFramesDB.playerEliteFrameDarkmode then
                tooltipText = L["Tooltip_Elite_Texture_Dark_Mode_Check"] .. "|A:ParagonReputation_Checkmark:15:15|a"
            end
            GameTooltip:AddLine(tooltipText, 1, 1, 1, true)
        end

        if title == L["Tooltip_Pixel_Border_RaidFrames_Title"] then
            local green = "|cff32f795"
            local reset = "|r"
            local activeSize = BetterBlizzFramesDB.raidFramePixelBorderSize and "1.5px" or "1px"
            local tooltipText = "\n" .. green .. "Right-click to toggle between 1px and 1.5px. Active: " .. activeSize .. reset
            GameTooltip:AddLine(tooltipText, 1, 1, 1, true)
        end

        if title == L["Change_Party_Frame_Alpha"] then
            local green = "|cff32f795"
            local reset = "|r"
            local check = ""
            if BetterBlizzFramesDB.partyFrameRangeAlphaSolidBackground then
                check = " |A:ParagonReputation_Checkmark:15:15|a"
            end
            local tooltipText = "\n" .. green .. L["Tooltip_Party_Frame_Range_Alpha_Solid_Bg"] .. reset .. check
            GameTooltip:AddLine(tooltipText, 1, 1, 1, true)
        end

        -- Set the subtext
        if subText then
            GameTooltip:AddLine("____________________________", 0.8, 0.8, 0.8, true)
            GameTooltip:AddLine(subText, 0.8, 0.80, 0.80, true)
        end
        -- Add CVar information if provided
        if cvarName then
            --GameTooltip:AddLine(" ")
            --GameTooltip:AddLine("Default Value: " .. cvarName, 0.5, 0.5, 0.5) -- grey color for subtext
            GameTooltip:AddDoubleLine(L["Tooltip_Changes_CVar"], cvarName, 0.2, 1, 0.6, 0.2, 1, 0.6)
        end
        if cpuUsage then
            local star = "|A:UI-HUD-UnitFrame-Target-PortraitOn-Boss-Rare-Star:16:16|a"
            local noStar = "|A:UI-HUD-UnitFrame-Target-PortraitOn-Boss-IconRing:16:16|a"

            -- Create star string based on cpuUsage (0-5)
            local starString = ""
            for i = 1, 5 do
                if i <= cpuUsage then
                    starString = starString .. star
                else
                    starString = starString .. noStar
                end
            end
            GameTooltip:AddDoubleLine(" ", " ")
            GameTooltip:AddDoubleLine(L["CPU_Usage"], starString, 0.2, 1, 0.6, 0.2, 1, 0.6)
        end

        if category then
            GameTooltip:AddLine("")
            GameTooltip:AddLine("|A:shop-games-magnifyingglass:17:17|a " .. L["Tooltip_Setting_Located_In"]..category..L["Tooltip_Section"], 0.4, 0.8, 1, true)
        end
        GameTooltip:Show()
    end)
    widget:SetScript("OnLeave", function(self)
        GameTooltip:Hide()
    end)
end

local CLASS_COLORS = {
    ROGUE = "|cfffff569",
    WARRIOR = "|cffc79c6e",
    MAGE = "|cff40c7eb",
    DRUID = "|cffff7d0a",
    HUNTER = "|cffabd473",
    PRIEST = "|cffffffff",
    WARLOCK = "|cff8787ed",
    SHAMAN = "|cff0070de",
    PALADIN = "|cfff58cba",
    DEATHKNIGHT = "|cffc41f3b",
    MONK = "|cff00ff96",
    DEMONHUNTER = "|cffa330c9",
    EVOKER = "|cff33937f",
    STARTER = "|cff32cd32",
    BLITZ = "|cffff8000",
    MYTHIC = "|cff7dd1c2",
}

local CLASS_ICONS = {
    ROGUE = "groupfinder-icon-class-rogue",
    WARRIOR = "groupfinder-icon-class-warrior",
    MAGE = "groupfinder-icon-class-mage",
    DRUID = "groupfinder-icon-class-druid",
    HUNTER = "groupfinder-icon-class-hunter",
    PRIEST = "groupfinder-icon-class-priest",
    WARLOCK = "groupfinder-icon-class-warlock",
    SHAMAN = "groupfinder-icon-class-shaman",
    PALADIN = "groupfinder-icon-class-paladin",
    DEATHKNIGHT = "groupfinder-icon-class-deathknight",
    MONK = "groupfinder-icon-class-monk",
    DEMONHUNTER = "groupfinder-icon-class-demonhunter",
    EVOKER = "groupfinder-icon-class-evoker",
    STARTER = "newplayerchat-chaticon-newcomer",
    BLITZ = "questlog-questtypeicon-pvp",
    MYTHIC = "worldquest-icon-dungeon",
}

local function ShowProfileConfirmation(profileName, class, profileFunction, additionalNote)
    local noteText = additionalNote or ""
    local color = CLASS_COLORS[class] or "|cffffffff"
    local icon = CLASS_ICONS[class] or "groupfinder-icon-role-leader"
    local profileText = string.format("|A:%s:16:16|a %s%s|r", icon, color, profileName..L["Profile_Label"])
    local confirmationText = titleText .. string.format(L["Profile_Confirmation_Text"], profileText, noteText)

    StaticPopupDialogs["BBF_CONFIRM_PROFILE"].text = confirmationText
    StaticPopup_Show("BBF_CONFIRM_PROFILE", nil, nil, { func = profileFunction })
end

local function CreateClassButton(parent, class, name, twitchName, onClickFunc)
    local bbfParent = parent == BetterBlizzFrames
    local btnWidth, btnHeight = bbfParent and 104 or 150, bbfParent and 22 or  30
    local button = CreateFrame("Button", nil, parent, "GameMenuButtonTemplate")
    button:SetSize(btnWidth, btnHeight)

    local dontIncludeProfileText = bbfParent and "" or L["Profile_Label"]
    local color = CLASS_COLORS[class] or "|cffffffff"
    local icon = CLASS_ICONS[class] or "groupfinder-icon-role-leader"

    if name == "Bodify" then
        icon = "gmchat-icon-blizz"
    end

    button:SetText(string.format("|A:%s:16:16|a %s%s|r", icon, color, (name..dontIncludeProfileText)))
    button:SetNormalFontObject("GameFontNormal")
    button:SetHighlightFontObject("GameFontHighlight")
    local a,b,c = button.Text:GetFont()
    button.Text:SetFont(a,b,"OUTLINE")
    -- local a,b,c,d,e = button.Text:GetPoint()
    -- button.Text:SetPoint(a,b,c,d,e-0.5)
    local ttAnchor = "ANCHOR_TOP"

    button:SetScript("OnClick", function()
        if onClickFunc then
            onClickFunc()
        end
    end)

    if class == "STARTER" then
        CreateTooltipTwo(button, string.format("|A:%s:16:16|a %s%s|r", icon, color, name..L["Profile_Label"]), L["Profile_Starter_Desc"], nil, ttAnchor)
    elseif class == "BLITZ" then
        CreateTooltipTwo(button, string.format("|A:%s:16:16|a %s%s|r", icon, color, name..L["Profile_Label"]), L["Profile_Blitz_Desc"], nil, ttAnchor)
    elseif class == "MYTHIC" then
        CreateTooltipTwo(button, string.format("|A:%s:16:16|a %s%s|r", icon, color, name..L["Profile_Label"]), L["Profile_Mythic_Desc"], nil, ttAnchor)
    elseif name == "Bodify" then
        CreateTooltipTwo(button, string.format("|A:%s:16:16|a %s%s|r", icon, color, name..L["Profile_Label"]), L["Profile_Bodify_Desc"], nil, ttAnchor)
    else
        CreateTooltipTwo(button, string.format("|A:%s:16:16|a %s%s|r", icon, color, name..L["Profile_Label"]), string.format(L["Profile_Streamer_Desc"], name), string.format("www.twitch.tv/%s", twitchName), ttAnchor)
    end

    return button
end

local function CreateImportExportUI(parent, title, dataTable, posX, posY, tableName)
    -- Frame to hold all import/export elements
    local frame = CreateFrame("Frame", nil, parent, "BackdropTemplate")
    frame:SetSize(210, 65) -- Adjust size as needed
    frame:SetPoint("TOPLEFT", parent, "TOPLEFT", posX, posY)
    
    -- Setting the backdrop
    frame:SetBackdrop({
        bgFile = "Interface\\ChatFrame\\ChatFrameBackground", -- More subtle background
        edgeFile = "Interface\\Tooltips\\UI-Tooltip-Border", -- Sleeker border
        tile = false, tileSize = 16, edgeSize = 16,
        insets = { left = 4, right = 4, top = 4, bottom = 4 }
    })
    frame:SetBackdropColor(0, 0, 0, 0.7) -- Semi-transparent black

    -- Title
    local titleText = frame:CreateFontString(nil, "OVERLAY", "GameFontNormalMed2")
    titleText:SetPoint("BOTTOM", frame, "TOP", 0, 0)
    titleText:SetText(title)

    -- Export EditBox
    local exportBox = CreateFrame("EditBox", nil, frame, "InputBoxTemplate")
    exportBox:SetSize(100, 20)
    exportBox:SetPoint("TOPRIGHT", frame, "TOPRIGHT", -15, -10)
    exportBox:SetAutoFocus(false)
    CreateTooltipTwo(exportBox, L["Tooltip_Ctrl_C_Copy"])

    -- Import EditBox
    local importBox = CreateFrame("EditBox", nil, frame, "InputBoxTemplate")
    importBox:SetSize(100, 20)
    importBox:SetPoint("TOP", exportBox, "BOTTOM", 0, -5)
    importBox:SetAutoFocus(false)

    -- Export Button
    local exportBtn = CreateFrame("Button", nil, frame, "GameMenuButtonTemplate")
    exportBtn:SetPoint("RIGHT", exportBox, "LEFT", -10, 0)
    exportBtn:SetSize(73, 20)
    exportBtn:SetText(L["Export"])
    exportBtn:SetNormalFontObject("GameFontNormal")
    exportBtn:SetHighlightFontObject("GameFontHighlight")
    CreateTooltipTwo(exportBtn, L["Tooltip_Export_Data"], L["Tooltip_Export_Data_Desc"])

    -- Import Button
    local importBtn = CreateFrame("Button", nil, frame, "GameMenuButtonTemplate")
    importBtn:SetPoint("RIGHT", importBox, "LEFT", -10, 0)
    importBtn:SetSize(title ~= "Full Profile" and 52 or 73, 20)
    importBtn:SetText(L["Import"])
    importBtn:SetNormalFontObject("GameFontNormal")
    importBtn:SetHighlightFontObject("GameFontHighlight")
    CreateTooltipTwo(importBtn, L["Tooltip_Import_Data"], L["Tooltip_Import_Data_Desc"])

    -- Keep Old Checkbox
    local keepOldCheckbox
    if title ~= "Full Profile" then
        keepOldCheckbox = CreateFrame("CheckButton", nil, frame, "InterfaceOptionsCheckButtonTemplate")
        keepOldCheckbox:SetPoint("RIGHT", importBtn, "LEFT", 3, -1)
        keepOldCheckbox:SetChecked(true)
        CreateTooltipTwo(keepOldCheckbox, L["Tooltip_Keep_Old_Data"], L["Tooltip_Keep_Old_Data_Desc"])
    end

    -- Button scripts
    exportBtn:SetScript("OnClick", function()
        local exportString = BBF.ExportProfile(dataTable, tableName)
        exportBox:SetText(exportString)
        exportBox:SetFocus()
        exportBox:HighlightText()
    end)

    local wipeButton = exportBox:CreateTexture(nil, "OVERLAY")
    wipeButton:SetSize(14,14)
    wipeButton:SetPoint("CENTER", exportBox, "TOPRIGHT", 8,6)
    wipeButton:SetAtlas("transmog-icon-remove")
    wipeButton:Hide()

    wipeButton:SetScript("OnMouseDown", function(self, button)
        if button == "RightButton" and IsShiftKeyDown() and IsAltKeyDown() then
            if title == "Full Profile" then
                BetterBlizzFramesDB = nil
            else
                BetterBlizzFramesDB[tableName] = nil
            end
            ReloadUI()
        end
    end)

    local function HideWipeButton()
        if not wipeButton:IsMouseOver() then
            wipeButton:Hide()
        end
    end

    frame:HookScript("OnEnter", function()
        wipeButton:Show()
        C_Timer.After(4, HideWipeButton)
    end)
    CreateTooltipTwo(wipeButton, L["Tooltip_Delete_Data_Title"]..title, L["Tooltip_Delete_Data_Desc"].." "..title)

    wipeButton:HookScript("OnEnter", function()
        wipeButton:Show()
    end)

    wipeButton:HookScript("OnLeave", function()
        C_Timer.After(0.5, HideWipeButton)
    end)


    importBtn:SetScript("OnClick", function()
        local importString = importBox:GetText()
        local profileData, errorMessage = BBF.OldImportProfile(importString, tableName)
        if errorMessage then
            BBF.Print(L["Print_Error_Importing"] .. title .. ": " .. tostring(errorMessage))
        else
            if not profileData then
                BBF.Print(L["Print_Error_Importing_Generic"])
                return
            end
            if keepOldCheckbox and keepOldCheckbox:GetChecked() then
                -- Perform a deep merge if "Keep Old" is checked
                BBF.DeepMergeTables(dataTable, profileData)
            else
                -- Replace existing data with imported data
                for k in pairs(dataTable) do dataTable[k] = nil end -- Clear current table
                for k, v in pairs(profileData) do
                    dataTable[k] = v -- Populate with new data
                end
            end
            BBF.Print(string.format(L["Print_Imported_Successfully"], title))
            StaticPopup_Show("BBF_CONFIRM_RELOAD")
        end
    end)
    return frame
end

local function CreateAnchorDropdown(name, parent, defaultText, settingKey, toggleFunc, point)
    -- Create the dropdown frame using the library's creation function
    local dropdown = LibDD:Create_UIDropDownMenu(name, parent)
    LibDD:UIDropDownMenu_SetWidth(dropdown, 125)

    -- Function to get the display text based on the setting value
    local function getDisplayTextForSetting(settingValue)
        if name == "combatIndicatorDropdown" or name == "playerAbsorbAnchorDropdown" then
            if settingValue == "LEFT" then
                return L["Anchor_INNER"]
            elseif settingValue == "RIGHT" then
                return L["Anchor_OUTER"]
            end
        end
        if settingValue == "TOP" then
            return L["Anchor_TOP"]
        elseif settingValue == "BOTTOM" then
            return L["Anchor_BOTTOM"]
        elseif settingValue == "CENTER" then
            return L["Anchor_CENTER"]
        elseif settingValue == "LEFT" then
            return L["Anchor_LEFT"]
        elseif settingValue == "RIGHT" then
            return L["Anchor_RIGHT"]
        end
        return settingValue
    end

    -- Set the initial dropdown text
    LibDD:UIDropDownMenu_SetText(dropdown, getDisplayTextForSetting(BetterBlizzFramesDB[settingKey]) or defaultText)

    local anchorPointsToUse = anchorPoints
    if name == "combatIndicatorDropdown" or name == "playerAbsorbAnchorDropdown" then
        anchorPointsToUse = anchorPoints2
    end

    -- Initialize the dropdown using the library's initialize function
    LibDD:UIDropDownMenu_Initialize(dropdown, function(self, level, menuList)
        local info = LibDD:UIDropDownMenu_CreateInfo()
        for _, anchor in ipairs(anchorPointsToUse) do
            local displayText = anchor

            -- Customize display text for specific dropdowns
            if anchor == "TOP" then
                displayText = L["Anchor_TOP"]
            elseif anchor == "BOTTOM" then
                displayText = L["Anchor_BOTTOM"]
            elseif anchor == "CENTER" then
                displayText = L["Anchor_CENTER"]
            elseif anchor == "LEFT" then
                if name == "combatIndicatorDropdown" or name == "playerAbsorbAnchorDropdown" then
                    displayText = L["Anchor_INNER"]
                else
                    displayText = L["Anchor_LEFT"]
                end
            elseif anchor == "RIGHT" then
                if name == "combatIndicatorDropdown" or name == "playerAbsorbAnchorDropdown" then
                    displayText = L["Anchor_OUTER"]
                else
                    displayText = L["Anchor_RIGHT"]
                end
            end

            info.text = displayText
            info.arg1 = anchor
            info.func = function(self, arg1)
                if BetterBlizzFramesDB[settingKey] ~= arg1 then
                    BetterBlizzFramesDB[settingKey] = arg1
                    LibDD:UIDropDownMenu_SetText(dropdown, getDisplayTextForSetting(arg1))
                    toggleFunc(arg1)
                    BBF.MoveToTFrames()
                end
            end
            info.checked = (BetterBlizzFramesDB[settingKey] == anchor)
            LibDD:UIDropDownMenu_AddButton(info)
        end
    end)

    -- Position the dropdown
    dropdown:SetPoint("TOPLEFT", point.anchorFrame, "TOPLEFT", point.x, point.y)

    -- Create and set up the label
    local dropdownText = parent:CreateFontString(nil, "OVERLAY", "GameFontNormal")
    dropdownText:SetPoint("BOTTOM", dropdown, "TOP", 0, 3)
    dropdownText:SetText(point.label)

    -- Enable or disable the dropdown based on the parent's check state
    if parent:GetObjectType() == "CheckButton" and parent:GetChecked() == false then
        LibDD:UIDropDownMenu_DisableDropDown(dropdown)
    else
        LibDD:UIDropDownMenu_EnableDropDown(dropdown)
    end

    return dropdown
end

local function CreateCheckbox(option, label, parent, cvarName, extraFunc)
    local checkBox = CreateFrame("CheckButton", nil, parent, "InterfaceOptionsCheckButtonTemplate")
    checkBox.Text:SetText(label)
    checkBox:SetSize(23,23)
    checkBox.Text:SetFont(fontSmall, 12)

    local category
    if parent.name then
        category = parent.name
    elseif parent:GetParent() and parent:GetParent().name then
        category = parent:GetParent().name
    elseif parent:GetParent() and parent:GetParent():GetParent() and parent:GetParent():GetParent().name then
        category = parent:GetParent():GetParent().name
    end

    if category == "Better|cff00c0ffBlizz|rFrames |A:gmchat-icon-blizz:16:16|a" then
        category = L["Search_Name_General"]
    end

    checkBox.searchCategory = category


    table.insert(checkBoxList, {checkbox = checkBox, label = label})

    local function UpdateOption(value)
        if option == 'friendlyFrameClickthrough' and BBF.checkCombatAndWarn() then
            return
        end

        local function SetChecked()
            if BetterBlizzFramesDB.hasCheckedUi then
                BetterBlizzFramesDB[option] = value
                checkBox:SetChecked(value)
            else
                C_Timer.After(0.1, function()
                    SetChecked()
                end)
            end
        end
        SetChecked()

        local grandparent = parent:GetParent()

        if parent:GetObjectType() == "CheckButton" and (parent:GetChecked() == false or (grandparent:GetObjectType() == "CheckButton" and grandparent:GetChecked() == false)) then
            checkBox:Disable()
            checkBox:SetAlpha(0.5)
        else
            checkBox:Enable()
            checkBox:SetAlpha(1)
        end

        if extraFunc and not BetterBlizzFramesDB.wasOnLoadingScreen and BetterBlizzFrames.guiLoaded then
            extraFunc(option, value)
        end

        if not BetterBlizzFramesDB.wasOnLoadingScreen then
            BBF.UpdateUserTargetSettings()
        end

        if not BetterBlizzFramesDB.wasOnLoadingScreen and BetterBlizzFramesDB.playerAuraFiltering then
            BBF.RefreshAllAuraFrames()
        end
        --BBF.Print("Checkbox option '" .. option .. "' changed to:", value)
    end

    UpdateOption(BetterBlizzFramesDB[option])

    checkBox:HookScript("OnClick", function(_, _, _)
        UpdateOption(checkBox:GetChecked())
    end)

    return checkBox
end




local function deleteEntry(listName, key)
    if not key then return end

    local entry = BetterBlizzFramesDB[listName][key]

    if not entry then
        if key == "example aura :3 (delete me)" then
            entry = BetterBlizzFramesDB[listName]["example"]
            key = "example"
        end
    end

    if entry then
        if entry.id then
            local spellName, _, icon = BBF.TWWGetSpellInfo(entry.id)
            if spellName and icon then
                local iconString = "|T" .. icon .. ":16:16:0:0|t"
                BBF.Print(string.format(L["Print_Removed_From_List"], iconString .. " " .. spellName .. " (" .. entry.id .. ")"))
            elseif entry.name then
                BBF.Print(string.format(L["Print_Removed_From_List"], entry.name .. " (" .. entry.id .. ")"))
            else
                BBF.Print(string.format(L["Print_Removed_ID_Not_Found"], entry.id))
            end
        else
            BBF.Print(string.format(L["Print_Removed_From_List"], entry.name))
        end

        BetterBlizzFramesDB[listName][key] = nil
    end

    BBF.currentSearchFilter = ""

    if SettingsPanel:IsShown() then
        if BBF[listName.."Refresh"] then
            BBF[listName.."Refresh"]()
        end
    else
        BBF[listName.."DelayedUpdate"] = BBF[listName.."Refresh"]
    end

    BBF.RefreshAllAuraFrames()
end

local lists = { "auraBlacklist", "auraWhitelist" }

for _, listName in ipairs(lists) do
    -- Create static popup dialogs for duplicate confirmations
    StaticPopupDialogs["BBF_DUPLICATE_NPC_CONFIRM_" .. listName] = {
        text = L["Dialog_Duplicate_Entry"],
        button1 = L["Yes"],
        button2 = L["No"],
        OnAccept = function()
            deleteEntry(listName, BBF.entryToDelete)  -- Delete the entry when "Yes" is clicked
        end,
        timeout = 0,
        whileDead = true,
    }

    -- Create static popup dialogs for delete confirmations
    StaticPopupDialogs["BBF_DELETE_NPC_CONFIRM_" .. listName] = {
        text = L["Dialog_Confirm_Delete"],
        button1 = L["Yes"],
        button2 = L["No"],
        OnAccept = function()
            deleteEntry(listName, BBF.entryToDelete)  -- Delete the entry when "Yes" is clicked
        end,
        timeout = 0,
        whileDead = true,
    }
end

StaticPopupDialogs["BBF_DUPLICATE_UPDATE_OR_DELETE"] = {
    text = L["Dialog_Duplicate_Blacklist"],
    button1 = L["Update_And_Always_Hide"],
    button2 = L["Delete_From_Blacklist"],
    OnAccept = function()
        BBF["auraBlacklist"](BBF.entryToDelete, "auraBlacklist", nil, true)  -- Update when accepted
    end,
    OnCancel = function()
        deleteEntry("auraBlacklist", BBF.entryToDelete)  -- Delete the entry when "Yes" is clicked
    end,
    timeout = 0,
    whileDead = true,
}


local function addOrUpdateEntry(inputText, listName, addShowMineTag, skipRefresh, color)
    BBF.entryToDelete = nil
    local name, comment = strsplit("/", inputText, 2)
    name = strtrim(name or "")
    comment = comment and strtrim(comment) or nil
    local id = tonumber(name)
    local printMsg
    local spellName
    local icon
    local iconString
    local _

    -- Check if there's a numeric ID within the name and clear the name if found
    if id then
        spellName, _, icon = BBF.TWWGetSpellInfo(id)
        name = spellName or ""

        if not spellName then
            BBF.Print(string.format(L["Print_No_Spell_Found"], id))
            return
        end

        if icon then
            iconString = "|T" .. icon .. ":16:16:0:0|t"
        else
            iconString = ""
        end

        -- Check if the spell is being added to blacklist or whitelist
        if listName == "auraBlacklist" then
            printMsg = iconString .. " " .. spellName .. " (" .. id .. ")" .. L["Print_Added_To_Blacklist_With_Icon"]
        elseif listName == "auraWhitelist" then
            printMsg = iconString .. " " .. spellName .. " (" .. id .. ")" .. L["Print_Added_To_Whitelist_With_Icon"]
        end
    end

    -- Remove unwanted characters from name and comment individually
    name = gsub(name, "[%/%(%)%[%]]", "")
    if comment then
        comment = gsub(comment, "[%/%(%)%[%]]", "")
    end

    if (name ~= "" or id) then
        local key = id or string.lower(name)  -- Use id if available, otherwise use name
        local isDuplicate = false

        -- Directly check if the key already exists in the list
        if BetterBlizzFramesDB[listName][key] then
            if listName == "auraBlacklist" then
                local hasShowMineTag = BetterBlizzFramesDB[listName][key].showMine
                if addShowMineTag and not hasShowMineTag then
                    -- do nothing, adds tag
                elseif not addShowMineTag and hasShowMineTag then
                    -- do nothing, removes tag
                else
                    isDuplicate = true
                    BBF.entryToDelete = key  -- Use key to identify the duplicate
                    if addShowMineTag then
                        BBF.DuplicateWithTag = true
                    end
                end
            elseif listName == "auraWhitelist" then
                isDuplicate = true
                BBF.entryToDelete = key  -- Use key to identify the duplicate
            end
        end

        if isDuplicate then
            if BBF.DuplicateWithTag then
                StaticPopup_Show("BBF_DUPLICATE_UPDATE_OR_DELETE")
                BBF.DuplicateWithTag = nil
            else
                StaticPopup_Show("BBF_DUPLICATE_NPC_CONFIRM_" .. listName)
            end
        else
            -- Initialize the new entry with appropriate structure
            local newEntry = {
                name = name,
                id = id,
                comment = comment or nil,
            }

            if listName == "auraWhitelist" then
                newEntry = {name = name, id = id, comment = comment or nil, color = {0,1,0,1}}
            end

            -- if color then
            --     --newEntry.color = {1,0.501960813999176,0,1} -- offensive
            --     --newEntry.color = {1,0.6627451181411743,0.9450981020927429,1} -- defensive
            --     newEntry.color = {0,1,1,1} -- mobility
            --     --newEntry.color = {0,1,0,1} --muy importante
            --     newEntry.important = true
            --     newEntry.enlarged = true
            -- end

            -- If adding to auraBlacklist and addShowMineTag is true, set showMine to true
            if addShowMineTag and listName == "auraBlacklist" then
                newEntry.showMine = true
                if id then
                    printMsg = iconString .. " " .. spellName .. " (" .. id .. ")" .. L["Print_Added_To_Blacklist_With_Tag"]
                end
            end

            -- Add the new entry to the list using key
            BetterBlizzFramesDB[listName][key] = newEntry

            -- Update UI: Re-create text line button and refresh the list display
            if BBF["UpdateTextLine"..listName] then
                BBF["UpdateTextLine"..listName](newEntry, #BBF[listName.."TextLines"] + 1, BBF[listName.."ExtraBoxes"])
            end

            BBF.currentSearchFilter = ""

            if not skipRefresh then
                if BBF[listName.."Refresh"] then
                    BBF[listName.."Refresh"]()
                end
            else
                if SettingsPanel:IsShown() then
                    if BBF[listName.."Refresh"] then
                        BBF[listName.."Refresh"]()
                    end
                else
                    BBF[listName.."DelayedUpdate"] = BBF[listName.."Refresh"]
                end
            end

            if printMsg then
                BBF.Print(printMsg)
            end

        end
    end

    BBF.RefreshAllAuraFrames()
    if BBF[listName.."EditBox"] then
        BBF[listName.."EditBox"]:SetText("")  -- Clear the EditBox
    end
end
BBF["auraBlacklist"] = addOrUpdateEntry
BBF["auraWhitelist"] = addOrUpdateEntry







local function CreateList(subPanel, listName, listData, refreshFunc, extraBoxes, colorText, width, pos)
    -- Create the scroll frame
    local scrollFrame = CreateFrame("ScrollFrame", nil, subPanel, "UIPanelScrollFrameTemplate")
    scrollFrame:SetSize(width or 322, 270)
    if not pos then
        scrollFrame:SetPoint("TOPLEFT", 10, -10)
    else
        scrollFrame:SetPoint("TOPLEFT", -48, -10)
    end

    -- Create the content frame
    local contentFrame = CreateFrame("Frame", nil, scrollFrame)
    contentFrame:SetSize(width or 322, 270)
    scrollFrame:SetScrollChild(contentFrame)

    local textLines = {}
    BBF[listName.."TextLines"] = textLines
    BBF[listName.."ExtraBoxes"] = extraBoxes
    local framePool = {}
    BBF.entryToDelete = nil
    BBF.currentSearchFilter = ""

    -- Function to update the background colors of the entries
    local function updateBackgroundColors()
        for i, button in ipairs(textLines) do
            local bg = button.bgImg
            if i % 2 == 0 then
                bg:SetColorTexture(0.3, 0.3, 0.3, 0.1)  -- Dark color for even lines
            else
                bg:SetColorTexture(0.3, 0.3, 0.3, 0.3)  -- Light color for odd lines
            end
        end
    end

    local function createOrUpdateTextLineButton(npc, index, extraBoxes)
        local button

        -- Reuse frame from the pool if available
        if framePool[index] then
            button = framePool[index]
            button:Show()
        else
            -- Create a new frame if pool is exhausted
            button = CreateFrame("Frame", nil, contentFrame)
            button:SetSize((width and width - 12) or (322 - 12), 20)
            button:SetPoint("TOPLEFT", 10, -(index - 1) * 20)

            -- Background
            local bg = button:CreateTexture(nil, "BACKGROUND")
            bg:SetAllPoints()
            button.bgImg = bg  -- Store the background texture for later updates

            -- Icon
            local iconTexture = button:CreateTexture(nil, "OVERLAY")
            iconTexture:SetSize(20, 20)  -- Same height as the button
            iconTexture:SetPoint("LEFT", button, "LEFT", 0, 0)
            button.iconTexture = iconTexture

            -- Text
            local text = button:CreateFontString(nil, "OVERLAY", "GameFontNormal")
            text:SetPoint("LEFT", button, "LEFT", 25, 0)
            button.text = text
            text:SetFont(fontSmall, 13)

            -- Delete Button
            local deleteButton = CreateFrame("Button", nil, button, "UIPanelButtonTemplate")
            deleteButton:SetSize(20, 20)
            deleteButton:SetPoint("RIGHT", button, "RIGHT", 4, 0)
            deleteButton:SetText("X")
            deleteButton:SetScript("OnClick", function()
                if IsShiftKeyDown() then
                    deleteEntry(listName, button.npcData.id or button.npcData.name:lower())
                else
                    BBF.entryToDelete = button.npcData.id or button.npcData.name:lower()
                    StaticPopup_Show("BBF_DELETE_NPC_CONFIRM_" .. listName)
                end
            end)
            button.deleteButton = deleteButton

            -- Save button to the pool
            framePool[index] = button
        end

        -- Update button's content
        button.npcData = npc
        local displayText
        if npc.id then
            displayText = string.format("%s (%d)", (npc.name or C_Spell.GetSpellName(npc.id) or "Name Missing"), npc.id)  -- Display as "Name (id)"
        else
            displayText = npc.name  -- Display just the name if there's no id
        end
        button.text:SetText(displayText)
        button.iconTexture:SetTexture(C_Spell.GetSpellTexture(npc.id or npc.name))

        -- Function to set text color
        local function SetTextColor(r, g, b, a)
            if colorText and button.checkBoxI and button.checkBoxI:GetChecked() then
                button.text:SetTextColor(r or 1, g or 1, b or 0, a or 1)
            else
                button.text:SetTextColor(1, 1, 0, 1)
            end
        end

        -- Function to set important box color
        local function SetImportantBoxColor(r, g, b, a)
            if button.checkBoxI then
                if button.checkBoxI:GetChecked() then
                    button.checkBoxI.texture:SetVertexColor(r or 0, g or 1, b or 0, a or 1)
                else
                    button.checkBoxI.texture:SetVertexColor(0, 1, 0, 1)
                end
            end
        end

        -- Initialize colors based on npc data
        local entryColors = npc.color or {1, 0.8196, 0, 1}  -- Default yellowish color 
        

        -- Extra logic for handling additional checkboxes and flags
        if extraBoxes then
            -- CheckBox for Pandemic
            if not button.checkBoxP then
                local checkBoxP = CreateFrame("CheckButton", nil, button, "UICheckButtonTemplate")
                checkBoxP:SetSize(24, 24)
                checkBoxP:SetPoint("RIGHT", button.deleteButton, "LEFT", 4, 0)
                checkBoxP:SetScript("OnClick", function(self)
                    button.npcData.pandemic = self:GetChecked() and true or nil
                    BBF.RefreshAllAuraFrames()
                end)
                checkBoxP.texture = checkBoxP:CreateTexture(nil, "ARTWORK", nil, 1)
                checkBoxP.texture:SetAtlas("newplayertutorial-drag-slotgreen")
                checkBoxP.texture:SetDesaturated(true)
                checkBoxP.texture:SetVertexColor(1, 0, 0)
                checkBoxP.texture:SetSize(27, 27)
                checkBoxP.texture:SetPoint("CENTER", checkBoxP, "CENTER", -0.5, 0.5)
                button.checkBoxP = checkBoxP
                local isWarlock = playerClass == "WARLOCK"
                local extraText = isWarlock and L["Tooltip_Pandemic_Glow_Warlock_Extra"] or ""
                CreateTooltipTwo(checkBoxP, L["Pandemic_Glow_Icon"], L["Tooltip_Pandemic_Glow"]..extraText, L["Tooltip_Pandemic_Extra"], "ANCHOR_TOPRIGHT")
            end
            button.checkBoxP:SetChecked(button.npcData.pandemic)
    
            -- CheckBox for Important with color picker
            if not button.checkBoxI then
                local checkBoxI = CreateFrame("CheckButton", nil, button, "UICheckButtonTemplate")
                checkBoxI:SetSize(24, 24)
                checkBoxI:SetPoint("RIGHT", button.checkBoxP, "LEFT", 4, 0)
                checkBoxI:SetScript("OnClick", function(self)
                    button.npcData.important = self:GetChecked() and true or nil
                    BBF.RefreshAllAuraFrames()
                    SetImportantBoxColor(button.npcData.color[1], button.npcData.color[2], button.npcData.color[3], button.npcData.color[4])
                    SetTextColor(button.npcData.color[1], button.npcData.color[2], button.npcData.color[3], button.npcData.color[4])
                end)
                checkBoxI.texture = checkBoxI:CreateTexture(nil, "ARTWORK", nil, 1)
                checkBoxI.texture:SetAtlas("newplayertutorial-drag-slotgreen")
                checkBoxI.texture:SetSize(27, 27)
                checkBoxI.texture:SetDesaturated(true)
                checkBoxI.texture:SetPoint("CENTER", checkBoxI, "CENTER", -0.5, 0.5)
                button.checkBoxI = checkBoxI
                CreateTooltipTwo(checkBoxI, L["Important_Glow_Icon"], L["Tooltip_Important_Glow"], L["Tooltip_Important_Extra"], "ANCHOR_TOPRIGHT")
            end
            button.checkBoxI:SetChecked(button.npcData.important)
    
            -- Color picker logic
            local function OpenColorPicker(isAll)
                BBF.needsUpdate = true

                -- one-time hook for OK/Cancel to run bulk recolor
                if isAll and not BBF._allColorHook then
                    BBF._allColorHook = true
                    local okBtn     = ColorPickerFrame.Footer and ColorPickerFrame.Footer.OkayButton
                    local cancelBtn = ColorPickerFrame.Footer and ColorPickerFrame.Footer.CancelButton
                    if okBtn then
                        okBtn:HookScript("OnClick", function()
                            if BBF._allColorActive and BBF._allColorPending then
                                local p = BBF._allColorPending
                                RecolorEntireAuraWhitelist(p.r, p.g, p.b, p.a)
                            end
                            BBF._allColorActive  = false
                            BBF._allColorPending = nil
                        end)
                    end
                    if cancelBtn then
                        cancelBtn:HookScript("OnClick", function()
                            BBF._allColorActive  = false
                            BBF._allColorPending = nil
                        end)
                    end
                end

                BBF._allColorActive  = isAll or false
                BBF._allColorPending = nil

                -- set OK button label
                local okBtn = ColorPickerFrame.Footer and ColorPickerFrame.Footer.OkayButton
                if okBtn then
                    if not BBF._colorPickerOkText then
                        BBF._colorPickerOkText = okBtn:GetText()
                    end
                    okBtn:SetText(isAll and L["Color_ALL_Auras"] or BBF._colorPickerOkText)
                end

                -- entryColors is the per-row array table (entry.color). Ensure table exists.
                entryColors = entryColors or {}
                if type(entryColors) ~= "table" then entryColors = {} end
                local r = entryColors[1] or 1
                local g = entryColors[2] or 1
                local b = entryColors[3] or 1
                local a = entryColors[4] or 1
                local backup = { r = r, g = g, b = b, a = a }

                local function updateRowPreview()
                    entryColors[1], entryColors[2], entryColors[3], entryColors[4] = r, g, b, a
                    SetTextColor(r, g, b, a)
                    SetImportantBoxColor(r, g, b, a)
                    BBF.RefreshAllAuraFrames()
                    if ColorPickerFrame.Content and ColorPickerFrame.Content.ColorSwatchCurrent then
                        ColorPickerFrame.Content.ColorSwatchCurrent:SetAlpha(a)
                    end
                    BBF.auraListNeedsUpdate = true
                    if isAll then BBF._allColorPending = { r = r, g = g, b = b, a = a } end
                end

                local function swatchFunc()
                    r, g, b = ColorPickerFrame:GetColorRGB()
                    updateRowPreview()
                end

                local function opacityFunc()
                    a = ColorPickerFrame:GetColorAlpha()
                    updateRowPreview()
                end

                local function cancelFunc()
                    r, g, b, a = backup.r, backup.g, backup.b, backup.a
                    updateRowPreview()
                    BBF._allColorActive  = false
                    BBF._allColorPending = nil
                end

                ColorPickerFrame.previousValues = { r = r, g = g, b = b, a = a }
                ColorPickerFrame:SetupColorPickerAndShow({
                    r = r, g = g, b = b, opacity = a, hasOpacity = true,
                    swatchFunc = swatchFunc, opacityFunc = opacityFunc, cancelFunc = cancelFunc
                })

                updateRowPreview()
            end

            button.checkBoxI:SetScript("OnMouseDown", function(self, button)
                if button ~= "RightButton" then return end
                local isAll = IsControlKeyDown() and IsAltKeyDown()
                OpenColorPicker(isAll)
            end)

            -- CheckBox for Compacted
            if not button.checkBoxC then
                local checkBoxC = CreateFrame("CheckButton", nil, button, "UICheckButtonTemplate")
                checkBoxC:SetSize(24, 24)
                checkBoxC:SetPoint("RIGHT", button.checkBoxI, "LEFT", 3, 0)
                button.checkBoxC = checkBoxC
                CreateTooltipTwo(checkBoxC, L["Compacted_Aura_Icon"], L["Tooltip_Compacted_Aura"], L["Tooltip_Pandemic_Extra"], "ANCHOR_TOPRIGHT")
            end
            button.checkBoxC:SetChecked(button.npcData.compacted)
    
            -- CheckBox for Enlarged
            if not button.checkBoxE then
                local checkBoxE = CreateFrame("CheckButton", nil, button, "UICheckButtonTemplate")
                checkBoxE:SetSize(24, 24)
                checkBoxE:SetPoint("RIGHT", button.checkBoxC, "LEFT", 3, 0)
                checkBoxE:SetScript("OnClick", function(self)
                    button.npcData.enlarged = self:GetChecked() and true or nil
                    button.checkBoxC:SetChecked(false)
                    button.npcData.compacted = false
                    BBF.RefreshAllAuraFrames()
                end)
                button.checkBoxC:SetScript("OnClick", function(self)
                    button.npcData.compacted = self:GetChecked() and true or nil
                    button.checkBoxE:SetChecked(false)
                    button.npcData.enlarged = false
                    BBF.RefreshAllAuraFrames()
                end)
                CreateTooltipTwo(checkBoxE, L["Enlarged_Aura_Icon"], L["Tooltip_Enlarged_Aura"], L["Tooltip_Pandemic_Extra"], "ANCHOR_TOPRIGHT")
                button.checkBoxE = checkBoxE
            end
            button.checkBoxE:SetChecked(button.npcData.enlarged)
    
            -- CheckBox for "Only Mine"
            if not button.checkBoxOnlyMine then
                local checkBoxOnlyMine = CreateFrame("CheckButton", nil, button, "UICheckButtonTemplate")
                checkBoxOnlyMine:SetSize(24, 24)
                checkBoxOnlyMine:SetPoint("RIGHT", button.checkBoxE, "LEFT", 3, 0)
                checkBoxOnlyMine:SetScript("OnClick", function(self)
                    button.npcData.onlyMine = self:GetChecked() and true or nil
                    BBF.RefreshAllAuraFrames()
                end)
                button.checkBoxOnlyMine = checkBoxOnlyMine
                CreateTooltipTwo(checkBoxOnlyMine, L["Only_My_Aura_Icon"], L["Tooltip_Only_My_Aura"], nil, "ANCHOR_TOPRIGHT")
            end
            button.checkBoxOnlyMine:SetChecked(button.npcData.onlyMine)
        end

        if listName == "auraBlacklist" then
            if not button.checkBoxShowMine then
                -- Create Checkbox Only Mine if not already created
                local checkBoxShowMine = CreateFrame("CheckButton", nil, button, "UICheckButtonTemplate")
                checkBoxShowMine:SetSize(24, 24)
                checkBoxShowMine:SetPoint("RIGHT", button, "RIGHT", -13, 0)
                CreateTooltipTwo(checkBoxShowMine, L["Show_Mine_Icon"] .. " |A:UI-HUD-UnitFrame-Player-Group-FriendOnlineIcon:22:22|a", L["Tooltip_Show_Mine"], nil, "ANCHOR_TOPRIGHT")

                -- Handler for the show mine checkbox
                checkBoxShowMine:SetScript("OnClick", function(self)
                    button.npcData.showMine = self:GetChecked() and true or nil
                    BBF.RefreshAllAuraFrames()
                end)

                -- Adjust text width and settings
                button.text:SetWidth(196)
                button.text:SetWordWrap(false)
                button.text:SetJustifyH("LEFT")

                -- Save the reference to the button
                button.checkBoxShowMine = checkBoxShowMine
            end
            button.checkBoxShowMine:SetChecked(button.npcData.showMine)
        end

        if button.checkBoxI then
            if button.checkBoxI:GetChecked() then
                SetImportantBoxColor(entryColors[1], entryColors[2], entryColors[3], entryColors[4])
                SetTextColor(entryColors[1], entryColors[2], entryColors[3], entryColors[4])
            else
                SetImportantBoxColor(0, 1, 0, 1)
                SetTextColor(1, 0.8196, 0, 1)
            end
        end

        if npc.id and not button.idTip then
            button:SetScript("OnEnter", function(self)
                if not button.npcData.id then return end
                GameTooltip:SetOwner(self, "ANCHOR_LEFT")
                GameTooltip:SetSpellByID(button.npcData.id)
                GameTooltip:AddLine(L["Tooltip_Spell_ID"] .. button.npcData.id, 1, 1, 1)
                GameTooltip:Show()
            end)
            button:SetScript("OnLeave", function(self)
                GameTooltip:Hide()
            end)
            button.idTip = true
        end

        -- Update background colors
        updateBackgroundColors()

        return button
    end
    BBF["UpdateTextLine"..listName] = createOrUpdateTextLineButton

    local editBox = CreateFrame("EditBox", nil, subPanel, "InputBoxTemplate")
    editBox:SetSize((width and width - 62) or (322 - 62), 19)
    editBox:SetPoint("TOP", scrollFrame, "BOTTOM", -15, -5)
    editBox:SetAutoFocus(false)
    BBF[listName.."EditBox"] = editBox
    CreateTooltipTwo(editBox, L["Filter_Auras"], L["Tooltip_Filter_Auras"], nil, "ANCHOR_TOP")

    local function cleanUpEntry(entry)
        -- Iterate through each field in the entry
        for key, value in pairs(entry) do
            if value == false then
                entry[key] = nil
            end
        end
    end

    local function getSortedNpcList()
        local sortableNpcList = {}

        -- Iterate over the structure using pairs to access all entries
        for key, entry in pairs(listData) do
            cleanUpEntry(entry)
            -- Apply the search filter
            if BBF.currentSearchFilter == "" or (entry.name and entry.name:lower():match(BBF.currentSearchFilter)) or (entry.id and tostring(entry.id):match(BBF.currentSearchFilter)) then
                table.insert(sortableNpcList, entry)
            end
        end

        -- Sort the list alphabetically by the 'name' field, and then by 'id' if the names are the same
        table.sort(sortableNpcList, function(a, b)
            local nameA = a.name and a.name:lower() or ""
            local nameB = b.name and b.name:lower() or ""

            -- First, compare by name
            if nameA ~= nameB then
                return nameA < nameB
            end

            -- If names are the same, compare by id (sort low to high)
            local idA = a.id or math.huge
            local idB = b.id or math.huge
            return idA < idB
        end)

        return sortableNpcList
    end

    -- Function to update the list with batching logic
    local function refreshList()
        if true then return end
        local sortedListData = getSortedNpcList()
        local totalEntries = #sortedListData
        local batchSize = 35  -- Number of entries to process per frame
        local currentIndex = 1

        local function processNextBatch()
            for i = currentIndex, math.min(currentIndex + batchSize - 1, totalEntries) do
                local npc = sortedListData[i]
                local button = createOrUpdateTextLineButton(npc, i, extraBoxes)
                textLines[i] = button
            end

            -- Hide any extra frames
            for i = totalEntries + 1, #framePool do
                if framePool[i] then
                    framePool[i]:Hide()
                end
            end

            -- Update the content frame height
            contentFrame:SetHeight(totalEntries * 20)
            updateBackgroundColors()

            -- Continue processing if there are more entries
            currentIndex = currentIndex + batchSize
            if currentIndex <= totalEntries then
                C_Timer.After(0.04, processNextBatch)  -- Defer to the next frame
            end
        end
        -- Start processing in the first frame
        processNextBatch()
    end

    contentFrame.refreshList = refreshList
    refreshList()
    --BBF[listName.."DelayedUpdate"] = refreshList
    BBF[listName.."Refresh"] = refreshList
    --BBF.auraWhitelist & BBF.auraBlacklist

    editBox:SetScript("OnEnterPressed", function(self)
        addOrUpdateEntry(self:GetText(), listName)
    end)

        -- Function to search and filter the list
        local function searchList(searchText)
            BBF.currentSearchFilter = searchText:lower()
            refreshList()
        end

        -- Update the list as the user types
        editBox:SetScript("OnTextChanged", function(self, userInput)
            if userInput then
                searchList(self:GetText())
            end
        end, true)

    local addButton = CreateFrame("Button", nil, subPanel, "UIPanelButtonTemplate")
    addButton:SetSize(60, 24)
    addButton:SetText(L["Add"])
    addButton:SetPoint("LEFT", editBox, "RIGHT", 10, 0)
    addButton:SetScript("OnClick", function()
        addOrUpdateEntry(editBox:GetText(), listName)
    end)
    scrollFrame:HookScript("OnShow", function()
        if BBF.auraWhitelistDelayedUpdate then
            BBF.auraWhitelistDelayedUpdate()
            BBF.auraWhitelistDelayedUpdate = nil
        end
        if BBF.auraBlacklistDelayedUpdate then
            BBF.auraBlacklistDelayedUpdate()
            BBF.auraBlacklistDelayedUpdate = nil
        end
    end)
    return scrollFrame
end

SettingsPanel:HookScript("OnShow", function()
    if BBF.auraWhitelistDelayedUpdate then
        BBF.auraWhitelistDelayedUpdate()
        BBF.auraWhitelistDelayedUpdate = nil
    end
    if BBF.auraBlacklistDelayedUpdate then
        BBF.auraBlacklistDelayedUpdate()
        BBF.auraBlacklistDelayedUpdate = nil
    end
end)

local function CreateCDManagerList(parent)
    local scrollFrame = CreateFrame("ScrollFrame", nil, parent, "UIPanelScrollFrameTemplate")
    local width, height = 450, 510
    scrollFrame:SetSize(width, height)
    scrollFrame:SetPoint("TOPLEFT", 185, -14)

    local content = CreateFrame("Frame", nil, scrollFrame)
    content:SetSize(width, height)
    scrollFrame:SetScrollChild(content)

    local spellText = parent:CreateFontString(nil, "OVERLAY", "GameFontNormalLarge")
    spellText:SetPoint("BOTTOMLEFT", scrollFrame, "TOPLEFT", 10, 3)
    spellText:SetText(L["Spell"])

    local priorityText = parent:CreateFontString(nil, "OVERLAY", "GameFontNormalLarge")
    priorityText:SetPoint("BOTTOMLEFT", scrollFrame, "TOP", 95, 3)
    priorityText:SetText(L["Priority"])

    local blacklistIcon = parent:CreateTexture(nil, "OVERLAY")
    blacklistIcon:SetAtlas("lootroll-toast-icon-pass-up")
    blacklistIcon:SetPoint("BOTTOM", scrollFrame, "TOPRIGHT", -29, 1)
    blacklistIcon:SetSize(22, 22)
    CreateTooltip(blacklistIcon, L["Tooltip_Hide_Spell_Icon"] .. " |A:lootroll-toast-icon-pass-up:22:22|a")

    local framePool = {}

    local function refreshList()
        local baseSpells = {}
        local blacklist = BetterBlizzFramesDB.cdManagerBlacklist or {}
        local priorityList = BetterBlizzFramesDB.cdManagerPriorityList or {}

        for _, id in ipairs(BBF.cooldownManagerSpells or {}) do
            baseSpells[id] = true
        end

        local fullList = {}
        for _, id in ipairs(BBF.cooldownManagerSpells or {}) do table.insert(fullList, id) end
        for idStr, _ in pairs(blacklist) do
            local id = tonumber(idStr)
            if id and not baseSpells[id] then
                table.insert(fullList, id)
            end
        end
        for idStr, _ in pairs(priorityList) do
            local id = tonumber(idStr)
            if id and not baseSpells[id] then
                table.insert(fullList, id)
            end
        end

        for i, button in ipairs(framePool) do button:Hide() end

        for i, spellID in ipairs(fullList) do
            local info = C_Spell.GetSpellInfo(spellID)
            if info then
                local name = info.name
                local icon = info.iconID or info.originalIconID
                local isCustom = not baseSpells[spellID]

                local button = framePool[i]
                if not button then
                    button = CreateFrame("Frame", nil, content)
                    button:SetSize(width - 12, 20)
                    button:SetPoint("TOPLEFT", 10, -(i - 1) * 20)

                    local bg = button:CreateTexture(nil, "BACKGROUND")
                    bg:SetAllPoints()
                    button.bg = bg

                    local iconTex = button:CreateTexture(nil, "ARTWORK")
                    iconTex:SetSize(20, 20)
                    iconTex:SetPoint("LEFT")
                    button.iconTex = iconTex

                    local label = button:CreateFontString(nil, "OVERLAY", "GameFontNormal")
                    label:SetPoint("LEFT", iconTex, "RIGHT", 5, 0)
                    button.label = label

                    local checkbox = CreateFrame("CheckButton", nil, button, "UICheckButtonTemplate")
                    checkbox:SetSize(24, 24)
                    checkbox:SetPoint("RIGHT", button, "RIGHT", -15, 0)
                    CreateTooltipTwo(checkbox, L["Hide_Spell_Icon"], L["Tooltip_Hide_Spell_Icon_CD"], nil, "ANCHOR_TOPRIGHT")
                    button.checkbox = checkbox

                    local slider = CreateFrame("Slider", nil, button, "OptionsSliderTemplate")
                    slider:SetSize(80, 16)
                    slider:SetPoint("RIGHT", checkbox, "LEFT", -20, 0)
                    slider:SetMinMaxValues(0, 20)
                    slider:SetValueStep(1)
                    slider:SetObeyStepOnDrag(true)
                    slider.Low:SetText("")
                    slider.High:SetText("")
                    CreateTooltipTwo(slider, L["Priority_Value"], L["Tooltip_Priority"], nil, "ANCHOR_TOPRIGHT")
                    button.slider = slider

                    local text = slider:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
                    text:SetPoint("RIGHT", slider, "LEFT", -5, 0)
                    button.sliderText = text

                    local del = CreateFrame("Button", nil, button, "UIPanelButtonTemplate")
                    del:SetSize(18, 18)
                    del:SetText("X")
                    del:SetPoint("RIGHT", button, "RIGHT", 0, 0)
                    button.del = del
                    CreateTooltipTwo(del, L["Delete"], L["Tooltip_Delete"])

                    framePool[i] = button
                end

                button.iconTex:SetTexture(icon)
                button.label:SetText(name .. " (" .. spellID .. ")")

                local isBlacklisted = BetterBlizzFramesDB.cdManagerBlacklist[spellID]
                local priority = BetterBlizzFramesDB.cdManagerPriorityList[spellID]

                button.checkbox:SetChecked(isBlacklisted or false)
                if isBlacklisted then
                    button.slider:Disable()
                    button.slider:SetAlpha(0.3)
                else
                    button.slider:Enable()
                    button.slider:SetAlpha(1)
                end

                local value = priority or 0
                button.slider:SetValue(value)
                button.sliderText:SetText(value)
                if value == 0 then
                    button.slider:SetAlpha(0.3)
                else
                    button.slider:SetAlpha(1)
                end

                button.checkbox:SetScript("OnClick", function(self)
                    if self:GetChecked() then
                        BetterBlizzFramesDB.cdManagerBlacklist[spellID] = true
                        BetterBlizzFramesDB.cdManagerPriorityList[spellID] = nil
                    else
                        BetterBlizzFramesDB.cdManagerBlacklist[spellID] = false
                    end
                    refreshList()
                    BBF.ResetCooldownManagerIcons()
                    BBF.RefreshCooldownManagerIcons()
                end)

                button.slider:SetScript("OnValueChanged", function(self, value)
                    local v = math.floor(value + 0.5)
                    self:SetValue(v)
                    button.sliderText:SetText(v)

                    if v == 0 then
                        BetterBlizzFramesDB.cdManagerPriorityList[spellID] = nil
                        self:SetAlpha(0.3)
                    else
                        BetterBlizzFramesDB.cdManagerPriorityList[spellID] = v
                        self:SetAlpha(1)
                    end

                    BBF.RefreshCooldownManagerIcons()
                end)

                if isCustom then
                    button.del:SetScript("OnClick", function()
                        BetterBlizzFramesDB.cdManagerBlacklist[spellID] = nil
                        BetterBlizzFramesDB.cdManagerPriorityList[spellID] = nil
                        refreshList()
                        BBF.RefreshCooldownManagerIcons()
                    end)
                    button.del:Show()
                else
                    button.del:Hide()
                end

                button.bg:SetColorTexture(0.2, 0.2, 0.2, i % 2 == 0 and 0.1 or 0.3)
                button:Show()
            end
        end

        local input = CreateFrame("EditBox", nil, parent, "InputBoxTemplate")
        input:SetSize(width-50, 20)
        input:SetPoint("TOPLEFT", scrollFrame, "BOTTOMLEFT", 15, -8)
        input:SetAutoFocus(false)
        CreateTooltipTwo(input, L["Enter_Spell_ID"], L["Tooltip_Enter_Spell"], L["Tooltip_Enter_Spell_Note"], "ANCHOR_TOP")

        function BBF.AddCDManagerSpellEntry(inputText, refreshList)
            if not inputText or inputText == "" then return end

            local id = tonumber(inputText)
            local info = C_Spell.GetSpellInfo(id or inputText)

            if info and info.spellID then
                local spellID = info.spellID
                if not BetterBlizzFramesDB.cdManagerPriorityList[spellID] and not BetterBlizzFramesDB.cdManagerBlacklist[spellID] then
                    BetterBlizzFramesDB.cdManagerBlacklist[spellID] = false
                    refreshList()
                    BBF.RefreshCooldownManagerIcons()
                end
            elseif not id then -- if it's not a number and didn't resolve to a spell, treat it as a raw name
                if not BetterBlizzFramesDB.cdManagerPriorityList[inputText] and not BetterBlizzFramesDB.cdManagerBlacklist[inputText] then
                    BetterBlizzFramesDB.cdManagerBlacklist[inputText] = false
                    refreshList()
                    BBF.RefreshCooldownManagerIcons()
                end
            else
                BBF.Print(string.format(L["Print_Invalid_Spell_ID"], inputText))
            end
        end

        input:SetScript("OnEnterPressed", function(self)
            BBF.AddCDManagerSpellEntry(self:GetText(), refreshList)
            self:SetText("")
        end)

        local add = CreateFrame("Button", nil, parent, "UIPanelButtonTemplate")
        add:SetSize(50, 22)
        add:SetText(L["Add"])
        add:SetPoint("LEFT", input, "RIGHT", 6, 0)

        add:SetScript("OnClick", function()
            BBF.AddCDManagerSpellEntry(input:GetText(), refreshList)
            input:SetText("")
        end)

        content:SetHeight(#fullList * 22)
    end

    scrollFrame:HookScript("OnShow", function()
        if BBF.cdManagerNeedsUpdate then
            refreshList()
        end
    end)

    scrollFrame.Refresh = refreshList
    BBF.RefreshCdManagerList = refreshList
    BBF.cdManagerScrollFrame = scrollFrame

    refreshList()
    return scrollFrame
end



local function CreateTitle(parent)
    local mainGuiAnchor = parent:CreateFontString(nil, "OVERLAY", "GameFontNormal")
    mainGuiAnchor:SetPoint("TOPLEFT", 15, -15)
    mainGuiAnchor:SetText(" ")
    local addonNameText = parent:CreateFontString(nil, "OVERLAY", "GameFontNormalLarge")
    addonNameText:SetPoint("TOPLEFT", mainGuiAnchor, "TOPLEFT", -20, 47)
    addonNameText:SetText("BetterBlizzFrames")
    local addonNameIcon = parent:CreateTexture(nil, "ARTWORK")
    addonNameIcon:SetAtlas("gmchat-icon-blizz")
    addonNameIcon:SetSize(22, 22)
    addonNameIcon:SetPoint("LEFT", addonNameText, "RIGHT", -2, -1)
    local verNumber = parent:CreateFontString(nil, "OVERLAY", "GameFontNormal")
    verNumber:SetPoint("LEFT", addonNameText, "RIGHT", 25, 0)
    verNumber:SetText(BBF.VersionNumber)
end

local function CreateSearchFrame()
    local searchFrame = CreateFrame("Frame", "BBFSearchFrame", UIParent)
    searchFrame:SetSize(680, 610)
    searchFrame:SetPoint("CENTER", UIParent, "CENTER")
    searchFrame:SetFrameStrata("HIGH")
    searchFrame:Hide()

    local wipText = searchFrame:CreateFontString(nil, "OVERLAY", "GameFontNormalLarge")
    wipText:SetPoint("BOTTOM", searchFrame, "BOTTOM", -10, 10)
    wipText:SetText(L["Search_WIP"])

    CreateTitle(searchFrame)

    local bgImg = searchFrame:CreateTexture(nil, "BACKGROUND")
    bgImg:SetAtlas("professions-recipe-background")
    bgImg:SetPoint("CENTER", searchFrame, "CENTER", -8, 4)
    bgImg:SetSize(680, 610)
    bgImg:SetAlpha(0.4)
    bgImg:SetVertexColor(0, 0, 0)

    local settingsText = searchFrame:CreateFontString(nil, "OVERLAY", "GameFontNormalLarge")
    settingsText:SetPoint("TOPLEFT", searchFrame, "TOPLEFT", 20, 0)
    settingsText:SetText(L["Search_Results"])

    -- Icon next to the title
    local searchIcon = searchFrame:CreateTexture(nil, "ARTWORK")
    searchIcon:SetAtlas("communities-icon-searchmagnifyingglass")
    searchIcon:SetSize(28, 28)
    searchIcon:SetPoint("RIGHT", settingsText, "LEFT", -3, -1)

    -- Reference the existing SettingsPanel.SearchBox to copy properties
    local referenceBox = SettingsPanel.SearchBox

    -- Create the search input field on top of SettingsPanel.SearchBox
    local searchBox = CreateFrame("EditBox", nil, SettingsPanel, "InputBoxTemplate")
    searchBox:SetSize(referenceBox:GetWidth() + 1, referenceBox:GetHeight() + 1)
    searchBox:SetPoint("CENTER", referenceBox, "CENTER")
    searchBox:SetFrameStrata("HIGH")
    searchBox:SetAutoFocus(false)
    searchBox.Left:Hide()
    searchBox.Right:Hide()
    searchBox.Middle:Hide()
    searchBox:SetFontObject(referenceBox:GetFontObject())
    searchBox:SetTextInsets(16, 8, 0, 0)
    searchBox:Hide()
    searchBox:SetScript("OnEnterPressed", function(self)
        self:ClearFocus()
    end)
    CreateTooltipTwo(searchBox, L["Search"], L["Tooltip_Search_Desc"], nil, "TOP")

    local resultsList = CreateFrame("Frame", nil, searchFrame)
    resultsList:SetSize(640, 500)
    resultsList:SetPoint("TOP", settingsText, "BOTTOM", 0, -10)

    local checkboxPool = {}
    local sliderPool = {}

    local function SearchElements(query)
        for _, child in ipairs({resultsList:GetChildren()}) do
            child:Hide()
        end

        if query == "" then
            return
        end

        -- Convert the query into lowercase and split it into individual words
        query = string.lower(query)
        local queryWords = { strsplit(" ", query) }

        local checkboxCount = 0
        local sliderCount = 0
        local yOffsetCheckbox = -20  -- Starting position for the first checkbox
        local yOffsetSlider = -20    -- Starting position for the first slider

        -- Helper function to check if all query words are in the label
        local function matchesQuery(label)
            label = string.lower(label)
            for _, queryWord in ipairs(queryWords) do
                if not string.find(label, queryWord) then
                    return false
                end
            end
            return true
        end

        local function applyRightClickScript(searchCheckbox, originalCheckbox)
            local originalScript = originalCheckbox:GetScript("OnMouseDown")
            if originalScript then
                searchCheckbox:SetScript("OnMouseDown", function(self, button)
                    if button == "RightButton" then
                        originalScript(originalCheckbox, button)
                    end
                end)
            end
        end

        -- Search through checkboxes
        for _, data in ipairs(checkBoxList) do
            if checkboxCount >= 20 then break end

            -- Prepare the label and tooltip text
            local label = string.lower(data.label or "")
            local tooltipTitle = string.lower(data.checkbox.tooltipTitle or "")
            local tooltipMainText = string.lower(data.checkbox.tooltipMainText or "")
            local tooltipSubText = string.lower(data.checkbox.tooltipSubText or "")
            local tooltipCVarName = string.lower(data.checkbox.tooltipCVarName or "")

            -- Check if all query words are found in any of the searchable fields
            if matchesQuery(label) or matchesQuery(tooltipTitle) or matchesQuery(tooltipMainText) or matchesQuery(tooltipSubText) or matchesQuery(tooltipCVarName) then
                checkboxCount = checkboxCount + 1

                -- Re-use or create a new checkbox from the pool
                local resultCheckBox = checkboxPool[checkboxCount]
                if not resultCheckBox then
                    resultCheckBox = CreateFrame("CheckButton", nil, resultsList, "InterfaceOptionsCheckButtonTemplate")
                    resultCheckBox:SetSize(23, 23)
                    resultCheckBox.Text:SetFont(fontSmall, 12)
                    checkboxPool[checkboxCount] = resultCheckBox
                end

                -- Update checkbox properties and position
                resultCheckBox:ClearAllPoints()
                resultCheckBox:SetPoint("TOPLEFT", searchIcon, "TOPLEFT", 27, yOffsetCheckbox)
                resultCheckBox.Text:SetText(data.label)
                if not data.label or data.label == "" then
                    resultCheckBox.Text:SetText(data.checkbox.tooltipTitle)
                end
                resultCheckBox:SetChecked(data.checkbox:GetChecked())

                -- Link the result checkbox to the main checkbox
                resultCheckBox:SetScript("OnClick", function()
                    data.checkbox:Click()
                end)

                applyRightClickScript(resultCheckBox, data.checkbox)

                -- Reapply tooltip
                if data.checkbox.tooltipMainText then
                    CreateTooltipTwo(resultCheckBox, data.checkbox.tooltipTitle, data.checkbox.tooltipMainText, data.checkbox.tooltipSubText, nil, data.checkbox.tooltipCVarName, nil, data.checkbox.searchCategory)
                elseif data.checkbox.tooltipTitle then
                    CreateTooltipTwo(resultCheckBox, data.checkbox.tooltipTitle, nil, nil, nil, nil, nil, data.checkbox.searchCategory)
                else
                    CreateTooltipTwo(resultCheckBox, L["No_data_yet_WIP"], nil, nil, nil, nil, nil, data.checkbox.searchCategory)
                end

                resultCheckBox:Show()

                -- Move down for the next checkbox
                yOffsetCheckbox = yOffsetCheckbox - 24
            end
        end

        -- Search through sliders
        for _, data in ipairs(sliderList) do
            if sliderCount >= 13 then break end

            -- Prepare the label and tooltip text
            local label = string.lower(data.label or "")
            local tooltipTitle = string.lower(data.slider.tooltipTitle or "")
            local tooltipMainText = string.lower(data.slider.tooltipMainText or "")
            local tooltipSubText = string.lower(data.slider.tooltipSubText or "")
            local tooltipCVarName = string.lower(data.slider.tooltipCVarName or "")

            -- Check if all query words are found in any of the searchable fields
            if matchesQuery(label) or matchesQuery(tooltipTitle) or matchesQuery(tooltipMainText) or matchesQuery(tooltipSubText) or matchesQuery(tooltipCVarName) then
                sliderCount = sliderCount + 1

                -- Re-use or create a new slider from the slider pool
                local resultSlider = sliderPool[sliderCount]
                if not resultSlider then
                    resultSlider = CreateFrame("Slider", nil, resultsList, "OptionsSliderTemplate")
                    resultSlider:SetOrientation('HORIZONTAL')
                    resultSlider:SetValueStep(data.slider:GetValueStep())
                    resultSlider:SetObeyStepOnDrag(true)
                    resultSlider.Text = resultSlider:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
                    resultSlider.Text:SetTextColor(1, 0.81, 0, 1)
                    resultSlider.Text:SetFont(fontSmall, 11)
                    resultSlider.Text:SetPoint("TOP", resultSlider, "BOTTOM", 0, -1)
                    resultSlider.Low:SetText(" ")
                    resultSlider.High:SetText(" ")
                    sliderPool[sliderCount] = resultSlider
                end

                -- Format the slider text value
                local function formatSliderValue(value)
                    return value % 1 == 0 and tostring(math.floor(value)) or string.format("%.2f", value)
                end

                -- Update slider properties and position
                resultSlider:ClearAllPoints()
                resultSlider:SetPoint("TOPLEFT", searchIcon, "TOPLEFT", 277, yOffsetSlider)
                resultSlider:SetScript("OnValueChanged", nil)
                resultSlider:SetMinMaxValues(data.slider:GetMinMaxValues())
                resultSlider:SetValue(data.slider:GetValue())
                resultSlider.Text:SetText(data.label .. ": " .. formatSliderValue(data.slider:GetValue()))

                resultSlider:SetScript("OnValueChanged", function(self, value)
                    data.slider:SetValue(value) -- Trigger the original slider's script
                    resultSlider.Text:SetText(data.label .. ": " .. formatSliderValue(value))
                end)

                -- Tooltip setup for sliders
                if data.slider.tooltipMainText then
                    CreateTooltipTwo(resultSlider, data.slider.tooltipTitle, data.slider.tooltipMainText, data.slider.tooltipSubText, nil, data.slider.tooltipCVarName, nil, data.slider.searchCategory)
                elseif data.slider.tooltipTitle then
                    CreateTooltipTwo(resultSlider, data.slider.tooltipTitle, nil, nil, nil, nil, nil, data.slider.searchCategory)
                else
                    CreateTooltipTwo(resultSlider, L["No_data_yet_WIP"], nil, nil, nil, nil, nil, data.slider.searchCategory)
                end

                -- Show the slider and prepare for the next slider
                resultSlider:Show()
                yOffsetSlider = yOffsetSlider - 42
            end
        end
    end

    searchBox:SetScript("OnTextChanged", function(self)
        local query = self:GetText()
        if #query > 0 then
            SettingsPanelSearchIcon:SetVertexColor(1, 1, 1)
            SettingsPanel.SearchBox.Instructions:SetAlpha(0)
            searchFrame:Show()
            if SettingsPanel.currentLayout and SettingsPanel.currentLayout.frame then
                SettingsPanel.currentLayout.frame:Hide()
            end
        else
            SettingsPanelSearchIcon:SetVertexColor(0.6, 0.6, 0.6)
            SettingsPanel.SearchBox.Instructions:SetAlpha(1)
            searchFrame:Hide()
            if SettingsPanel.currentLayout and SettingsPanel.currentLayout.frame then
                SettingsPanel.currentLayout.frame:Show()
            end
        end
        if #query >= 1 then
            SearchElements(query)
        else
            SearchElements("")
        end

        if not searchBox.hookedSettings then
            SettingsPanel:HookScript("OnHide", function()
                SettingsPanelSearchIcon:SetVertexColor(0.6, 0.6, 0.6)
                SettingsPanel.SearchBox.Instructions:SetAlpha(1)
                searchFrame:Hide()
                searchBox:Hide()
                if SettingsPanel.currentLayout and SettingsPanel.currentLayout.frame then
                    searchBox:SetText("")
                    SettingsPanel.currentLayout.frame:Show()
                end
            end)
            searchBox.hookedSettings = true
        end
    end)

    hooksecurefunc(SettingsPanel, "DisplayLayout", function()
        if SettingsPanel.currentLayout.frame and SettingsPanel.currentLayout.frame.name == "Better|cff00c0ffBlizz|rFrames |A:gmchat-icon-blizz:16:16|a" or
        (SettingsPanel.currentLayout.frame and SettingsPanel.currentLayout.frame.parent == "Better|cff00c0ffBlizz|rFrames |A:gmchat-icon-blizz:16:16|a") then
            SettingsPanel.SearchBox.Instructions:SetText(L["Search_In_BBF"])
            searchBox:Show()
            searchBox:SetText("")
            searchFrame:Hide()
            searchFrame:ClearAllPoints()
            searchFrame:SetPoint("TOPLEFT", SettingsPanel.currentLayout.frame, "TOPLEFT")
            searchFrame:SetPoint("BOTTOMRIGHT", SettingsPanel.currentLayout.frame, "BOTTOMRIGHT")
            if not SettingsPanel.currentLayout.frame:IsShown() then
                SettingsPanel.currentLayout.frame:Show()
            end
        else
            if SettingsPanel.SearchBox.Instructions:GetText() == L["Search_In_BBF"] then
                SettingsPanel.SearchBox.Instructions:SetText(L["Search"])
            end
            searchBox:Hide()
            searchFrame:Hide()
        end
    end)
end

------------------------------------------------------------
-- GUI Panels
------------------------------------------------------------
local function guiProfiles()
    local parent = SettingsPanel
    local frame = CreateFrame("Frame", nil, BetterBlizzFrames, "SettingsFrameTemplate")
    frame.titleText = frame:CreateFontString(nil, "OVERLAY", "GameFontNormal")
    frame.titleText:SetPoint("TOP", frame, "TOP", 1, -4)
    frame.titleText:SetText("|A:gmchat-icon-blizz:16:16|a BBF")

    frame.descriptionText = frame:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
    frame.descriptionText:SetPoint("TOP", frame, "TOP", 2, -26)
    frame.descriptionText:SetText(L["Profile_Description"])
    frame.descriptionText:SetWidth(100)

    frame.coreText = frame:CreateFontString(nil, "OVERLAY", "GameFontNormal")
    frame.coreText:SetPoint("TOP", frame.descriptionText, "BOTTOM", 0, -10)
    frame.coreText:SetText(L["Profile_Core"])

    frame.streamerText = frame:CreateFontString(nil, "OVERLAY", "GameFontNormal")
    frame.streamerText:SetPoint("TOP", frame.coreText, "BOTTOM", 0, -60)
    frame.streamerText:SetText(L["Profile_Streamers"])

    frame.infoText = frame:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
    frame.infoText:SetPoint("BOTTOM", frame, "BOTTOM", 2, 200)
    frame.infoText:SetText(L["Profile_Info_Message"])
    frame.infoText:SetWidth(100)

    frame:SetSize(130, parent:GetHeight())
    frame:SetPoint("TOPRIGHT", parent, "TOPLEFT", 7, 0)
    frame:SetFrameStrata("BACKGROUND")
    frame.ClosePanelButton:Hide()

    local function CopyNineSliceColors(fromFrame, toFrame)
        if not (fromFrame and toFrame and fromFrame.NineSlice and toFrame.NineSlice) then
            return
        end

        local parts = {
            "TopLeftCorner", "TopRightCorner",
            "BottomLeftCorner", "BottomRightCorner",
            "TopEdge", "BottomEdge",
            "LeftEdge", "RightEdge",
            "Center",
        }

        for _, name in ipairs(parts) do
            local src = fromFrame.NineSlice[name]
            local dst = toFrame.NineSlice[name]
            if src and dst and src.GetVertexColor and dst.SetVertexColor then
                local r, g, b, a = src:GetVertexColor()
                dst:SetVertexColor(r, g, b, a)

                if src.IsDesaturated and dst.SetDesaturated then
                    dst:SetDesaturated(src:IsDesaturated())
                end
            end
        end
    end

    CopyNineSliceColors(SettingsPanel, frame)

    BetterBlizzFrames.profilesFrame = frame
    return frame
end

local function guiGeneralTab()
    ----------------------
    -- Main panel:
    ----------------------
    local mainGuiAnchor = BetterBlizzFrames:CreateFontString(nil, "OVERLAY", "GameFontNormal")
    mainGuiAnchor:SetPoint("TOPLEFT", 15, -15)
    mainGuiAnchor:SetText(" ")

    BetterBlizzFrames.searchName = L["Search_Name_General"]

    local profilesFrame = guiProfiles()

    local bgImg = BetterBlizzFrames:CreateTexture(nil, "BACKGROUND")
    bgImg:SetAtlas("professions-recipe-background")
    bgImg:SetPoint("CENTER", BetterBlizzFrames, "CENTER", -8, 4)
    bgImg:SetSize(680, 610)
    bgImg:SetAlpha(0.4)
    bgImg:SetVertexColor(0,0,0)

    local midnightBeta = BetterBlizzFrames:CreateFontString(nil, "BACKGROUND", "GameFontNormal")
    midnightBeta:SetPoint("BOTTOM", SettingsPanel, "TOP", 0, 0)
    midnightBeta:SetText(L["Msg_Midnight_Early_Beta"])
    midnightBeta:SetFont("Fonts\\FRIZQT__.TTF", 24, "THINOUTLINE")
    midnightBeta:Hide()
    BetterBlizzFrames:HookScript("OnShow",function()
        midnightBeta:Show()
    end)
    BetterBlizzFrames:HookScript("OnHide",function()
        midnightBeta:Hide()
    end)

    local newSearch = BetterBlizzFrames:CreateTexture(nil, "BACKGROUND")
    newSearch:SetAtlas("NewCharacter-Horde", true)
    newSearch:SetPoint("BOTTOM", BetterBlizzFrames, "TOP", -70, 2)
    CreateTooltipTwo(newSearch, L["Search"], L["Tooltip_Search_Desc"])

    local newSearchPoint = BetterBlizzFrames:CreateTexture(nil, "BACKGROUND")
    newSearchPoint:SetAtlas("auctionhouse-icon-buyallarrow", true)
    newSearchPoint:SetPoint("LEFT", newSearch, "RIGHT", -25, 0)
    newSearchPoint:SetRotation(math.pi / 2)

    CreateSearchFrame()
    -- local addonNameText = BetterBlizzFrames:CreateFontString(nil, "OVERLAY", "GameFontNormalLarge")
    -- addonNameText:SetPoint("TOPLEFT", mainGuiAnchor, "TOPLEFT", -20, 47)
    -- addonNameText:SetText("BetterBlizzFrames"])
    -- local addonNameIcon = BetterBlizzFrames:CreateTexture(nil, "ARTWORK")
    -- addonNameIcon:SetAtlas("gmchat-icon-blizz")
    -- addonNameIcon:SetSize(22, 22)
    -- addonNameIcon:SetPoint("LEFT", addonNameText, "RIGHT", -2, -1)
    -- local verNumber = BetterBlizzFrames:CreateFontString(nil, "OVERLAY", "GameFontNormal")
    -- verNumber:SetPoint("LEFT", addonNameText, "RIGHT", 25, 0)
    -- verNumber:SetText(BBF.VersionNumber)
    CreateTitle(BetterBlizzFrames)

    ----------------------
    -- General:
    ----------------------
    -- "General:" text
    local settingsText = BetterBlizzFrames:CreateFontString(nil, "OVERLAY", "GameFontNormal")
    settingsText:SetPoint("TOPLEFT", mainGuiAnchor, "BOTTOMLEFT", 0, 30)
    settingsText:SetText(L["General_Settings"])
    settingsText:SetFont(fontLarge, 16)
    settingsText:SetTextColor(1,1,1)
    local generalSettingsIcon = BetterBlizzFrames:CreateTexture(nil, "ARTWORK")
    generalSettingsIcon:SetAtlas("optionsicon-brown")
    generalSettingsIcon:SetSize(22, 22)
    generalSettingsIcon:SetPoint("RIGHT", settingsText, "LEFT", -3, -1)


    if BetterBlizzFrames.titleText then
        BetterBlizzFrames.titleText:Hide()
        BetterBlizzFrames.loadGUI:Hide()
    end



    local hideArenaFrames = CreateCheckbox("hideArenaFrames", L["Hide_Arena_Frames"], BetterBlizzFrames, nil, BBF.HideArenaFrames)
    hideArenaFrames:SetPoint("TOPLEFT", settingsText, "BOTTOMLEFT", -24, pixelsOnFirstBox)
    hideArenaFrames:HookScript("OnClick", function(self)
        if not self:GetChecked() then
            StaticPopup_Show("BBF_CONFIRM_RELOAD")
        end
    end)
    CreateTooltip(hideArenaFrames, L["Tooltip_Hide_Arena_Frames"])

    local hideBossFrames = CreateCheckbox("hideBossFrames", L["Hide_Boss_Frames"], BetterBlizzFrames, nil, BBF.HideArenaFrames)
    hideBossFrames:SetPoint("TOPLEFT", hideArenaFrames, "BOTTOMLEFT", 0, pixelsBetweenBoxes)
    CreateTooltip(hideBossFrames, L["Tooltip_Hide_Boss_Frames"])

    local hideBossFramesParty = CreateCheckbox("hideBossFramesParty", L["Party"], BetterBlizzFrames, nil, BBF.HideArenaFrames)
    hideBossFramesParty:SetPoint("LEFT", hideBossFrames.text, "RIGHT", 0, 0)
    CreateTooltip(hideBossFramesParty, L["Tooltip_Hide_Boss_Frames_Party"], "ANCHOR_LEFT")

    local hideBossFramesRaid = CreateCheckbox("hideBossFramesRaid", L["Raid"], BetterBlizzFrames, nil, BBF.HideArenaFrames)
    hideBossFramesRaid:SetPoint("LEFT", hideBossFramesParty.text, "RIGHT", 0, 0)
    CreateTooltip(hideBossFramesRaid, L["Tooltip_Hide_Boss_Frames_Raid"], "ANCHOR_LEFT")

    hideBossFrames:HookScript("OnClick", function(self)
        if self:GetChecked() then
            BetterBlizzFramesDB.overShieldsCompact = true
            BetterBlizzFramesDB.hideBossFramesParty = true
            hideBossFramesParty:SetAlpha(1)
            hideBossFramesParty:Enable()
            hideBossFramesParty:SetChecked(true)
            hideBossFramesRaid:SetAlpha(1)
            hideBossFramesRaid:Enable()
            hideBossFramesRaid:SetChecked(true)
        else
            BetterBlizzFramesDB.overShieldsCompact = false
            BetterBlizzFramesDB.hideBossFramesParty = false
            hideBossFramesParty:SetAlpha(0)
            hideBossFramesParty:Disable()
            hideBossFramesParty:SetChecked(false)
            hideBossFramesRaid:SetAlpha(0)
            hideBossFramesRaid:Disable()
            hideBossFramesRaid:SetChecked(false)
            StaticPopup_Show("BBF_CONFIRM_RELOAD")
        end
    end)

    if not BetterBlizzFramesDB.hideBossFrames then
        hideBossFramesParty:SetAlpha(0)
        hideBossFramesParty:Disable()
        hideBossFramesRaid:SetAlpha(0)
        hideBossFramesRaid:Disable()
    end

    local playerFrameOCD = CreateCheckbox("playerFrameOCD", L["OCD_Tweaks"], BetterBlizzFrames, nil, BBF.FixStupidBlizzPTRShit)
    playerFrameOCD:SetPoint("TOPLEFT", hideBossFrames, "BOTTOMLEFT", 0, pixelsBetweenBoxes)
    CreateTooltip(playerFrameOCD, L["Tooltip_OCD_Tweaks_Retail"])

    -- local playerFrameOCDTextureBypass = CreateCheckbox("playerFrameOCDTextureBypass", L["OCD_Skip_Bars"], BetterBlizzFrames, nil, BBF.HideFrames)
    -- playerFrameOCDTextureBypass:SetPoint("LEFT", playerFrameOCD.text, "RIGHT", 0, 0)
    -- CreateTooltip(playerFrameOCDTextureBypass, L["Tooltip_OCD_Skip_Bars"])

    playerFrameOCD:HookScript("OnClick", function(self)
        BBF.AllNameChanges()
        StaticPopup_Show("BBF_CONFIRM_RELOAD")
    end)

    -- if not BetterBlizzFramesDB.playerFrameOCD then
    --     playerFrameOCDTextureBypass:Disable()
    --     playerFrameOCDTextureBypass:SetAlpha(0)
    -- end

    local hideLossOfControlFrameBg = CreateCheckbox("hideLossOfControlFrameBg", L["Hide_CC_Background"], BetterBlizzFrames, nil, BBF.HideFrames)
    hideLossOfControlFrameBg:SetPoint("TOPLEFT", playerFrameOCD, "BOTTOMLEFT", 0, pixelsBetweenBoxes)
    CreateTooltip(hideLossOfControlFrameBg, L["Tooltip_Hide_CC_Background"])
    hideLossOfControlFrameBg:HookScript("OnClick", function()
        BBF.ToggleLossOfControlTestMode()
    end)

    local hideLossOfControlFrameLines = CreateCheckbox("hideLossOfControlFrameLines", L["Hide_CC_Red_Lines"], BetterBlizzFrames, nil, BBF.HideFrames)
    hideLossOfControlFrameLines:SetPoint("TOPLEFT", hideLossOfControlFrameBg, "BOTTOMLEFT", 0, pixelsBetweenBoxes)
    CreateTooltip(hideLossOfControlFrameLines, L["Tooltip_Hide_CC_Red_Lines"])
    hideLossOfControlFrameLines:HookScript("OnClick", function()
        BBF.ToggleLossOfControlTestMode()
    end)

    local lossOfControlScale = CreateSlider(BetterBlizzFrames, L["CC_Scale"], 0.4, 1.4, 0.01, "lossOfControlScale", nil, 90)
    lossOfControlScale:SetPoint("LEFT", hideLossOfControlFrameBg.text, "RIGHT", 3, -16)
    CreateTooltipTwo(lossOfControlScale, L["Loss_of_Control_Scale"], L["Tooltip_LossOfControlScale_Desc"])

    local darkModeUi = CreateCheckbox("darkModeUi", L["Dark_Mode"], BetterBlizzFrames)
    darkModeUi:SetPoint("TOPLEFT", hideLossOfControlFrameLines, "BOTTOMLEFT", 0, pixelsBetweenBoxes)
    darkModeUi:HookScript("OnClick", function()
        BBF.DarkmodeFrames(true)
    end)
    CreateTooltip(darkModeUi, L["Tooltip_Dark_Mode"])

    local darkModeActionBars = CreateCheckbox("darkModeActionBars", L["ActionBars"], darkModeUi)
    darkModeActionBars:SetPoint("TOPLEFT", darkModeUi, "BOTTOMLEFT", 0, pixelsBetweenBoxes)
    darkModeActionBars:HookScript("OnClick", function()
        BBF.DarkmodeFrames(true)
    end)
    CreateTooltip(darkModeActionBars, L["Tooltip_Dark_Mode_ActionBars"])

    local darkModeMinimap = CreateCheckbox("darkModeMinimap", L["Minimap"], darkModeUi)
    darkModeMinimap:SetPoint("TOPLEFT", darkModeActionBars, "BOTTOMLEFT", 0, pixelsBetweenBoxes)
    darkModeMinimap:HookScript("OnClick", function()
        BBF.DarkmodeFrames(true)
    end)
    CreateTooltip(darkModeMinimap, L["Dark_Mode_Minimap"])

    local darkModeCastbars = CreateCheckbox("darkModeCastbars", L["Castbars"], darkModeUi)
    darkModeCastbars:SetPoint("LEFT", darkModeUi.Text, "RIGHT", 5, 0)
    darkModeCastbars:HookScript("OnClick", function()
        BBF.DarkmodeFrames(true)
    end)
    CreateTooltip(darkModeCastbars, L["Tooltip_Dark_Mode_Castbars"])

    local darkModeUiAura = CreateCheckbox("darkModeUiAura", L["Auras"], darkModeUi)
    darkModeUiAura:SetPoint("TOPLEFT", darkModeCastbars, "BOTTOMLEFT", 0, pixelsBetweenBoxes)
    darkModeUiAura:HookScript("OnClick", function()
        StaticPopup_Show("BBF_CONFIRM_RELOAD")
        BBF.DarkmodeFrames(true)
    end)
    CreateTooltip(darkModeUiAura, L["Tooltip_Dark_Mode_Auras"])

    local darkModeNameplateResource = CreateCheckbox("darkModeNameplateResource", L["Nameplate_Resource"], darkModeUi)
    darkModeNameplateResource:SetPoint("TOPLEFT", darkModeUiAura, "BOTTOMLEFT", 0, pixelsBetweenBoxes)
    darkModeNameplateResource:HookScript("OnClick", function()
        BBF.DarkmodeFrames(true)
    end)
    CreateTooltip(darkModeNameplateResource, L["Dark_Mode_Nameplate_Resource"])

    local darkModeGameTooltip = CreateCheckbox("darkModeGameTooltip", L["Tooltip"], darkModeUi)
    darkModeGameTooltip:SetPoint("TOPLEFT", darkModeMinimap, "BOTTOMLEFT", 0, pixelsBetweenBoxes)
    darkModeGameTooltip:HookScript("OnClick", function()
        BBF.DarkmodeFrames(true)
    end)
    CreateTooltipTwo(darkModeGameTooltip, L["Dark_Mode_Tooltip"], L["Tooltip_Dark_Mode_GameTooltip_Desc"])

    local darkModeEliteTexture = CreateCheckbox("darkModeEliteTexture", L["Elite_Texture"], darkModeUi)
    darkModeEliteTexture:SetPoint("TOPLEFT", darkModeGameTooltip, "BOTTOMLEFT", 0, pixelsBetweenBoxes)
    darkModeEliteTexture:HookScript("OnClick", function()
        BBF.DarkmodeFrames(true)
    end)
    CreateTooltipTwo(darkModeEliteTexture, L["Dark_Mode_Elite_Texture"], L["Tooltip_Dark_Mode_Elite_Texture_Desc"])
    darkModeEliteTexture:HookScript("OnMouseDown", function(self, button)
        if button == "RightButton" then
            if not BetterBlizzFramesDB.darkModeEliteTextureDesaturated then
                BetterBlizzFramesDB.darkModeEliteTextureDesaturated = true
            else
                BetterBlizzFramesDB.darkModeEliteTextureDesaturated = nil
            end
            BBF.DarkmodeFrames(true)
        end
    end)

    local darkModeObjectiveFrame = CreateCheckbox("darkModeObjectiveFrame", L["Objectives"], darkModeUi)
    darkModeObjectiveFrame:SetPoint("LEFT", darkModeGameTooltip.Text, "RIGHT", 5, 0)
    darkModeObjectiveFrame:HookScript("OnClick", function()
        BBF.DarkmodeFrames(true)
    end)
    CreateTooltipTwo(darkModeObjectiveFrame, L["Dark_Mode_Objectives"], L["Tooltip_Dark_Mode_Objectives_Desc"])

    local darkModeVigor = CreateCheckbox("darkModeVigor", L["Vigor"], darkModeUi)
    darkModeVigor:SetPoint("LEFT", darkModeObjectiveFrame.Text, "RIGHT", 5, 0)
    darkModeVigor:HookScript("OnClick", function()
        BBF.DarkmodeFrames(true)
    end)
    CreateTooltipTwo(darkModeVigor, L["Dark_Mode_Vigor"], L["Tooltip_Dark_Mode_Vigor_Desc"])

    local darkModeColor = CreateSlider(darkModeUi, L["Darkness"], 0, 1, 0.01, "darkModeColor", nil, 90)
    darkModeColor:SetPoint("LEFT", darkModeUiAura.text, "RIGHT", 3, -1)
    CreateTooltipTwo(darkModeColor, L["Dark_Mode_Value"], L["Tooltip_Dark_Mode_Value_Desc"])

    darkModeUi:HookScript("OnClick", function(self)
        CheckAndToggleCheckboxes(darkModeUi, 0)
    end)
    if not BetterBlizzFramesDB.darkModeUi then
        CheckAndToggleCheckboxes(darkModeUi, 0)
    end










    local playerFrameText = BetterBlizzFrames:CreateFontString(nil, "OVERLAY", "GameFontNormal")
    playerFrameText:SetPoint("TOPLEFT", mainGuiAnchor, "BOTTOMLEFT", 0, -173)
    playerFrameText:SetText(L["Player_Frame"])
    playerFrameText:SetFont(fontLarge, 16)
    playerFrameText:SetTextColor(1,1,1)
    local playerFrameIcon = BetterBlizzFrames:CreateTexture(nil, "ARTWORK")
    playerFrameIcon:SetAtlas("groupfinder-icon-friend")
    playerFrameIcon:SetSize(28, 28)
    playerFrameIcon:SetPoint("RIGHT", playerFrameText, "LEFT", -0.5, 0)

    local playerFrameClickthrough = CreateCheckbox("playerFrameClickthrough", L["Clickthrough"], BetterBlizzFrames, nil, BBF.ClickthroughFrames)
    playerFrameClickthrough:SetPoint("TOPLEFT", playerFrameText, "BOTTOMLEFT", -24, pixelsOnFirstBox)
    CreateTooltip(playerFrameClickthrough, L["Tooltip_Clickthrough"])
    playerFrameClickthrough:HookScript("OnClick", function(self)
        if not self:GetChecked() then
            StaticPopup_Show("BBF_CONFIRM_RELOAD")
        end
    end)

    local textures = BetterBlizzFramesDB.classicFrames and 7 or 4
    local playerEliteFrame = CreateCheckbox("playerEliteFrame", L["Elite_Texture"], BetterBlizzFrames)
    playerEliteFrame:SetPoint("LEFT", playerFrameClickthrough.text, "RIGHT", 5, 0)
    playerEliteFrame:HookScript("OnClick", function(self)
        BBF.PlayerElite(BetterBlizzFramesDB.playerEliteFrameMode)
    end)
    playerEliteFrame:HookScript("OnMouseDown", function(self, button)
        if button == "RightButton" and IsShiftKeyDown() then
            if not BetterBlizzFramesDB.playerEliteFrameDarkmode then
                BetterBlizzFramesDB.playerEliteFrameDarkmode = true
            else
                BetterBlizzFramesDB.playerEliteFrameDarkmode = nil
            end
            if GameTooltip:IsShown() and GameTooltip:GetOwner() == self then
                self:GetScript("OnEnter")(self)
            end
            BBF.PlayerElite(BetterBlizzFramesDB["playerEliteFrameMode"])
        elseif button == "RightButton" then
            BetterBlizzFramesDB["playerEliteFrameMode"] = BetterBlizzFramesDB["playerEliteFrameMode"] % textures + 1
            BBF.PlayerElite(BetterBlizzFramesDB["playerEliteFrameMode"])
        end
    end)
    CreateTooltipTwo(playerEliteFrame, L["Show_Elite_Texture"], string.format(L["Tooltip_Show_Elite_Texture_Desc"], textures))

    local playerReputationColor = CreateCheckbox("playerReputationColor", L["Add_Reputation_Color"], BetterBlizzFrames, nil, BBF.PlayerReputationColor)
    playerReputationColor:SetPoint("TOPLEFT", playerFrameClickthrough, "BOTTOMLEFT", 0, pixelsBetweenBoxes)
    CreateTooltip(playerReputationColor, L["Tooltip_Add_Reputation_Color"] .. " |A:UI-HUD-UnitFrame-Target-PortraitOn-Type:18:98|a")

    local playerReputationClassColor = CreateCheckbox("playerReputationClassColor", L["Class_Color_Combo"], BetterBlizzFrames, nil, BBF.PlayerReputationColor)
    playerReputationClassColor:SetPoint("LEFT", playerReputationColor.text, "RIGHT", 5, 0)
    CreateTooltip(playerReputationClassColor, L["Tooltip_Class_Color_Reputation"])
    playerReputationColor:HookScript("OnClick", function(self)
        if self:GetChecked() then
            playerReputationClassColor:Enable()
            playerReputationClassColor:SetAlpha(1)
        else
            playerReputationClassColor:Disable()
            playerReputationClassColor:SetAlpha(0)
        end
    end)
    if not BetterBlizzFramesDB.playerReputationColor then
        playerReputationClassColor:SetAlpha(0)
        playerReputationClassColor:Disable()
    end

    local hidePlayerName = CreateCheckbox("hidePlayerName", L["Hide_Names"], BetterBlizzFrames, nil, BBF.UpdateNameSettings)
    hidePlayerName:SetPoint("TOPLEFT", playerReputationColor, "BOTTOMLEFT", 0, pixelsBetweenBoxes)
    hidePlayerName:HookScript("OnClick", function(self)
        -- if self:GetChecked() then
        --     PlayerFrame.name:SetAlpha(0)
        --     if PlayerFrame.bbfName then
        --         PlayerFrame.bbfName:SetAlpha(0)
        --     end
        -- else
        --     PlayerFrame.name:SetAlpha(0)
        --     if PlayerFrame.bbfName then
        --         PlayerFrame.bbfName:SetAlpha(1)
        --     else
        --         PlayerFrame.name:SetAlpha(1)
        --     end
        -- end
        BBF.SetCenteredNamesCaller()
    end)

    local symmetricPlayerFrame = CreateCheckbox("symmetricPlayerFrame", L["Mirror_TargetFrame"], BetterBlizzFrames, nil, BBF.SymmetricPlayerFrame)
    symmetricPlayerFrame:SetPoint("LEFT", hidePlayerName.text, "RIGHT", 0, 0)
    CreateTooltipTwo(symmetricPlayerFrame, L["Mirror_TargetFrame"], L["Tooltip_Mirror_TargetFrame_Desc"])
    -- symmetricPlayerFrame:HookScript("OnClick", function(self)
    --     if not self:GetChecked() then
    --         StaticPopup_Show("BBF_CONFIRM_RELOAD")
    --         BetterBlizzFramesDB.playerFrameOCD = nil
    --     end
    -- end)
    symmetricPlayerFrame:SetScript("OnClick", function(self)
        self:SetChecked(BetterBlizzFramesDB.symmetricPlayerFrame or false)
    end)

    symmetricPlayerFrame:SetScript("OnMouseDown", function(self, button)
        if button == "RightButton" then
            StaticPopup_Show("BBF_CONFIRM_RELOAD")
            if BetterBlizzFramesDB.symmetricPlayerFrame then
                BetterBlizzFramesDB.symmetricPlayerFrame = nil
                symmetricPlayerFrame:SetChecked(false)
                return
            end
            symmetricPlayerFrame:SetChecked(true)
            BetterBlizzFramesDB.symmetricPlayerFrame = true
        end
    end)

    -- local hidePlayerMaxHpReduction = CreateCheckbox("hidePlayerMaxHpReduction", "Hide Reduced HP", BetterBlizzFrames, nil, BBF.HideFrames)
    -- hidePlayerMaxHpReduction:SetPoint("LEFT", hidePlayerName.text, "RIGHT", 0, 0)
    -- CreateTooltipTwo(hidePlayerMaxHpReduction, L["Hide_Reduced_HP"], L["Tooltip_Hide_Reduced_HP_Player"])

    local hidePlayerPower = CreateCheckbox("hidePlayerPower", L["Hide_Resource_Power"], BetterBlizzFrames, nil, BBF.HideFrames)
    hidePlayerPower:SetPoint("TOPLEFT", hidePlayerName, "BOTTOMLEFT", 0, pixelsBetweenBoxes)
    CreateTooltipTwo(hidePlayerPower, L["Hide_Resource_Power"], L["Tooltip_Hide_Resource_Power_Desc"])

    local classOptionsFrame
    local function OpenClassSpecificWindow()
        if not classOptionsFrame then
            classOptionsFrame = CreateFrame("Frame", "ClassOptionsFrame", UIParent, "BasicFrameTemplateWithInset")
            classOptionsFrame:SetSize(185, 210)
            classOptionsFrame:SetPoint("CENTER")
            classOptionsFrame:SetFrameStrata("DIALOG")
            classOptionsFrame:SetMovable(true)
            classOptionsFrame:EnableMouse(true)
            classOptionsFrame:RegisterForDrag("LeftButton")
            classOptionsFrame:SetScript("OnDragStart", classOptionsFrame.StartMoving)
            classOptionsFrame:SetScript("OnDragStop", classOptionsFrame.StopMovingOrSizing)
            classOptionsFrame.title = classOptionsFrame:CreateFontString(nil, "OVERLAY")
            classOptionsFrame.title:SetFontObject("GameFontHighlight")
            classOptionsFrame.title:SetPoint("LEFT", classOptionsFrame.TitleBg, "LEFT", 5, 0)
            classOptionsFrame.title:SetText(L["Class_Specific_Options"])

            local classes = {
                { classID = 11, var = "hidePlayerPowerNoDruid", color = RAID_CLASS_COLORS["DRUID"] },
                { classID = 4, var = "hidePlayerPowerNoRogue", color = RAID_CLASS_COLORS["ROGUE"] },
                { classID = 9, var = "hidePlayerPowerNoWarlock", color = RAID_CLASS_COLORS["WARLOCK"] },
                { classID = 2, var = "hidePlayerPowerNoPaladin", color = RAID_CLASS_COLORS["PALADIN"] },
                { classID = 6, var = "hidePlayerPowerNoDeathKnight", color = RAID_CLASS_COLORS["DEATHKNIGHT"] },
                { classID = 13, var = "hidePlayerPowerNoEvoker", color = RAID_CLASS_COLORS["EVOKER"] },
                { classID = 10, var = "hidePlayerPowerNoMonk", color = RAID_CLASS_COLORS["MONK"] },
                { classID = 8, var = "hidePlayerPowerNoMage", color = RAID_CLASS_COLORS["MAGE"] },
            }

            local previousCheckbox
            for i, classData in ipairs(classes) do
                local classCheckbox = CreateFrame("CheckButton", nil, classOptionsFrame, "UICheckButtonTemplate")
                classCheckbox:SetSize(24, 24)
                local localizedClassName = GetClassInfo(classData.classID)
                classCheckbox.Text:SetText(string.format(L["Ignore_Class"], localizedClassName))

                -- Set the color of the checkbox label to the class color
                local r, g, b = classData.color.r, classData.color.g, classData.color.b
                classCheckbox.Text:SetTextColor(r, g, b)

                -- Position the checkboxes
                if i == 1 then
                    classCheckbox:SetPoint("TOPLEFT", classOptionsFrame, "TOPLEFT", 10, -30)
                else
                    classCheckbox:SetPoint("TOPLEFT", previousCheckbox, "BOTTOMLEFT", 0, 3)
                end

                -- Set the state from the DB
                classCheckbox:SetChecked(BetterBlizzFramesDB[classData.var])

                -- Save the state back to the DB when toggled
                classCheckbox:SetScript("OnClick", function(self)
                    BetterBlizzFramesDB[classData.var] = self:GetChecked() or nil
                    BBF.HideFrames()
                end)

                previousCheckbox = classCheckbox
            end
            classOptionsFrame:Show()
        else
            -- Toggle visibility of the frame when the function is called
            if classOptionsFrame:IsShown() then
                classOptionsFrame:Hide()
            else
                classOptionsFrame:Show()
            end
        end
    end

    hidePlayerPower:SetScript("OnMouseDown", function(self, button)
        if button == "RightButton" then
            OpenClassSpecificWindow()
        end
    end)

    local hideResourceTooltip = CreateCheckbox("hideResourceTooltip", L["Hide_Resource_Tooltip"], BetterBlizzFrames, nil, BBF.HideClassResourceTooltip)
    hideResourceTooltip:SetPoint("TOPLEFT", hidePlayerPower, "BOTTOMLEFT", 0, pixelsBetweenBoxes)
    CreateTooltipTwo(hideResourceTooltip, L["Hide_Resource_Tooltip"], L["Tooltip_Hide_Resource_Tooltip_Desc"])

    local hideManaFeedback = CreateCheckbox("hideManaFeedback", L["Hide_Mana_Feedback"], BetterBlizzFrames, nil, BBF.HideFrames)
    hideManaFeedback:SetPoint("TOPLEFT", hideResourceTooltip, "BOTTOMLEFT", 0, pixelsBetweenBoxes)
    CreateTooltipTwo(hideManaFeedback, L["Hide_Mana_Feedback"], L["Tooltip_Hide_Mana_Feedback_Desc"])

    local hidePlayerRestAnimation = CreateCheckbox("hidePlayerRestAnimation", L["Hide_Zzz_Rest_Animation"], BetterBlizzFrames, nil, BBF.HideFrames)
    hidePlayerRestAnimation:SetPoint("TOPLEFT", hideManaFeedback, "BOTTOMLEFT", 0, pixelsBetweenBoxes)
    CreateTooltip(hidePlayerRestAnimation, L["Tooltip_Hide_Zzz_Rest"])

    local hidePlayerCornerIcon = CreateCheckbox("hidePlayerCornerIcon", L["Hide_Corner_Icon"], BetterBlizzFrames, nil, BBF.HideFrames)
    hidePlayerCornerIcon:SetPoint("TOPLEFT", hidePlayerRestAnimation, "BOTTOMLEFT", 0, pixelsBetweenBoxes)
    CreateTooltip(hidePlayerCornerIcon, L["Tooltip_Hide_Corner_Icon"] .. " |A:UI-HUD-UnitFrame-Player-PortraitOn-CornerEmbellishment:22:22|a")

    local hidePlayerHealthLossAnim = CreateCheckbox("hidePlayerHealthLossAnim", L["Hide_Health_Loss_FX"], BetterBlizzFrames, nil, BBF.HideFrames)
    hidePlayerHealthLossAnim:SetPoint("LEFT", hidePlayerCornerIcon.text, "RIGHT", 0, 0)
    CreateTooltipTwo(hidePlayerHealthLossAnim, L["Tooltip_Hide_Health_Loss_FX"], L["Tooltip_Hide_Health_Loss_FX_Desc"])

    local hidePlayerRestGlow = CreateCheckbox("hidePlayerRestGlow", L["Hide_Rest_Glow"], BetterBlizzFrames, nil, BBF.HideFrames)
    hidePlayerRestGlow:SetPoint("TOPLEFT", hidePlayerCornerIcon, "BOTTOMLEFT", 0, pixelsBetweenBoxes)
    CreateTooltip(hidePlayerRestGlow, L["Tooltip_Hide_Rest_Glow"] .. " |A:UI-HUD-UnitFrame-Player-PortraitOn-Status:30:80|a")

    local hideFullPower = CreateCheckbox("hideFullPower", L["Hide_Full_Mana_FX"], BetterBlizzFrames, nil, BBF.HideFrames)
    hideFullPower:SetPoint("LEFT", hidePlayerRestGlow.text, "RIGHT", 0, 0)
    CreateTooltipTwo(hideFullPower, L["Tooltip_Hide_Full_Mana_FX"] .. " |A:FullAlert-FrameGlow:27:51|a", L["Tooltip_Hide_Full_Mana_FX_Desc"])

    local hideCombatIcon = CreateCheckbox("hideCombatIcon", L["Hide_Combat_Icon"], BetterBlizzFrames, nil, BBF.HideFrames)
    hideCombatIcon:SetPoint("TOPLEFT", hidePlayerRestGlow, "BOTTOMLEFT", 0, pixelsBetweenBoxes)
    CreateTooltip(hideCombatIcon, L["Tooltip_Hide_Combat_Icon"] .. " |A:UI-HUD-UnitFrame-Player-CombatIcon:22:22|a")

    local hideHitIndicator = CreateCheckbox("hideHitIndicator", L["Hide_Hit_Indicator"], BetterBlizzFrames, nil, BBF.HideFrames)
    hideHitIndicator:SetPoint("LEFT", hideCombatIcon.text, "RIGHT", 0, 0)
    CreateTooltipTwo(hideHitIndicator, L["Hide_Hit_Indicator"], L["Tooltip_Hide_Hit_Indicator_Desc"])

    local hideGroupIndicator = CreateCheckbox("hideGroupIndicator", L["Hide_Group_Indicator"], BetterBlizzFrames, nil, BBF.HideFrames)
    hideGroupIndicator:SetPoint("TOPLEFT", hideCombatIcon, "BOTTOMLEFT", 0, pixelsBetweenBoxes)
    CreateTooltip(hideGroupIndicator, L["Tooltip_Hide_Group_Indicator"])

    local hideTotemFrame = CreateCheckbox("hideTotemFrame", L["Hide_Totem_Frame"], BetterBlizzFrames, nil, BBF.HideFrames)
    hideTotemFrame:SetPoint("LEFT", hideGroupIndicator.text, "RIGHT", 0, 0)
    CreateTooltip(hideTotemFrame, L["Tooltip_Hide_Totem_Frame"])

    local hidePlayerLeaderIcon = CreateCheckbox("hidePlayerLeaderIcon", L["Hide_Leader_Icon"], BetterBlizzFrames, nil, BBF.HideFrames)
    hidePlayerLeaderIcon:SetPoint("TOPLEFT", hideGroupIndicator, "BOTTOMLEFT", 0, pixelsBetweenBoxes)
    CreateTooltip(hidePlayerLeaderIcon, L["Tooltip_Hide_Leader_Icon"] .. " |A:UI-HUD-UnitFrame-Player-Group-LeaderIcon:22:22|a")

    local hidePlayerGuideIcon = CreateCheckbox("hidePlayerGuideIcon", L["Hide_Guide_Icon"], BetterBlizzFrames, nil, BBF.HideFrames)
    hidePlayerGuideIcon:SetPoint("LEFT", hidePlayerLeaderIcon.text, "RIGHT", 0, 0)
    CreateTooltip(hidePlayerGuideIcon, L["Tooltip_Hide_Guide_Icon"] .. " |A:UI-HUD-UnitFrame-Player-Group-GuideIcon:22:22|a")

    local hidePlayerRoleIcon = CreateCheckbox("hidePlayerRoleIcon", L["Hide_Role_Icon"], BetterBlizzFrames, nil, BBF.HideFrames)
    hidePlayerRoleIcon:SetPoint("TOPLEFT", hidePlayerLeaderIcon, "BOTTOMLEFT", 0, pixelsBetweenBoxes)
    CreateTooltip(hidePlayerRoleIcon, L["Tooltip_Hide_Role_Icon"] .. " |A:roleicon-tiny-dps:22:22|a")

    local hidePvpTimerText = CreateCheckbox("hidePvpTimerText", L["Hide_PvP_Timer"], BetterBlizzFrames, nil, BBF.HideFrames)
    hidePvpTimerText:SetPoint("LEFT", hidePlayerRoleIcon.text, "RIGHT", 0, 0)
    CreateTooltipTwo(hidePvpTimerText, L["Hide_PvP_Timer"], L["Tooltip_Hide_PvP_Timer_Desc"])





    local petFrameText = BetterBlizzFrames:CreateFontString(nil, "OVERLAY", "GameFontNormal")
    petFrameText:SetPoint("TOPLEFT", mainGuiAnchor, "BOTTOMLEFT", 460, -455)
    petFrameText:SetText(L["Pet_Frame"])
    petFrameText:SetFont(fontLarge, 16)
    petFrameText:SetTextColor(1,1,1)
    local petFrameIcon = BetterBlizzFrames:CreateTexture(nil, "ARTWORK")
    petFrameIcon:SetAtlas("newplayerchat-chaticon-newcomer")
    petFrameIcon:SetSize(21, 21)
    petFrameIcon:SetPoint("RIGHT", petFrameText, "LEFT", -2, 0)

    local hidePetFrame = CreateCheckbox("hidePetFrame", L["Hide_Pet_Frame"], BetterBlizzFrames, nil, BBF.HideFrames)
    hidePetFrame:SetPoint("TOPLEFT", petFrameText, "BOTTOMLEFT", -24, pixelsOnFirstBox)
    CreateTooltipTwo(hidePetFrame, L["Hide_Pet_Frame"], L["Tooltip_Hide_Pet_Frame_Desc"])

    local petCastbar = CreateCheckbox("petCastbar", L["Pet_Castbar"], BetterBlizzFrames, nil, BBF.UpdatePetCastbar)
    petCastbar:SetPoint("TOPLEFT", hidePetFrame, "BOTTOMLEFT", 0, pixelsBetweenBoxes)
    CreateTooltip(petCastbar, L["Tooltip_Pet_Castbar"])

    local hidePetName = CreateCheckbox("hidePetName", L["Hide_Pet_Name"], BetterBlizzFrames)
    hidePetName:SetPoint("TOPLEFT", petCastbar, "BOTTOMLEFT", 0, pixelsBetweenBoxes)
    hidePetName:HookScript("OnClick", function (self)
        BBF.AllNameChanges()
    end)
    CreateTooltipTwo(hidePetName, L["Hide_Pet_Name"], L["Tooltip_Hide_Pet_Name_Desc"])

    local colorPetAfterOwner = CreateCheckbox("colorPetAfterOwner", L["Color_Pet_After_Player_Class"], BetterBlizzFrames)
    colorPetAfterOwner:SetPoint("TOPLEFT", hidePetName, "BOTTOMLEFT", 0, pixelsBetweenBoxes)
    colorPetAfterOwner:HookScript("OnClick", function (self)
        BBF.UpdateFrames()
    end)

    local hidePetText = CreateCheckbox("hidePetText", L["Hide_Pet_Statusbar_Text"], BetterBlizzFrames, nil, BBF.HideFrames)
    hidePetText:SetPoint("TOPLEFT", colorPetAfterOwner, "BOTTOMLEFT", 0, pixelsBetweenBoxes)
    CreateTooltipTwo(hidePetText, L["Hide_Pet_Statusbar_Text"], L["Tooltip_Hide_Pet_Statusbar_Text_Desc"])

    local hidePetHitIndicator = CreateCheckbox("hidePetHitIndicator", L["Hide_Pet_Hit_Indicator"], BetterBlizzFrames, nil, BBF.HideFrames)
    hidePetHitIndicator:SetPoint("TOPLEFT", hidePetText, "BOTTOMLEFT", 0, pixelsBetweenBoxes)
    CreateTooltipTwo(hidePetHitIndicator, L["Hide_Pet_Hit_Indicator"], L["Tooltip_Hide_Pet_Hit_Indicator_Desc"])

    local partyFrameText = BetterBlizzFrames:CreateFontString(nil, "OVERLAY", "GameFontNormal")
    partyFrameText:SetPoint("TOPLEFT", mainGuiAnchor, "BOTTOMLEFT", 0, -423)
    partyFrameText:SetText(L["Party_Frame"])
    partyFrameText:SetFont(fontLarge, 16)
    partyFrameText:SetTextColor(1,1,1)
    local partyFrameIcon = BetterBlizzFrames:CreateTexture(nil, "ARTWORK")
    partyFrameIcon:SetAtlas("groupfinder-icon-friend")
    partyFrameIcon:SetSize(25, 25)
    partyFrameIcon:SetPoint("RIGHT", partyFrameText, "LEFT", -4, -1)
    local partyFrameIcon2 = BetterBlizzFrames:CreateTexture(nil, "BORDER")
    partyFrameIcon2:SetAtlas("groupfinder-icon-friend")
    partyFrameIcon2:SetSize(20, 20)
    partyFrameIcon2:SetPoint("RIGHT", partyFrameText, "LEFT", 0, 4)

    local showPartyCastbar = CreateCheckbox("showPartyCastbar", L["Party_Castbars"], BetterBlizzFrames, nil, BBF.UpdateCastbars)
    showPartyCastbar:SetPoint("TOPLEFT", partyFrameText, "BOTTOMLEFT", -24, pixelsOnFirstBox)
    showPartyCastbar:HookScript("OnClick", function(self)
        --BBF.AbsorbCaller()
    end)
    CreateTooltip(showPartyCastbar, L["Tooltip_Show_Party_Castbar"])

    local hidePartyRoles = CreateCheckbox("hidePartyRoles", L["Hide_Role_Icons"], BetterBlizzFrames)
    hidePartyRoles:SetPoint("LEFT", showPartyCastbar.text, "RIGHT", 0, 0)
    hidePartyRoles:HookScript("OnClick", function()
        BBF.PartyNameChange()
    end)
    CreateTooltip(hidePartyRoles, L["Tooltip_Hide_Party_Role_Icons"])

--[=[
    local sortGroup = CreateCheckbox("sortGroup", L["Sort_Group"], BetterBlizzFrames, nil, BBF.SortGroup)
    sortGroup:SetPoint("TOPLEFT", showPartyCastbar, "BOTTOMLEFT", 0, pixelsBetweenBoxes)
    CreateTooltip(sortGroup, L["Tooltip_Sort_Group"])

    local sortGroupPlayerTop = CreateCheckbox("sortGroupPlayerTop", L["Player_On_Top"], BetterBlizzFrames, nil, BBF.SortGroup)
    sortGroupPlayerTop:SetPoint("LEFT", sortGroup.text, "RIGHT", 0, 0)

    local sortGroupPlayerBottom = CreateCheckbox("sortGroupPlayerBottom", L["Player_On_Bottom"], BetterBlizzFrames, nil, BBF.SortGroup)
    sortGroupPlayerBottom:SetPoint("LEFT", sortGroupPlayerTop.text, "RIGHT", 0, 0)

    sortGroupPlayerTop:HookScript("OnClick", function(self)
        if self:GetChecked() then
            sortGroupPlayerBottom:SetChecked(false)
            BetterBlizzFramesDB.sortGroupPlayerBottom = false
        end
    end)

    sortGroupPlayerBottom:HookScript("OnClick", function(self)
        if self:GetChecked() then
            sortGroupPlayerTop:SetChecked(false)
            BetterBlizzFramesDB.sortGroupPlayerTop = false
        end
    end)

    sortGroup:HookScript("OnClick", function(self)
        if self:GetChecked() then
            sortGroupPlayerTop:Enable()
            sortGroupPlayerTop:SetAlpha(1)
            sortGroupPlayerBottom:Enable()
            sortGroupPlayerBottom:SetAlpha(1)
        else
            sortGroupPlayerTop:Disable()
            sortGroupPlayerTop:SetAlpha(0)
            sortGroupPlayerBottom:Disable()
            sortGroupPlayerBottom:SetAlpha(0)
        end
    end)
    if not BetterBlizzFramesDB.sortGroup then
        sortGroupPlayerTop:SetAlpha(0)
        sortGroupPlayerBottom:SetAlpha(0)
    end

]=]


    local hidePartyFramesInArena = CreateCheckbox("hidePartyFramesInArena", L["Hide_Party_in_Arena"], BetterBlizzFrames, nil, BBF.HidePartyInArena)
    hidePartyFramesInArena:SetPoint("TOPLEFT", showPartyCastbar, "BOTTOMLEFT", 0, pixelsBetweenBoxes)
    CreateTooltip(hidePartyFramesInArena, L["Tooltip_Hide_Party_in_Arena_GEX"])

    local raidFramePixelBorder = CreateCheckbox("raidFramePixelBorder", L["Pixel_Border"], BetterBlizzFrames)
    raidFramePixelBorder:SetPoint("LEFT", hidePartyFramesInArena.text, "RIGHT", 0, 0)
    raidFramePixelBorder:HookScript("OnClick", function(self)
        StaticPopup_Show("BBF_CONFIRM_RELOAD")
    end)
    raidFramePixelBorder:HookScript("OnMouseDown", function(self, button)
        if button == "RightButton" then
            if not BetterBlizzFramesDB.raidFramePixelBorderSize then
                BetterBlizzFramesDB.raidFramePixelBorderSize = 1.5
            else
                BetterBlizzFramesDB.raidFramePixelBorderSize = nil
            end
            if GameTooltip:IsShown() and GameTooltip:GetOwner() == self then
                self:GetScript("OnEnter")(self)
            end
            StaticPopup_Show("BBF_CONFIRM_RELOAD")
        end
    end)
    CreateTooltipTwo(raidFramePixelBorder, L["Tooltip_Pixel_Border_RaidFrames_Title"], L["Tooltip_Pixel_Border_RaidFrames_Desc"])

    local hidePartyNames = CreateCheckbox("hidePartyNames", L["Hide_Names"], BetterBlizzFrames)
    hidePartyNames:SetPoint("TOPLEFT", hidePartyFramesInArena, "BOTTOMLEFT", 0, pixelsBetweenBoxes)
    hidePartyNames:HookScript("OnClick", function(self)
        BBF.AllNameChanges()
    end)

    local hidePartyAggroHighlight = CreateCheckbox("hidePartyAggroHighlight", L["Hide_Aggro_Highlight"], BetterBlizzFrames, nil, BBF.HideFrames)
    hidePartyAggroHighlight:SetPoint("LEFT", hidePartyNames.text, "RIGHT", 0, 0)
    CreateTooltip(hidePartyAggroHighlight, L["Tooltip_Hide_Party_Aggro_Highlight"])

    -- local hidePartyMaxHpReduction = CreateCheckbox("hidePartyMaxHpReduction", "Hide Reduced HP", BetterBlizzFrames, nil, BBF.HideFrames)
    -- hidePartyMaxHpReduction:SetPoint("LEFT", hidePartyRoles.text, "RIGHT", 0, 0)
    -- CreateTooltipTwo(hidePartyMaxHpReduction, L["Hide_Reduced_HP"], L["Tooltip_Hide_Reduced_HP_Party"])

    local hidePartyFrameTitle = CreateCheckbox("hidePartyFrameTitle", L["Hide_CompactPartyFrame_Title"], BetterBlizzFrames, nil, BBF.HideFrames)
    hidePartyFrameTitle:SetPoint("TOPLEFT", hidePartyNames, "BOTTOMLEFT", 0, pixelsBetweenBoxes)
    CreateTooltip(hidePartyFrameTitle, L["Tooltip_Hide_CompactPartyFrame_Title"])

    local hideCompactUnitFrameBackground = CreateCheckbox("hideCompactUnitFrameBackground", L["Hide_Bg"], BetterBlizzFrames, nil, BBF.HideCompactUnitFrameBackgrounds)
    hideCompactUnitFrameBackground:SetPoint("LEFT", hidePartyFrameTitle.Text, "RIGHT", 0, 0)
    CreateTooltipTwo(hideCompactUnitFrameBackground, L["Hide_Compact_Frame_Backgrounds"], L["Tooltip_Hide_Compact_Frame_Backgrounds"])

    local hideRaidFrameManager = CreateCheckbox("hideRaidFrameManager", L["Hide_RaidFrameManager"], BetterBlizzFrames, nil, BBF.HideFrames)
    hideRaidFrameManager:SetPoint("TOPLEFT", hidePartyFrameTitle, "BOTTOMLEFT", 0, pixelsBetweenBoxes)
    CreateTooltip(hideRaidFrameManager, L["Tooltip_Hide_RaidFrameManager"])

    local classColorPartyNames = CreateCheckbox("classColorPartyNames", L["Color_Names"], BetterBlizzFrames, nil, BBF.AllNameChanges)
    classColorPartyNames:SetPoint("LEFT", hideRaidFrameManager.Text, "RIGHT", 0, 0)
    CreateTooltipTwo(classColorPartyNames, L["Class_Color_Names"], L["Tooltip_Class_Color_Names_Party_Raid"])

    local hideRaidFrameContainerBorder = CreateCheckbox("hideRaidFrameContainerBorder", L["Hide_Container_Border"], BetterBlizzFrames, nil, BBF.HideFrames)
    hideRaidFrameContainerBorder:SetPoint("TOPLEFT", hideRaidFrameManager, "BOTTOMLEFT", 0, pixelsBetweenBoxes)
    CreateTooltipTwo(hideRaidFrameContainerBorder, L["Hide_CompactRaidFrame_Container_Border"], L["Tooltip_Hide_Container_Border_Desc"])

    local hidePartyDispelOverlay = CreateCheckbox("hidePartyDispelOverlay", L["Hide_Dispel_Overlay"], BetterBlizzFrames, nil, BBF.HideFrames)
    hidePartyDispelOverlay:SetPoint("LEFT", hideRaidFrameContainerBorder.Text, "RIGHT", 0, 0)
    hidePartyDispelOverlay:HookScript("OnMouseDown", function(self, button)
        if button == "RightButton" then
            if IsShiftKeyDown() then
                if not BetterBlizzFramesDB.hidePartyDispelOverlayKeepGradient then
                    BetterBlizzFramesDB.hidePartyDispelOverlayKeepGradient = true
                else
                    BetterBlizzFramesDB.hidePartyDispelOverlayKeepGradient = nil
                end
            else
                if not BetterBlizzFramesDB.hidePartyDispelOverlayKeepBorder then
                    BetterBlizzFramesDB.hidePartyDispelOverlayKeepBorder = true
                else
                    BetterBlizzFramesDB.hidePartyDispelOverlayKeepBorder = nil
                end
            end
            if GameTooltip:IsShown() and GameTooltip:GetOwner() == self then
                self:GetScript("OnEnter")(self)
            end
            BBF.HideFrames()
        end
    end)
    CreateTooltipTwo(hidePartyDispelOverlay, L["Hide_Dispel_Overlay"], L["Tooltip_Hide_Dispel_Overlay"])

    local hidePartyRangeIcon = CreateCheckbox("hidePartyRangeIcon", L["Hide_Range_Icon"], BetterBlizzFrames, nil, BBF.HideFrames)
    hidePartyRangeIcon:SetPoint("TOPLEFT", hidePartyDispelOverlay, "BOTTOMLEFT", 0, pixelsBetweenBoxes)
    CreateTooltipTwo(hidePartyRangeIcon, L["Hide_Range_Icon"], L["Tooltip_Hide_Range_Icon"])

    local newRaidFrameRoleIcons = CreateCheckbox("newRaidFrameRoleIcons", L["New_Role_Icons"], BetterBlizzFrames)
    newRaidFrameRoleIcons:SetPoint("TOPLEFT", hidePartyRangeIcon, "BOTTOMLEFT", 0, pixelsBetweenBoxes)
    CreateTooltipTwo(newRaidFrameRoleIcons, L["New_Role_Icons"], L["Tooltip_New_Role_Icons_Desc"])
    newRaidFrameRoleIcons:HookScript("OnClick", function(self)
        StaticPopup_Show("BBF_CONFIRM_RELOAD")
    end)

    local partyFrameScale = CreateSlider(BetterBlizzFrames, L["Party_Frame_Scale"], 0.7, 1.7, 0.01, "partyFrameScale", nil, 120)
    partyFrameScale:SetPoint("TOPLEFT", hideRaidFrameContainerBorder, "BOTTOMLEFT", 6, -9)

    local changePartyFrameRangeAlpha = CreateCheckbox("changePartyFrameRangeAlpha", "", BetterBlizzFrames)

    local partyFrameRangeAlpha = CreateSlider(changePartyFrameRangeAlpha, L["Party_Frame_Range_Alpha"], 0, 1, 0.01, "partyFrameRangeAlpha", nil, 120)
    partyFrameRangeAlpha:SetPoint("TOP", partyFrameScale, "BOTTOM", 0, -19)
    CreateTooltipTwo(changePartyFrameRangeAlpha, L["Party_Frame_Range_Alpha"], L["Tooltip_Party_Frame_Range_Alpha"])

    changePartyFrameRangeAlpha:SetPoint("RIGHT", partyFrameRangeAlpha, "LEFT", 0, 0)
    CreateTooltipTwo(changePartyFrameRangeAlpha, L["Change_Party_Frame_Alpha"], L["Tooltip_Change_Party_Frame_Alpha"])
    changePartyFrameRangeAlpha:HookScript("OnClick", function(self)
        if self:GetChecked() then
            BBF.HookAndUpdatePartyFrameRangeAlpha(true)
            EnableElement(partyFrameRangeAlpha)
        else
            StaticPopup_Show("BBF_CONFIRM_RELOAD")
            DisableElement(partyFrameRangeAlpha)
        end
    end)
    changePartyFrameRangeAlpha:HookScript("OnMouseDown", function(self, button)
        if button == "RightButton" then
            BetterBlizzFramesDB.partyFrameRangeAlphaSolidBackground = not BetterBlizzFramesDB.partyFrameRangeAlphaSolidBackground
            if GameTooltip:IsShown() and GameTooltip:GetOwner() == self then
                self:GetScript("OnEnter")(self)
            end
            StaticPopup_Show("BBF_CONFIRM_RELOAD")
        end
    end)


    local targetFrameText = BetterBlizzFrames:CreateFontString(nil, "OVERLAY", "GameFontNormal")
    targetFrameText:SetPoint("TOPLEFT", mainGuiAnchor, "BOTTOMLEFT", 250, -197)
    targetFrameText:SetText(L["Target_Frame"])
    targetFrameText:SetFont(fontLarge, 16)
    targetFrameText:SetTextColor(1,1,1)
    local targetFrameIcon = BetterBlizzFrames:CreateTexture(nil, "ARTWORK")
    targetFrameIcon:SetAtlas("groupfinder-icon-friend")
    targetFrameIcon:SetSize(28, 28)
    targetFrameIcon:SetPoint("RIGHT", targetFrameText, "LEFT", -0.5, 0)
    targetFrameIcon:SetDesaturated(1)
    targetFrameIcon:SetVertexColor(1, 0, 0)

    local targetFrameClickthrough = CreateCheckbox("targetFrameClickthrough", L["Clickthrough"], BetterBlizzFrames, nil, BBF.ClickthroughFrames)
    targetFrameClickthrough:SetPoint("TOPLEFT", targetFrameText, "BOTTOMLEFT", -24, pixelsOnFirstBox)
    CreateTooltip(targetFrameClickthrough, L["Tooltip_Target_Clickthrough"])
    targetFrameClickthrough:HookScript("OnClick", function(self)
        if not self:GetChecked() then
            StaticPopup_Show("BBF_CONFIRM_RELOAD")
        end
    end)

    local hideTargetName = CreateCheckbox("hideTargetName", L["Hide_Names"], BetterBlizzFrames, nil, BBF.UpdateNameSettings)
    hideTargetName:SetPoint("TOPLEFT", targetFrameClickthrough, "BOTTOMLEFT", 0, pixelsBetweenBoxes)
    CreateTooltip(hideTargetName, L["Tooltip_Hide_Target_Name"])
    hideTargetName:HookScript("OnClick", function(self)
        -- if self:GetChecked() then
        --     TargetFrame.name:SetAlpha(0)
        --     if TargetFrame.bbfName then
        --         TargetFrame.bbfName:SetAlpha(0)
        --     end
        -- else
        --     TargetFrame.name:SetAlpha(0)
        --     if TargetFrame.bbfName then
        --         TargetFrame.bbfName:SetAlpha(1)
        --     else
        --         TargetFrame.name:SetAlpha(1)
        --     end
        -- end
        BBF.AllNameChanges()
    end)

    -- local hideTargetMaxHpReduction = CreateCheckbox("hideTargetMaxHpReduction", "Hide Reduced HP", BetterBlizzFrames, nil, BBF.HideFrames)
    -- hideTargetMaxHpReduction:SetPoint("LEFT", hideTargetName.text, "RIGHT", 0, 0)
    -- CreateTooltipTwo(hideTargetMaxHpReduction, L["Hide_Reduced_HP"], L["Tooltip_Hide_Reduced_HP_Target"])

    local hideTargetLeaderIcon = CreateCheckbox("hideTargetLeaderIcon", L["Hide_Leader_Icon"], BetterBlizzFrames, nil, BBF.HideFrames)
    hideTargetLeaderIcon:SetPoint("TOPLEFT", hideTargetName, "BOTTOMLEFT", 0, pixelsBetweenBoxes)
    CreateTooltip(hideTargetLeaderIcon, L["Tooltip_Hide_Target_Leader_Icon"] .. " |A:UI-HUD-UnitFrame-Player-Group-LeaderIcon:22:22|a")

    local classColorTargetReputationTexture = CreateCheckbox("classColorTargetReputationTexture", L["Reputation_Class_Color"], BetterBlizzFrames)
    classColorTargetReputationTexture:SetPoint("TOPLEFT", hideTargetLeaderIcon, "BOTTOMLEFT", 0, pixelsBetweenBoxes)
    CreateTooltip(classColorTargetReputationTexture, L["Tooltip_Target_Reputation_Class_Color"] .. " |A:UI-HUD-UnitFrame-Target-PortraitOn-Type:18:98|a")
    classColorTargetReputationTexture:HookScript("OnClick", function(self)
        if self:GetChecked() then
            BBF.ClassColorReputation(TargetFrame.TargetFrameContent.TargetFrameContentMain.ReputationColor, "target")
        else
            BBF.ResetClassColorReputation(TargetFrame.TargetFrameContent.TargetFrameContentMain.ReputationColor, "target")
        end
    end)

    local hideTargetReputationColor = CreateCheckbox("hideTargetReputationColor", L["Hide_Reputation_Color"], BetterBlizzFrames, nil, BBF.HideFrames)
    hideTargetReputationColor:SetPoint("TOPLEFT", classColorTargetReputationTexture, "BOTTOMLEFT", 0, pixelsBetweenBoxes)
    CreateTooltip(hideTargetReputationColor, L["Tooltip_Hide_Target_Reputation_Color"] .. " |A:UI-HUD-UnitFrame-Target-PortraitOn-Type:18:98|a")






    local targetToTFrameText = BetterBlizzFrames:CreateFontString(nil, "OVERLAY", "GameFontNormal")
    targetToTFrameText:SetPoint("TOPLEFT", mainGuiAnchor, "BOTTOMLEFT", 250, -308)
    targetToTFrameText:SetText(L["Target_of_Target"])
    targetToTFrameText:SetFont(fontLarge, 16)
    targetToTFrameText:SetTextColor(1,1,1)
    local targetToTFrameIcon = BetterBlizzFrames:CreateTexture(nil, "BORDER")
    targetToTFrameIcon:SetAtlas("groupfinder-icon-friend")
    targetToTFrameIcon:SetSize(28, 28)
    targetToTFrameIcon:SetPoint("RIGHT", targetToTFrameText, "LEFT", -0.5, 0)
    targetToTFrameIcon:SetDesaturated(1)
    targetToTFrameIcon:SetVertexColor(1, 0, 0)
    local targetToTFrameIcon2 = BetterBlizzFrames:CreateTexture(nil, "ARTWORK")
    targetToTFrameIcon2:SetAtlas("TargetCrosshairs")
    targetToTFrameIcon2:SetSize(28, 28)
    targetToTFrameIcon2:SetPoint("TOPLEFT", targetToTFrameIcon, "TOPLEFT", 13.5, -13)

    local hideTargetToT = CreateCheckbox("hideTargetToT", L["Hide_Frame"], BetterBlizzFrames, nil, BBF.HideFrames)
    hideTargetToT:SetPoint("TOPLEFT", targetToTFrameText, "BOTTOMLEFT", -24, pixelsOnFirstBox)
    CreateTooltipTwo(hideTargetToT, L["Tooltip_Hide_ToT_Frame"])

    local hideTargetToTName = CreateCheckbox("hideTargetToTName", L["Hide_Names"], BetterBlizzFrames)
    hideTargetToTName:SetPoint("LEFT", hideTargetToT.Text, "RIGHT", 0, 0)
    hideTargetToTName:HookScript("OnClick", function(self)
        if self:GetChecked() then
            TargetFrame.totFrame.Name:SetAlpha(0)
            if TargetFrame.totFrame.bbfName then
                TargetFrame.totFrame.bbfName:SetAlpha(0)
            end
        else
            TargetFrame.totFrame.Name:SetAlpha(0)
            if TargetFrame.totFrame.bbfName then
                TargetFrame.totFrame.bbfName:SetAlpha(1)
            end
        end
    end)
    CreateTooltipTwo(hideTargetToTName, L["Tooltip_Hide_ToT_Name"])

    local hideTargetToTDebuffs = CreateCheckbox("hideTargetToTDebuffs", L["Hide_ToT_Debuffs"], BetterBlizzFrames, nil, BBF.HideFrames)
    hideTargetToTDebuffs:SetPoint("TOPLEFT", hideTargetToT, "BOTTOMLEFT", 0, pixelsBetweenBoxes)
    CreateTooltip(hideTargetToTDebuffs, L["Tooltip_Hide_ToT_Debuffs"])

    local targetToTScale = CreateSlider(BetterBlizzFrames, L["Size"], 0.6, 2.5, 0.01, "targetToTScale", nil, 120)
    targetToTScale:SetPoint("TOPLEFT", targetToTFrameText, "BOTTOMLEFT", -20, -50)
    CreateTooltip(targetToTScale, L["Tooltip_ToT_Size"])

    BBF.targetToTXPos = CreateSlider(BetterBlizzFrames, L["X_Offset"], -100, 100, 1, "targetToTXPos", "X", 120)
    BBF.targetToTXPos:SetPoint("TOP", targetToTScale, "BOTTOM", 0, -15)
    CreateTooltip(BBF.targetToTXPos, L["Tooltip_ToT_X_Offset"])

    local targetToTYPos = CreateSlider(BetterBlizzFrames, L["Y_Offset"], -100, 100, 1, "targetToTYPos", "Y", 120)
    targetToTYPos:SetPoint("TOP", BBF.targetToTXPos, "BOTTOM", 0, -15)
    CreateTooltip(targetToTYPos, L["Tooltip_ToT_Y_Offset"])




    local chatFrameText = BetterBlizzFrames:CreateFontString(nil, "OVERLAY", "GameFontNormal")
    chatFrameText:SetPoint("TOPLEFT", mainGuiAnchor, "BOTTOMLEFT", 250, -467)
    chatFrameText:SetText(L["Chat_Frame"])
    chatFrameText:SetFont(fontLarge, 16)
    chatFrameText:SetTextColor(1,1,1)
    local chatFrameIcon = BetterBlizzFrames:CreateTexture(nil, "BORDER")
    chatFrameIcon:SetAtlas("transmog-icon-chat")
    chatFrameIcon:SetSize(18, 16)
    chatFrameIcon:SetPoint("RIGHT", chatFrameText, "LEFT", -4, 0)

    local hideChatButtons = CreateCheckbox("hideChatButtons", L["Hide_Chat_Buttons"], BetterBlizzFrames, nil, BBF.HideFrames)
    hideChatButtons:SetPoint("TOPLEFT", chatFrameText, "BOTTOMLEFT", -24, pixelsOnFirstBox)
    CreateTooltip(hideChatButtons, L["Tooltip_Hide_Chat_Buttons"])

    local chatFrameFilters = BetterBlizzFrames:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
    chatFrameFilters:SetPoint("TOPLEFT", mainGuiAnchor, "BOTTOMLEFT", 232, -507)
    chatFrameFilters:SetText(L["Filters"])
    chatFrameFilters:SetFont(fontLarge, 12)
    chatFrameFilters:SetTextColor(1,1,1)

    local filterGladiusSpam = CreateCheckbox("filterGladiusSpam", L["Gladius_Spam"], BetterBlizzFrames, nil, BBF.ChatFilterCaller)
    filterGladiusSpam:SetPoint("TOPLEFT", hideChatButtons, "BOTTOMLEFT", 0, -10)
    CreateTooltip(filterGladiusSpam, L["Tooltip_Filter_Gladius_Spam"])

    local filterNpcArenaSpam = CreateCheckbox("filterNpcArenaSpam", L["Arena_Npc_Talk"], BetterBlizzFrames, nil, BBF.ChatFilterCaller)
    filterNpcArenaSpam:SetPoint("LEFT", filterGladiusSpam.text, "RIGHT", 0, 0)
    CreateTooltip(filterNpcArenaSpam, L["Tooltip_Filter_Arena_Npc_Talk"])

    local filterTalentSpam = CreateCheckbox("filterTalentSpam", L["Talent_Spam"], BetterBlizzFrames, nil, BBF.ChatFilterCaller)
    filterTalentSpam:SetPoint("TOPLEFT", filterGladiusSpam, "BOTTOMLEFT", 0, pixelsBetweenBoxes)
    CreateTooltip(filterTalentSpam, L["Tooltip_Filter_Talent_Spam"])

    local filterEmoteSpam = CreateCheckbox("filterEmoteSpam", L["Emote_Spam"], BetterBlizzFrames, nil, BBF.ChatFilterCaller)
    filterEmoteSpam:SetPoint("TOPLEFT", filterTalentSpam, "BOTTOMLEFT", 0, pixelsBetweenBoxes)
    CreateTooltip(filterEmoteSpam, L["Tooltip_Filter_Emote_Spam"])

    local filterSystemMessages = CreateCheckbox("filterSystemMessages", L["System_Messages"], BetterBlizzFrames, nil, BBF.ChatFilterCaller)
    filterSystemMessages:SetPoint("TOPLEFT", filterNpcArenaSpam, "BOTTOMLEFT", 0, pixelsBetweenBoxes)
    CreateTooltip(filterSystemMessages, L["Tooltip_Filter_System_Messages"])

    local filterMiscInfo = CreateCheckbox("filterMiscInfo", L["Misc_Info"], BetterBlizzFrames, nil, BBF.ChatFilterCaller)
    filterMiscInfo:SetPoint("TOPLEFT", filterSystemMessages, "BOTTOMLEFT", 0, pixelsBetweenBoxes)
    CreateTooltip(filterMiscInfo, L["Tooltip_Filter_Misc_Info"])

    local arenaNamesText = BetterBlizzFrames:CreateFontString(nil, "OVERLAY", "GameFontNormal")
    arenaNamesText:SetPoint("TOPLEFT", mainGuiAnchor, "BOTTOMLEFT", 460, -98)
    arenaNamesText:SetText(L["Arena_Names"])
    arenaNamesText:SetFont(fontLarge, 16)
    arenaNamesText:SetTextColor(1,1,1)
    CreateTooltip(arenaNamesText, L["Change_player_names_into_spec"], "ANCHOR_LEFT")
    local arenaNamesIcon = BetterBlizzFrames:CreateTexture(nil, "ARTWORK")
    arenaNamesIcon:SetAtlas("questlog-questtypeicon-pvp")
    arenaNamesIcon:SetSize(19, 22)
    arenaNamesIcon:SetPoint("RIGHT", arenaNamesText, "LEFT", -3.5, 0)

    local targetAndFocusArenaNames = CreateCheckbox("targetAndFocusArenaNames", L["Target_And_Focus_Arena_Names"], BetterBlizzFrames)
    targetAndFocusArenaNames:SetPoint("TOPLEFT", arenaNamesText, "BOTTOMLEFT", -24, pixelsOnFirstBox)
    CreateTooltipTwo(targetAndFocusArenaNames, L["Arena_Names"], L["Tooltip_Arena_Names_Target_Focus_Desc"], nil, "ANCHOR_LEFT")

    local partyArenaNames = CreateCheckbox("partyArenaNames", L["Party"], BetterBlizzFrames)
    partyArenaNames:SetPoint("LEFT", targetAndFocusArenaNames.text, "RIGHT", 0, 0)
    CreateTooltipTwo(partyArenaNames, L["Arena_Names"], L["Tooltip_Arena_Names_Desc"], nil, "ANCHOR_LEFT")

    local showSpecName = CreateCheckbox("showSpecName", L["Show_Spec_Name"], BetterBlizzFrames)
    showSpecName:SetPoint("TOPLEFT", targetAndFocusArenaNames, "BOTTOMLEFT", 0, pixelsBetweenBoxes)
    CreateTooltipTwo(showSpecName, L["Show_Spec_Name"], string.format(L["Tooltip_Show_Spec_Name_Desc"], (BetterBlizzFramesDB.targetAndFocusArenaNamePartyOverride and L["True"] or L["False"])))
    showSpecName:SetScript("OnMouseDown", function(self, button)
        if button == "RightButton" then
            if BetterBlizzFramesDB.targetAndFocusArenaNamePartyOverride then
                BetterBlizzFramesDB.targetAndFocusArenaNamePartyOverride = false
            else
                BetterBlizzFramesDB.targetAndFocusArenaNamePartyOverride = true
            end
            local value = (BetterBlizzFramesDB.targetAndFocusArenaNamePartyOverride and L["True"] or L["False"])
            local showSpecNameTip = L["Tooltip_Show_Spec_Name_Tip_Prefix"]..value.."|r"
            GameTooltip:ClearLines()
            GameTooltip:SetOwner(self, "ANCHOR_RIGHT")
            GameTooltip:AddLine(L["Show_Spec_Name"])
            GameTooltip:AddLine(showSpecNameTip, 1, 1, 1, true)
            GameTooltip:Show()
            CreateTooltipTwo(showSpecName, L["Show_Spec_Name"], string.format(L["Tooltip_Show_Spec_Name_Desc"], (BetterBlizzFramesDB.targetAndFocusArenaNamePartyOverride and L["True"] or L["False"])))
            BBF.AllNameChanges()
        end
    end)

    local shortArenaSpecName = CreateCheckbox("shortArenaSpecName", L["Short"], BetterBlizzFrames)
    shortArenaSpecName:SetPoint("LEFT", showSpecName.Text, "RIGHT", 0, 0)
    CreateTooltip(shortArenaSpecName, L["Tooltip_Short_Arena_Spec_Name"], "ANCHOR_LEFT")

    local showArenaID = CreateCheckbox("showArenaID", L["Show_Arena_ID"], BetterBlizzFrames)
    showArenaID:SetPoint("TOPLEFT", showSpecName, "BOTTOMLEFT", 0, pixelsBetweenBoxes)
    CreateTooltip(showArenaID, L["Tooltip_Show_Arena_ID"])

    local function ToggleDependentCheckboxes()
        local enable = targetAndFocusArenaNames:GetChecked() or partyArenaNames:GetChecked()

        if enable then
            EnableElement(showSpecName)
            EnableElement(shortArenaSpecName)
            EnableElement(showArenaID)
        else
            DisableElement(showSpecName)
            DisableElement(shortArenaSpecName)
            DisableElement(showArenaID)
        end
    end
    -- Initial setup to ensure correct state upon UI load/reload
    ToggleDependentCheckboxes()
    -- Hook into the OnClick event of targetAndFocusArenaNames
    targetAndFocusArenaNames:HookScript("OnClick", ToggleDependentCheckboxes)
    -- Hook into the OnClick event of partyArenaNames
    partyArenaNames:HookScript("OnClick", ToggleDependentCheckboxes)

    local focusFrameText = BetterBlizzFrames:CreateFontString(nil, "OVERLAY", "GameFontNormal")
    focusFrameText:SetPoint("TOPLEFT", mainGuiAnchor, "BOTTOMLEFT", 460, -183)
    focusFrameText:SetText(L["Focus_Frame"])
    focusFrameText:SetFont(fontLarge, 16)
    focusFrameText:SetTextColor(1,1,1)
    local focusFrameIcon = BetterBlizzFrames:CreateTexture(nil, "ARTWORK")
    focusFrameIcon:SetAtlas("groupfinder-icon-friend")
    focusFrameIcon:SetSize(28, 28)
    focusFrameIcon:SetPoint("RIGHT", focusFrameText, "LEFT", -0.5, 0)
    focusFrameIcon:SetDesaturated(1)
    focusFrameIcon:SetVertexColor(0, 1, 0)

    local focusFrameClickthrough = CreateCheckbox("focusFrameClickthrough", L["Clickthrough"], BetterBlizzFrames, nil, BBF.ClickthroughFrames)
    focusFrameClickthrough:SetPoint("TOPLEFT", focusFrameText, "BOTTOMLEFT", -24, pixelsOnFirstBox)
    CreateTooltip(focusFrameClickthrough, L["Tooltip_Focus_Clickthrough"])
    focusFrameClickthrough:HookScript("OnClick", function(self)
        if not self:GetChecked() then
            StaticPopup_Show("BBF_CONFIRM_RELOAD")
        end
    end)

    local hideFocusName = CreateCheckbox("hideFocusName", L["Hide_Names"], BetterBlizzFrames, nil, BBF.UpdateNameSettings)
    hideFocusName:SetPoint("TOPLEFT", focusFrameClickthrough, "BOTTOMLEFT", 0, pixelsBetweenBoxes)
    CreateTooltip(hideFocusName, L["Tooltip_Hide_Focus_Name"])
    hideFocusName:HookScript("OnClick", function(self)
        -- if self:GetChecked() then
        --     FocusFrame.name:SetAlpha(0)
        --     if FocusFrame.bbfName then
        --         FocusFrame.bbfName:SetAlpha(0)
        --     end
        -- else
        --     FocusFrame.name:SetAlpha(0)
        --     if FocusFrame.bbfName then
        --         FocusFrame.bbfName:SetAlpha(1)
        --     else
        --         FocusFrame.name:SetAlpha(1)
        --     end
        -- end
        BBF.AllNameChanges()
    end)

    -- local hideFocusMaxHpReduction = CreateCheckbox("hideFocusMaxHpReduction", "Hide Reduced HP", BetterBlizzFrames, nil, BBF.HideFrames)
    -- hideFocusMaxHpReduction:SetPoint("LEFT", hideFocusName.text, "RIGHT", 0, 0)
    -- CreateTooltipTwo(hideFocusMaxHpReduction, L["Hide_Reduced_HP"], L["Tooltip_Hide_Reduced_HP_Focus"])

    local hideFocusLeaderIcon = CreateCheckbox("hideFocusLeaderIcon", L["Hide_Leader_Icon"], BetterBlizzFrames, nil, BBF.HideFrames)
    hideFocusLeaderIcon:SetPoint("TOPLEFT", hideFocusName, "BOTTOMLEFT", 0, pixelsBetweenBoxes)
    CreateTooltip(hideFocusLeaderIcon, L["Tooltip_Hide_Focus_Leader_Icon"] .. " |A:UI-HUD-UnitFrame-Player-Group-LeaderIcon:22:22|a")

    local classColorFocusReputationTexture = CreateCheckbox("classColorFocusReputationTexture", L["Reputation_Class_Color"], BetterBlizzFrames)
    classColorFocusReputationTexture:SetPoint("TOPLEFT", hideFocusLeaderIcon, "BOTTOMLEFT", 0, pixelsBetweenBoxes)
    CreateTooltip(classColorFocusReputationTexture, L["Tooltip_Focus_Reputation_Class_Color"] .. " |A:UI-HUD-UnitFrame-Target-PortraitOn-Type:18:98|a")
    classColorFocusReputationTexture:HookScript("OnClick", function(self)
        if self:GetChecked() then
            BBF.ClassColorReputation(FocusFrame.TargetFrameContent.TargetFrameContentMain.ReputationColor, "focus")
        else
            BBF.ResetClassColorReputation(FocusFrame.TargetFrameContent.TargetFrameContentMain.ReputationColor, "focus")
        end
    end)

    local hideFocusReputationColor = CreateCheckbox("hideFocusReputationColor", L["Hide_Reputation_Color"], BetterBlizzFrames, nil, BBF.HideFrames)
    hideFocusReputationColor:SetPoint("TOPLEFT", classColorFocusReputationTexture, "BOTTOMLEFT", 0, pixelsBetweenBoxes)
    CreateTooltip(hideFocusReputationColor, L["Tooltip_Hide_Focus_Reputation_Color"] .. " |A:UI-HUD-UnitFrame-Target-PortraitOn-Type:18:98|a")







    local focusToTFrameText = BetterBlizzFrames:CreateFontString(nil, "OVERLAY", "GameFontNormal")
    focusToTFrameText:SetPoint("TOPLEFT", mainGuiAnchor, "BOTTOMLEFT", 460, -298)
    focusToTFrameText:SetText(L["Focus_ToT"])
    focusToTFrameText:SetFont(fontLarge, 16)
    focusToTFrameText:SetTextColor(1,1,1)
    local focusToTFrameIcon = BetterBlizzFrames:CreateTexture(nil, "BORDER")
    focusToTFrameIcon:SetAtlas("groupfinder-icon-friend")
    focusToTFrameIcon:SetSize(28, 28)
    focusToTFrameIcon:SetPoint("RIGHT", focusToTFrameText, "LEFT", -0.5, 0)
    focusToTFrameIcon:SetDesaturated(1)
    focusToTFrameIcon:SetVertexColor(0, 1, 0)
    local focusToTFrameIcon2 = BetterBlizzFrames:CreateTexture(nil, "ARTWORK")
    focusToTFrameIcon2:SetAtlas("TargetCrosshairs")
    focusToTFrameIcon2:SetSize(28, 28)
    focusToTFrameIcon2:SetPoint("TOPLEFT", focusToTFrameIcon, "TOPLEFT", 13.5, -13)

    local hideFocusToT = CreateCheckbox("hideFocusToT", L["Hide_Frame"], BetterBlizzFrames, nil, BBF.HideFrames)
    hideFocusToT:SetPoint("TOPLEFT", focusToTFrameText, "BOTTOMLEFT", -24, pixelsOnFirstBox)
    CreateTooltipTwo(hideFocusToT, L["Tooltip_Hide_FocusToT_Frame"])

    local hideFocusToTName = CreateCheckbox("hideFocusToTName", L["Hide_Names"], BetterBlizzFrames)
    hideFocusToTName:SetPoint("LEFT", hideFocusToT.Text, "RIGHT", 0, 0)
    hideFocusToTName:HookScript("OnClick", function(self)
        if self:GetChecked() then
            FocusFrame.totFrame.Name:SetAlpha(0)
            if FocusFrame.totFrame.bbfName then
                FocusFrame.totFrame.bbfName:SetAlpha(0)
            end
        else
            FocusFrame.totFrame.Name:SetAlpha(0)
            if FocusFrame.totFrame.bbfName then
                FocusFrame.totFrame.bbfName:SetAlpha(1)
            end
        end
    end)
    CreateTooltipTwo(hideFocusToTName, L["Tooltip_Hide_FocusToT_Name"])

    local hideFocusToTDebuffs = CreateCheckbox("hideFocusToTDebuffs", L["Hide_FocusToT_Debuffs"], BetterBlizzFrames, nil, BBF.HideFrames)
    hideFocusToTDebuffs:SetPoint("TOPLEFT", hideFocusToT, "BOTTOMLEFT", 0, pixelsBetweenBoxes)
    CreateTooltip(hideFocusToTDebuffs, L["Tooltip_Hide_ToT_Debuffs"])

    local focusToTScale = CreateSlider(BetterBlizzFrames, L["Size"], 0.6, 2.5, 0.01, "focusToTScale", nil, 120)
    focusToTScale:SetPoint("TOPLEFT", focusToTFrameText, "BOTTOMLEFT", -20, -50)
    CreateTooltip(focusToTScale, L["Tooltip_FocusToT_Size"])

    BBF.focusToTXPos = CreateSlider(BetterBlizzFrames, L["X_Offset"], -100, 100, 1, "focusToTXPos", "X", 120)
    BBF.focusToTXPos:SetPoint("TOP", focusToTScale, "BOTTOM", 0, -15)
    CreateTooltip(BBF.focusToTXPos, L["Tooltip_FocusToT_X_Offset"])

    local focusToTYPos = CreateSlider(BetterBlizzFrames, L["Y_Offset"], -100, 100, 1, "focusToTYPos", "Y", 120)
    focusToTYPos:SetPoint("TOP", BBF.focusToTXPos, "BOTTOM", 0, -15)
    CreateTooltip(focusToTYPos, L["Tooltip_FocusToT_Y_Offset"])





    local allFrameText = BetterBlizzFrames:CreateFontString(nil, "OVERLAY", "GameFontNormal")
    allFrameText:SetPoint("TOPLEFT", mainGuiAnchor, "BOTTOMLEFT", 250, 30)
    allFrameText:SetText(L["All_Frames"])
    allFrameText:SetFont(fontLarge, 16)
    allFrameText:SetTextColor(1,1,1)
    local allFrameIcon = BetterBlizzFrames:CreateTexture(nil, "ARTWORK")
    allFrameIcon:SetAtlas("groupfinder-icon-friend")
    allFrameIcon:SetSize(25, 25)
    allFrameIcon:SetPoint("RIGHT", allFrameText, "LEFT", -2, -1)
    local allFrameIcon2 = BetterBlizzFrames:CreateTexture(nil, "BORDER")
    allFrameIcon2:SetAtlas("groupfinder-icon-friend")
    allFrameIcon2:SetSize(20, 20)
    allFrameIcon2:SetPoint("RIGHT", allFrameText, "LEFT", 2, 4)
    allFrameIcon2:SetDesaturated(1)
    allFrameIcon2:SetVertexColor(0, 1, 0)
    local allFrameIcon3 = BetterBlizzFrames:CreateTexture(nil, "BORDER")
    allFrameIcon3:SetAtlas("groupfinder-icon-friend")
    allFrameIcon3:SetSize(20, 20)
    allFrameIcon3:SetPoint("RIGHT", allFrameText, "LEFT", -10, 4)
    allFrameIcon3:SetDesaturated(1)
    allFrameIcon3:SetVertexColor(1, 0, 0)

    local classicFrames = CreateCheckbox("classicFrames", L["Classic_Frames"], BetterBlizzFrames)
    classicFrames:SetPoint("TOPLEFT", allFrameText, "BOTTOMLEFT", -24, pixelsOnFirstBox)
    CreateTooltipTwo(classicFrames, L["Classic_Frames"], L["Tooltip_Classic_Frames_Desc"])
    classicFrames:HookScript("OnClick", function(self)
        BetterBlizzFramesDB.noPortraitModes = false
        if self:GetChecked() and C_AddOns.IsAddOnLoaded("ClassicFrames") then
            C_AddOns.DisableAddOn("ClassicFrames")
        end
        if self:GetChecked() then
            if not BBF.ClassicReloadWindow then
                local statusText = classicFrames:GetChecked() and "|cff00ff00ON|r" or "|cffff0000OFF|r"
                StaticPopupDialogs["BBF_CLASSIC_RELOAD"] = {
                    text = titleText..string.format(L["Popup_Classic_Frames_Turn"], statusText),
                    button1 = L["Reload_UI"],
                    button2 = L["No"],
                    OnAccept = function()
                        BetterBlizzFramesDB.reopenOptions = true
                        if BBF.ChangesOnReload then
                            for key, value in pairs(BBF.ChangesOnReload) do
                                BetterBlizzFramesDB[key] = value
                                if key == "comboPointLocation" and value ~= nil and not InCombatLockdown() then
                                    C_CVar.SetCVar("comboPointLocation", value)
                                end
                            end
                        end
                        C_AddOns.DisableAddOn("ClassicFrames")
                        ReloadUI()
                    end,
                    OnShow = function(self)
                        local statusText = classicFrames:GetChecked() and "|cff00ff00ON|r" or "|cffff0000OFF|r"
                        self.Text:SetText(titleText..string.format(L["Popup_Classic_Frames_Turn"], statusText))
                        if not self.classicSettings then
                            BBF.ChangesOnReload = {}
                            self.cfTextures = CreateFrame("CheckButton", nil, self, "UICheckButtonTemplate")
                            self.cfTextures:SetSize(26, 26)
                            CreateTooltipTwo(self.cfTextures, L["Use_Classic_Textures"], L["Tooltip_Use_Classic_Textures_Desc"])
                            self.cfTextures.Text:SetText(L["Classic_Health_Mana_Textures"])

                            self.cfCastbars = CreateFrame("CheckButton", nil, self, "UICheckButtonTemplate")
                            self.cfCastbars:SetSize(26, 26)
                            CreateTooltipTwo(self.cfCastbars, L["Use_Classic_Castbars"], L["Tooltip_Use_Classic_Castbars_Desc"])
                            self.cfCastbars.Text:SetText(L["Castbar_Classic"])

                            self.cfComboPoints = CreateFrame("CheckButton", nil, self, "UICheckButtonTemplate")
                            self.cfComboPoints:SetSize(26, 26)
                            CreateTooltipTwo(self.cfComboPoints, L["Use_Classic_Combo_Points"], L["Tooltip_Use_Classic_Combo_Points_Desc"])
                            self.cfComboPoints.Text:SetText(L["Classic_Combo_Points"])

                            local firstClick = BetterBlizzFramesDB.classicFramesClicked == nil
                            BetterBlizzFramesDB.classicFramesClicked = true

                            self.cfCastbars:SetChecked((firstClick and true) or BetterBlizzFramesDB.classicCastbars or false)
                            self.cfComboPoints:SetChecked(C_CVar.GetCVar("comboPointLocation") == "1" and true or false)
                            self.cfTextures:SetChecked(BetterBlizzFramesDB.changeUnitFrameHealthbarTexture or false)

                            self.classicSettings = true
                        end

                        local function CheckBoxes()
                            local castbarsEnabled = self.cfCastbars:GetChecked()
                            if castbarsEnabled then
                                BBF.ChangesOnReload["classicCastbarsParty"] = castbarsEnabled
                                BBF.ChangesOnReload["classicCastbarsPlayer"] = castbarsEnabled
                                BBF.ChangesOnReload["classicCastbarsPlayerBorder"] = castbarsEnabled
                                BBF.ChangesOnReload["classicCastbars"] = castbarsEnabled
                                BBF.ChangesOnReload["classicCastbarsParty"] = castbarsEnabled
                                BBF.ChangesOnReload["targetToTXPos"] = -1
                                BBF.ChangesOnReload["targetToTYPos"] = 17
                                BBF.ChangesOnReload["focusToTXPos"] = -1
                                BBF.ChangesOnReload["focusToTYPos"] = 17
                                BBF.ChangesOnReload["targetToTScale"] = 0.97
                                BBF.ChangesOnReload["focusToTScale"] = 0.97
                                BBF.ChangesOnReload["targetCastBarXPos"] = 5
                                BBF.ChangesOnReload["focusCastBarXPos"] = 5
                                BBF.ChangesOnReload["targetCastBarWidth"] = 143
                                BBF.ChangesOnReload["focusCastBarWidth"] = 143
                                BBF.ChangesOnReload["playerCastBarWidth"] = 205
                                BBF.ChangesOnReload["playerCastBarHeight"] = 12.5
                            end

                            local comboPointsEnabled = self.cfComboPoints:GetChecked()
                            BBF.ChangesOnReload["comboPointLocation"] = comboPointsEnabled and "1" or nil
                            BBF.ChangesOnReload["enableLegacyComboPoints"] = comboPointsEnabled and true or nil
                            BBF.ChangesOnReload["legacyCombosTurnedOff"] = comboPointsEnabled and nil or true

                            local statusBarsEnabled = self.cfTextures:GetChecked()
                            BBF.ChangesOnReload["changeUnitFrameHealthbarTexture"] = statusBarsEnabled or false
                            BBF.ChangesOnReload["changeUnitFrameManabarTexture"] = statusBarsEnabled or false
                            BBF.ChangesOnReload["unitFrameHealthbarTexture"] = statusBarsEnabled and "Blizzard CF" or nil
                            BBF.ChangesOnReload["unitFrameManabarTexture"] = statusBarsEnabled and "Blizzard CF" or nil
                            BBF.ChangesOnReload["hidePlayerHealthLossAnim"] = statusBarsEnabled and true or nil
                        end
                        CheckBoxes()

                        self.cfCastbars:SetScript("OnClick", function()
                            CheckBoxes()
                        end)
                        self.cfComboPoints:SetScript("OnClick", function()
                            CheckBoxes()
                        end)
                        self.cfTextures:SetScript("OnClick", function()
                            CheckBoxes()
                        end)
                        self.cfCastbars:SetPoint("BOTTOMLEFT", self.ButtonContainer.Button1, "TOPLEFT", 15, 43)
                        self.cfComboPoints:SetPoint("TOPLEFT", self.cfCastbars, "BOTTOMLEFT", 0, pixelsBetweenBoxes)
                        self.cfTextures:SetPoint("TOPLEFT", self.cfComboPoints, "BOTTOMLEFT", 0, pixelsBetweenBoxes)
                        self.cfTextures:Show()
                    end,
                    OnHide = function(self)
                        if self.cfTextures then
                            self.cfTextures:Hide()
                        end
                        if self.cfComboPoints then
                            self.cfComboPoints:Hide()
                        end
                        if self.cfCastbars then
                            self.cfCastbars:Hide()
                        end
                    end,
                    timeout = 0,
                    whileDead = true,
                }
                BBF.ClassicReloadWindow = true
            end
            StaticPopup_Show("BBF_CLASSIC_RELOAD")
        else
            local db = BetterBlizzFramesDB
            db.classicCastbarsParty = false
            db.classicCastbarsPlayer = false
            db.classicCastbarsPlayerBorder = false
            db.classicCastbars = false
            db.classicCastbarsParty = false
            db.changeUnitFrameHealthbarTexture = false
            db.changeUnitFrameManabarTexture = false
            db.comboPointLocation = nil
            db.targetToTXPos = -1
            db.targetToTYPos = 17
            db.focusToTXPos = -1
            db.focusToTYPos = 17
            db.targetToTScale = 0.97
            db.focusToTScale = 0.97
            db.targetCastBarXPos = 5
            db.focusCastBarXPos = 5
            db.targetCastBarWidth = 143
            db.focusCastBarWidth = 143
            db.playerCastBarWidth = 205
            db.playerCastBarHeight = 12.5
            db.hidePlayerHealthLossAnim = nil
            if not InCombatLockdown() then
                C_CVar.SetCVar("comboPointLocation", "2")
            end
            StaticPopup_Show("BBF_CONFIRM_RELOAD")
        end
    end)

    local noPortraitModes = CreateCheckbox("noPortraitModes", L["No_Portrait"], BetterBlizzFrames)
    noPortraitModes:SetPoint("LEFT", classicFrames.text, "RIGHT", 0, 0)
    CreateTooltipTwo(noPortraitModes, L["No_Portrait"], L["Tooltip_No_Portrait_Desc"])
    noPortraitModes:HookScript("OnClick", function(self)
        BetterBlizzFramesDB.classicFrames = false
        StaticPopup_Show("BBF_CONFIRM_RELOAD")
    end)

    local noPortraitPixelBorder = CreateCheckbox("noPortraitPixelBorder", L["NP_PixelBorder"], BetterBlizzFrames)
    noPortraitPixelBorder:SetPoint("BOTTOMLEFT", noPortraitModes, "TOPRIGHT", -14, -5)
    CreateTooltipTwo(noPortraitPixelBorder, L["No_Portrait_PixelBorder"], L["Tooltip_No_Portrait_PixelBorder_Desc"])
    noPortraitPixelBorder:HookScript("OnClick", function(self)
        if self:GetChecked() then
            BetterBlizzFramesDB.classicFrames = false
            BetterBlizzFramesDB.noPortraitModes = true
            if not BetterBlizzFramesDB.changeUnitFrameHealthbarTexture then
                BetterBlizzFramesDB.changeUnitFrameHealthbarTexture = true
                BetterBlizzFramesDB.unitFrameHealthbarTexture = "Blizzard Retail Bar Crop 2"
            end
            if not BetterBlizzFramesDB.changeUnitFrameManabarTexture then
                BetterBlizzFramesDB.changeUnitFrameManabarTexture = true
                BetterBlizzFramesDB.unitFrameManabarTexture = BetterBlizzFramesDB.unitFrameHealthbarTexture or "Blizzard Retail Bar Crop 2"
            end
        end
        StaticPopup_Show("BBF_CONFIRM_RELOAD")
    end)

    local classColorFrames = CreateCheckbox("classColorFrames", L["Class_Color_Health"], BetterBlizzFrames)
    classColorFrames:SetPoint("TOPLEFT", classicFrames, "BOTTOMLEFT", 0, pixelsBetweenBoxes)
    classColorFrames:HookScript("OnClick", function(self)
        if not self:GetChecked() then
            StaticPopup_Show("BBF_CONFIRM_RELOAD")
        end
    end)

    classColorFrames:HookScript("OnMouseDown", function(self, button)
        if button == "RightButton" then
            if IsShiftKeyDown() and not IsControlKeyDown() then
                if not BetterBlizzFramesDB.classColorFramesSkipFriendly then
                    BetterBlizzFramesDB.classColorFramesSkipFriendly = true
                else
                    BetterBlizzFramesDB.classColorFramesSkipFriendly = nil
                end
            elseif IsControlKeyDown() and not IsShiftKeyDown() then
                if not BetterBlizzFramesDB.classColorFramesSkipPlayer then
                    BetterBlizzFramesDB.classColorFramesSkipPlayer = true
                else
                    BetterBlizzFramesDB.classColorFramesSkipPlayer = nil
                end
            end
            if BetterBlizzFramesDB.classColorFramesSkipPlayer then
                if PlayerFrame and PlayerFrame.healthbar then
                    PlayerFrame.healthbar:SetStatusBarDesaturated(false)
                    PlayerFrame.healthbar:SetStatusBarColor(1, 1, 1)
                end
                if CfPlayerFrameHealthBar then
                    BBF.updateFrameColorToggleVer(CfPlayerFrameHealthBar, "player")
                end
            else
                if PlayerFrame and PlayerFrame.healthbar then
                    BBF.updateFrameColorToggleVer(PlayerFrame.healthbar, "player")
                end
                if CfPlayerFrameHealthBar then
                    BBF.updateFrameColorToggleVer(CfPlayerFrameHealthBar, "player")
                end
            end
            if GameTooltip:IsShown() and GameTooltip:GetOwner() == self then
                self:GetScript("OnEnter")(self)
            end
            BBF.UpdateFrames()
        end
    end)

    classColorFrames:HookScript("OnClick", function (self)
        local function UpdateCVar()
            if not InCombatLockdown() then
                if BetterBlizzFramesDB.classColorFrames then
                    SetCVar("raidFramesDisplayClassColor", 1)
                end
            else
                C_Timer.After(1, function()
                    UpdateCVar()
                end)
            end
        end
        UpdateCVar()
        BBF.UpdateFrames()
    end)
    CreateTooltipTwo(classColorFrames, L["Tooltip_Class_Color_Healthbars_Title"], L["Tooltip_Class_Color_Frames_Desc"])

    local customHealthbarColors = CreateCheckbox("customHealthbarColors", L["Custom_Color_Health_Mana"], BetterBlizzFrames)
    customHealthbarColors:SetPoint("TOPLEFT", classColorFrames, "BOTTOMLEFT", 0, pixelsBetweenBoxes)
    CreateTooltipTwo(customHealthbarColors, L["Custom_Colors"], L["Tooltip_Custom_Colors_Desc"])
    customHealthbarColors:HookScript("OnClick", function(self)
        BBF.UpdateFrames()
        if not self:GetChecked() then
            StaticPopup_Show("BBF_CONFIRM_RELOAD")
        end
    end)

    customHealthbarColors.extendedSettings = CreateFrame("Frame", nil, BetterBlizzFrames, "DefaultPanelFlatTemplate")
    customHealthbarColors.extendedSettings:SetSize(345, 560)
    customHealthbarColors.extendedSettings:SetPoint("TOPLEFT", classColorFrames, "BOTTOMLEFT", 0, -10)
    customHealthbarColors.extendedSettings:SetFrameStrata("DIALOG")
    customHealthbarColors.extendedSettings:SetIgnoreParentAlpha(true)
    customHealthbarColors.extendedSettings:Hide()
    customHealthbarColors.extendedSettings:SetTitle(L["Custom_Health_Colors"])
    customHealthbarColors.extendedSettings:EnableMouse(true)
    customHealthbarColors.extendedSettings:SetMovable(true)
    customHealthbarColors.extendedSettings:SetClampedToScreen(true)
    customHealthbarColors.extendedSettings:RegisterForDrag("LeftButton")
    customHealthbarColors.extendedSettings:SetScript("OnDragStart", function(self) self:StartMoving() end)
    customHealthbarColors.extendedSettings:SetScript("OnDragStop", function(self) self:StopMovingOrSizing() end)

    customHealthbarColors.closeButton = CreateFrame("Button", nil, customHealthbarColors.extendedSettings, "UIPanelCloseButton")
    customHealthbarColors.closeButton:SetPoint("TOPRIGHT", customHealthbarColors.extendedSettings, "TOPRIGHT", 0, 0)
    customHealthbarColors.closeButton:SetScript("OnClick", function()
        customHealthbarColors.extendedSettings:Hide()
        BetterBlizzFrames:SetAlpha(1)
    end)

    customHealthbarColors.bg = customHealthbarColors.extendedSettings:CreateTexture(nil, "BACKGROUND")
    customHealthbarColors.bg:SetPoint("TOPLEFT", customHealthbarColors.extendedSettings, "TOPLEFT", 7, -3)
    customHealthbarColors.bg:SetPoint("BOTTOMRIGHT", customHealthbarColors.extendedSettings, "BOTTOMRIGHT", -3, 3)
    customHealthbarColors.bg:SetColorTexture(0.08, 0.08, 0.08, 1)

    customHealthbarColors:HookScript("OnMouseDown", function(self, button)
        if button == "RightButton" then
            if IsShiftKeyDown() and not IsControlKeyDown() then
                if not BetterBlizzFramesDB.classColorFramesSkipFriendly then
                    BetterBlizzFramesDB.classColorFramesSkipFriendly = true
                else
                    BetterBlizzFramesDB.classColorFramesSkipFriendly = nil
                end
                BBF.UpdateFrames()
            elseif IsControlKeyDown() and not IsShiftKeyDown() then
                if not BetterBlizzFramesDB.classColorFramesSkipPlayer then
                    BetterBlizzFramesDB.classColorFramesSkipPlayer = true
                else
                    BetterBlizzFramesDB.classColorFramesSkipPlayer = nil
                end
                if BetterBlizzFramesDB.classColorFramesSkipPlayer then
                    if PlayerFrame and PlayerFrame.healthbar then
                        PlayerFrame.healthbar:SetStatusBarDesaturated(false)
                        PlayerFrame.healthbar:SetStatusBarColor(1, 1, 1)
                    end
                    if CfPlayerFrameHealthBar then
                        BBF.updateFrameColorToggleVer(CfPlayerFrameHealthBar, "player")
                    end
                else
                    if PlayerFrame and PlayerFrame.healthbar then
                        BBF.updateFrameColorToggleVer(PlayerFrame.healthbar, "player")
                    end
                    if CfPlayerFrameHealthBar then
                        BBF.updateFrameColorToggleVer(CfPlayerFrameHealthBar, "player")
                    end
                end
            elseif not IsShiftKeyDown() and not IsControlKeyDown() then
                customHealthbarColors.extendedSettings:SetShown(not customHealthbarColors.extendedSettings:IsShown())
                BetterBlizzFrames:SetAlpha(customHealthbarColors.extendedSettings:IsShown() and 0.5 or 1)
            end
        end
    end)

    local clrFx = customHealthbarColors.extendedSettings
    clrFx.customColorsHeader = clrFx:CreateFontString(nil, "OVERLAY", "GameFontNormal")
    clrFx.customColorsHeader:SetPoint("TOPLEFT", clrFx, "TOPLEFT", 11, -28)
    clrFx.customColorsHeader:SetText(L["Custom_Colors"])
    clrFx.customColorsHeader:SetFont(fontLarge, 14)
    clrFx.customColorsHeader:SetTextColor(1, 1, 1)

    clrFx.customColorsUnitFrames = CreateCheckbox("customColorsUnitFrames", L["Enable_On_UnitFrames"], clrFx)
    clrFx.customColorsUnitFrames:SetPoint("TOPLEFT", clrFx.customColorsHeader, "BOTTOMLEFT", 0, -1)
    CreateTooltipTwo(clrFx.customColorsUnitFrames, L["Enable_On_UnitFrames"], L["Tooltip_Enable_On_UnitFrames_Desc"])
    clrFx.customColorsUnitFrames:HookScript("OnClick", function(self)
        BBF.UpdateFrames()
    end)

    clrFx.customColorsRaidFrames = CreateCheckbox("customColorsRaidFrames", L["Enable_On_Raid_Party_Frames"], clrFx)
    clrFx.customColorsRaidFrames:SetPoint("TOPLEFT", clrFx.customColorsUnitFrames, "BOTTOMLEFT", 0, pixelsBetweenBoxes)
    CreateTooltipTwo(clrFx.customColorsRaidFrames, L["Enable_On_Raid_Party_Frames"], L["Tooltip_Enable_On_Raid_Party_Frames_Desc"])
    clrFx.customColorsRaidFrames:HookScript("OnClick", function(self)
        BBF.UpdateFrames()
    end)

    clrFx.reactionColorsSeparator = clrFx:CreateFontString(nil, "OVERLAY", "GameFontNormal")
    clrFx.reactionColorsSeparator:SetPoint("TOPLEFT", clrFx.customColorsRaidFrames, "BOTTOMLEFT", 0, -2)
    clrFx.reactionColorsSeparator:SetText(L["Reaction_Colors"])
    clrFx.reactionColorsSeparator:SetFont(fontLarge, 14)
    clrFx.reactionColorsSeparator:SetTextColor(1, 1, 1)

    clrFx.enemyHealthColor = CreateColorBox(clrFx, "enemyHealthColor", L["Enemies_Only"], function() BBF.UpdateFrames() end)
    clrFx.enemyHealthColor:SetPoint("TOPLEFT", clrFx.reactionColorsSeparator, "BOTTOMLEFT", 0, -1)
    CreateTooltipTwo(clrFx.enemyHealthColor, L["Enemy_Health_Color"], L["Tooltip_Color_Picker_Desc"])

    clrFx.friendlyHealthColor = CreateColorBox(clrFx, "friendlyHealthColor", L["Friendly"], function() BBF.UpdateFrames() end)
    clrFx.friendlyHealthColor:SetPoint("LEFT", clrFx.enemyHealthColor.text, "RIGHT", 0, 0)
    CreateTooltipTwo(clrFx.friendlyHealthColor, L["Friendly_Health_Color"], L["Tooltip_Color_Picker_Desc"])

    clrFx.neutralHealthColor = CreateColorBox(clrFx, "neutralHealthColor", L["Neutral"], function() BBF.UpdateFrames() end)
    clrFx.neutralHealthColor:SetPoint("LEFT", clrFx.friendlyHealthColor.text, "RIGHT", 0, 0)
    CreateTooltipTwo(clrFx.neutralHealthColor, L["Neutral_Health_Color"], L["Tooltip_Color_Picker_Desc"])

    clrFx.classColorsSeparator = clrFx:CreateFontString(nil, "OVERLAY", "GameFontNormal")
    clrFx.classColorsSeparator:SetPoint("TOPLEFT", clrFx.enemyHealthColor, "BOTTOMLEFT", 0, -3)
    clrFx.classColorsSeparator:SetText(L["Class_Colors"])
    clrFx.classColorsSeparator:SetFont(fontLarge, 14)
    clrFx.classColorsSeparator:SetTextColor(1, 1, 1)

    clrFx.overrideClassColors = CreateCheckbox("overrideClassColors", L["Override_Class_Colors"], clrFx)
    clrFx.overrideClassColors:SetPoint("TOPLEFT", clrFx.classColorsSeparator, "BOTTOMLEFT", 0, -1)
    CreateTooltipTwo(clrFx.overrideClassColors, L["Override_Class_Colors"], L["Tooltip_Override_Class_Colors_Desc"])

    clrFx.useOneClassColor = CreateCheckbox("useOneClassColor", L["Use_One_Color"], clrFx)
    clrFx.useOneClassColor:SetPoint("TOPLEFT", clrFx.overrideClassColors, "BOTTOMLEFT", 0, pixelsBetweenBoxes)
    CreateTooltipTwo(clrFx.useOneClassColor, L["Use_One_Color_For_All_Classes"], L["Tooltip_Use_One_Color_For_All_Classes_Desc"])
    clrFx.useOneClassColor:HookScript("OnClick", function(self)
        local enabled = not self:GetChecked()
        if self:GetChecked() then
            clrFx.singleClassColor:SetAlpha(1)
        else
            clrFx.singleClassColor:SetAlpha(0.5)
        end
        for _, classData in ipairs(customHealthbarColors.classColorBoxes) do
            if enabled then
                classData.colorBox:SetAlpha(1)
            else
                classData.colorBox:SetAlpha(0.5)
            end
        end
        BBF.UpdateFrames()
    end)

    clrFx.singleClassColor = CreateColorBox(clrFx, "singleClassColor", L["All_Classes"], function() BBF.UpdateFrames() end)
    clrFx.singleClassColor:SetPoint("LEFT", clrFx.useOneClassColor.Text, "RIGHT", 4, 0)
    CreateTooltipTwo(clrFx.singleClassColor, L["Single_Class_Color"], L["Tooltip_Color_Picker_Desc"])

    if not BetterBlizzFramesDB.useOneClassColor then
        clrFx.singleClassColor:SetAlpha(0.5)
    end

    customHealthbarColors.classColorBoxes = {}
    
    local classes = {}
    for classID = 1, GetNumClasses() do
        local _, classTag, classID = GetClassInfo(classID)
        if classTag then
            table.insert(classes, {key = classTag, name = FormatClassName(classTag)})
        end
    end
    
    table.sort(classes, function(a, b) return a.name < b.name end)

    local lastClassColorRow1
    local lastClassColorRow2
    local lastClassColorRow3
    local thirdCount = math.ceil(#classes / 3)
    
    for i, classData in ipairs(classes) do
        local classColor = CreateColorBox(clrFx, "classColor"..classData.key, classData.name, function() BBF.UpdateFrames() end)
        
        if i <= thirdCount then
            if i == 1 then
                classColor:SetPoint("TOPLEFT", clrFx.useOneClassColor, "BOTTOMLEFT", 0, 1)
            else
                classColor:SetPoint("TOPLEFT", lastClassColorRow1, "BOTTOMLEFT", 0, 1)
            end
            lastClassColorRow1 = classColor
        elseif i <= thirdCount * 2 then
            if i == thirdCount + 1 then
                classColor:SetPoint("TOPLEFT", clrFx.useOneClassColor, "BOTTOMLEFT", 105, 1)
            else
                classColor:SetPoint("TOPLEFT", lastClassColorRow2, "BOTTOMLEFT", 0, 1)
            end
            lastClassColorRow2 = classColor
        else
            if i == thirdCount * 2 + 1 then
                classColor:SetPoint("TOPLEFT", clrFx.useOneClassColor, "BOTTOMLEFT", 210, 1)
            else
                classColor:SetPoint("TOPLEFT", lastClassColorRow3, "BOTTOMLEFT", 0, 1)
            end
            lastClassColorRow3 = classColor
        end
        
        CreateTooltipTwo(classColor, classData.name.." Class Color", L["Tooltip_Color_Picker_Desc"])
        table.insert(customHealthbarColors.classColorBoxes, {colorBox = classColor, class = classData.key})
    end

    if not BetterBlizzFramesDB.overrideClassColors then
        clrFx.useOneClassColor:Disable()
        clrFx.useOneClassColor:SetAlpha(0.5)
        clrFx.singleClassColor:SetAlpha(0.5)
        for _, classData in ipairs(customHealthbarColors.classColorBoxes) do
            classData.colorBox:SetAlpha(0.5)
        end
    else
        if BetterBlizzFramesDB.useOneClassColor then
            clrFx.singleClassColor:SetAlpha(1)
            for _, classData in ipairs(customHealthbarColors.classColorBoxes) do
                classData.colorBox:SetAlpha(0.5)
            end
        else
            clrFx.singleClassColor:SetAlpha(0.5)
            for _, classData in ipairs(customHealthbarColors.classColorBoxes) do
                classData.colorBox:SetAlpha(1)
            end
        end
    end

    clrFx.useOneClassColor:HookScript("OnShow", function(self)
        local enabled = not BetterBlizzFramesDB.useOneClassColor
        local classColorsEnabled = BetterBlizzFramesDB.overrideClassColors
        for _, classData in ipairs(customHealthbarColors.classColorBoxes) do
            if classColorsEnabled and enabled then
                classData.colorBox:SetAlpha(1)
            else
                classData.colorBox:SetAlpha(0.5)
            end
        end
    end)
    
    clrFx.powerColorsSeparator = clrFx:CreateFontString(nil, "OVERLAY", "GameFontNormal")
    clrFx.powerColorsSeparator:SetPoint("TOPLEFT", lastClassColorRow1 or clrFx.useOneClassColor, "BOTTOMLEFT", 0, -3)
    clrFx.powerColorsSeparator:SetText(L["Power_Colors"])
    clrFx.powerColorsSeparator:SetFont(fontLarge, 14)
    clrFx.powerColorsSeparator:SetTextColor(1, 1, 1)

    clrFx.customPowerColors = CreateCheckbox("customPowerColors", L["Enable_Power_Colors"], clrFx)
    clrFx.customPowerColors:SetPoint("TOPLEFT", clrFx.powerColorsSeparator, "BOTTOMLEFT", 0, -1)
    CreateTooltipTwo(clrFx.customPowerColors, L["Enable_Power_Colors"], L["Tooltip_Enable_Power_Colors_Desc"])

    clrFx.useOnePowerColor = CreateCheckbox("useOnePowerColor", L["Use_One_Color"], clrFx)
    clrFx.useOnePowerColor:SetPoint("TOPLEFT", clrFx.customPowerColors, "BOTTOMLEFT", 0, pixelsBetweenBoxes)
    CreateTooltipTwo(clrFx.useOnePowerColor, L["Use_One_Color_For_All_Powers"], L["Tooltip_Use_One_Color_For_All_Powers_Desc"])
    clrFx.useOnePowerColor:HookScript("OnClick", function(self)
        local enabled = not self:GetChecked()
        if self:GetChecked() then
            clrFx.singlePowerColor:SetAlpha(1)
        else
            clrFx.singlePowerColor:SetAlpha(0.5)
        end
        for _, powerData in ipairs(customHealthbarColors.powerColorBoxes) do
            if enabled then
                powerData.colorBox:SetAlpha(1)
            else
                powerData.colorBox:SetAlpha(0.5)
            end
        end
        if BetterBlizzFramesDB.useOnePowerColor and not BetterBlizzFramesDB.changeUnitFrameManabarTexture and BetterBlizzFramesDB.useOnePowerColor and BetterBlizzFramesDB.customPowerColors then
            clrFx.singlePowerColorNote:Show()
        else
            clrFx.singlePowerColorNote:Hide()
        end
        BBF.UpdateFrames()
    end)

    clrFx.singlePowerColor = CreateColorBox(clrFx, "singlePowerColor", L["All_Powers"], function() BBF.UpdateFrames() end)
    clrFx.singlePowerColor:SetPoint("LEFT", clrFx.useOnePowerColor.Text, "RIGHT", 4, 0)
    CreateTooltipTwo(clrFx.singlePowerColor, L["Single_Power_Color"], L["Tooltip_Color_Picker_Desc"])

    clrFx.singlePowerColorNote = clrFx:CreateFontString(nil, "OVERLAY", "GameFontNormal")
    clrFx.singlePowerColorNote:SetPoint("LEFT", clrFx.singlePowerColor.text, "RIGHT", 2, 1)
    clrFx.singlePowerColorNote:SetText("|cffff0000Note!|r")
    clrFx.singlePowerColorNote:SetScript("OnEnter", function(self)
        GameTooltip:SetOwner(self, "ANCHOR_RIGHT")
        GameTooltip:SetText(L["Texture_Change_Recommended"], 1, 1, 1, 1, true)
        GameTooltip:AddLine(L["Tooltip_Texture_Change_Recommended_Desc"], nil, nil, nil, true)
        GameTooltip:Show()
    end)
    clrFx.singlePowerColorNote:SetScript("OnLeave", function(self)
        GameTooltip:Hide()
    end)
    if BetterBlizzFramesDB.useOnePowerColor and not BetterBlizzFramesDB.changeUnitFrameManabarTexture and BetterBlizzFramesDB.useOnePowerColor and BetterBlizzFramesDB.customPowerColors then
        clrFx.singlePowerColorNote:Show()
    else
        clrFx.singlePowerColorNote:Hide()
    end

    if not BetterBlizzFramesDB.useOnePowerColor then
        clrFx.singlePowerColor:SetAlpha(0.5)
    end


    local powerColors = {
        {key = "MANA", name = L["Power_Mana"]},
        {key = "RAGE", name = L["Power_Rage"]},
        {key = "FOCUS", name = L["Power_Focus"]},
        {key = "ENERGY", name = L["Power_Energy"]},
        {key = "RUNIC_POWER", name = L["Power_Runic_Power"]},
        {key = "LUNAR_POWER", name = L["Power_Lunar_Power"]},
        {key = "MAELSTROM", name = L["Power_Maelstrom"]},
        {key = "INSANITY", name = L["Power_Insanity"]},
        {key = "CHI", name = L["Power_Chi"]},
        {key = "FURY", name = L["Power_Fury"]},
        {key = "EBON_MIGHT", name = L["Power_Ebon_Might"]},
        {key = "STAGGER", name = L["Power_Stagger"]},
        {key = "SOUL_FRAGMENTS", name = L["Power_Soul_Fragments"]},
    }

    customHealthbarColors.powerColorBoxes = {}
    local lastPowerColorRow1
    local lastPowerColorRow2
    local lastPowerColorRow3
    local thirdCount = 4
    
    for i, powerData in ipairs(powerColors) do
        local powerColor = CreateColorBox(clrFx, "powerColor"..powerData.key, powerData.name, function() BBF.UpdateFrames() end)

        if i <= thirdCount then
            if i == 1 then
                powerColor:SetPoint("TOPLEFT", clrFx.useOnePowerColor, "BOTTOMLEFT", 0, 1)
            else
                powerColor:SetPoint("TOPLEFT", lastPowerColorRow1, "BOTTOMLEFT", 0, 1)
            end
            lastPowerColorRow1 = powerColor
        elseif i <= thirdCount * 2 then
            if i == thirdCount + 1 then
                powerColor:SetPoint("TOPLEFT", clrFx.useOnePowerColor, "BOTTOMLEFT", 105, 1)
            else
                powerColor:SetPoint("TOPLEFT", lastPowerColorRow2, "BOTTOMLEFT", 0, 1)
            end
            lastPowerColorRow2 = powerColor
        else
            if i == thirdCount * 2 + 1 then
                powerColor:SetPoint("TOPLEFT", clrFx.useOnePowerColor, "BOTTOMLEFT", 210, 1)
            else
                powerColor:SetPoint("TOPLEFT", lastPowerColorRow3, "BOTTOMLEFT", 0, 1)
            end
            lastPowerColorRow3 = powerColor
        end
        
        CreateTooltipTwo(powerColor, powerData.name.." Color", L["Tooltip_Color_Picker_Desc"])
        table.insert(customHealthbarColors.powerColorBoxes, {colorBox = powerColor, power = powerData.key})
    end
    
    if not BetterBlizzFramesDB.customPowerColors then
        clrFx.useOnePowerColor:Disable()
        clrFx.useOnePowerColor:SetAlpha(0.5)
        clrFx.singlePowerColor:SetAlpha(0.5)
        for _, powerData in ipairs(customHealthbarColors.powerColorBoxes) do
            powerData.colorBox:SetAlpha(0.5)
        end
    else
        if BetterBlizzFramesDB.useOnePowerColor then
            clrFx.singlePowerColor:SetAlpha(1)
            for _, powerData in ipairs(customHealthbarColors.powerColorBoxes) do
                powerData.colorBox:SetAlpha(0.5)
            end
        else
            clrFx.singlePowerColor:SetAlpha(0.5)
            for _, powerData in ipairs(customHealthbarColors.powerColorBoxes) do
                powerData.colorBox:SetAlpha(1)
            end
        end
    end

    clrFx.useOnePowerColor:HookScript("OnShow", function(self)
        local enabled = not BetterBlizzFramesDB.useOnePowerColor
        local powerColorsEnabled = BetterBlizzFramesDB.customPowerColors
        for _, powerData in ipairs(customHealthbarColors.powerColorBoxes) do
            if powerColorsEnabled and enabled then
                powerData.colorBox:SetAlpha(1)
            else
                powerData.colorBox:SetAlpha(0.5)
            end
        end
    end)
    
    clrFx.customPowerColors:HookScript("OnShow", function(self)
        local enabled = BetterBlizzFramesDB.customPowerColors
        if enabled then
            clrFx.useOnePowerColor:Enable()
            clrFx.useOnePowerColor:SetAlpha(1)
            clrFx.singlePowerColor:SetAlpha(BetterBlizzFramesDB.useOnePowerColor and 1 or 0.5)
            for _, powerData in ipairs(customHealthbarColors.powerColorBoxes) do
                powerData.colorBox:SetAlpha(BetterBlizzFramesDB.useOnePowerColor and 0.5 or 1)
            end
        else
            clrFx.useOnePowerColor:Disable()
            clrFx.useOnePowerColor:SetAlpha(0.5)
            clrFx.singlePowerColor:SetAlpha(0.5)
            for _, powerData in ipairs(customHealthbarColors.powerColorBoxes) do
                powerData.colorBox:SetAlpha(0.5)
            end
        end
    end)
    
    clrFx.customPowerColors:HookScript("OnClick", function(self)
        local enabled = self:GetChecked()
        if enabled then
            clrFx.useOnePowerColor:Enable()
            clrFx.useOnePowerColor:SetAlpha(1)
            clrFx.singlePowerColor:SetAlpha(BetterBlizzFramesDB.useOnePowerColor and 1 or 0.5)
            for _, powerData in ipairs(customHealthbarColors.powerColorBoxes) do
                powerData.colorBox:SetAlpha(BetterBlizzFramesDB.useOnePowerColor and 0.5 or 1)
            end
        else
            clrFx.useOnePowerColor:Disable()
            clrFx.useOnePowerColor:SetAlpha(0.5)
            clrFx.singlePowerColor:SetAlpha(0.5)
            for _, powerData in ipairs(customHealthbarColors.powerColorBoxes) do
                powerData.colorBox:SetAlpha(0.5)
            end
        end
        if BetterBlizzFramesDB.useOnePowerColor and not BetterBlizzFramesDB.changeUnitFrameManabarTexture and BetterBlizzFramesDB.useOnePowerColor and BetterBlizzFramesDB.customPowerColors then
            clrFx.singlePowerColorNote:Show()
        else
            clrFx.singlePowerColorNote:Hide()
        end
        BBF.UpdateFrames()
    end)

    clrFx.backgroundColorsSeparator = clrFx:CreateFontString(nil, "OVERLAY", "GameFontNormal")
    clrFx.backgroundColorsSeparator:SetPoint("TOPLEFT", lastPowerColorRow1 or clrFx.useOnePowerColor, "BOTTOMLEFT", 0, -3)
    clrFx.backgroundColorsSeparator:SetText(L["Background_Colors"])
    clrFx.backgroundColorsSeparator:SetFont(fontLarge, 14)
    clrFx.backgroundColorsSeparator:SetTextColor(1, 1, 1)

    clrFx.addUnitFrameBgTexture = CreateCheckbox("addUnitFrameBgTexture", L["Change_UnitFrame_Background_Color"], clrFx)
    clrFx.addUnitFrameBgTexture:SetPoint("TOPLEFT", clrFx.backgroundColorsSeparator, "BOTTOMLEFT", 0, -1)
    CreateTooltipTwo(clrFx.addUnitFrameBgTexture, L["Change_UnitFrame_Background_Color"], L["Tooltip_Change_UnitFrame_Background_Color_Desc"])

    clrFx.unitFrameBgTextureColor = CreateColorBox(clrFx, "unitFrameBgTextureColor", L["Health_BG"], function() BBF.UnitFrameBackgroundTexture() end)
    clrFx.unitFrameBgTextureColor:SetPoint("TOPLEFT", clrFx.addUnitFrameBgTexture, "BOTTOMLEFT", 16, 5)
    CreateTooltipTwo(clrFx.unitFrameBgTextureColor, L["Health_Bar_Background_Color"], L["Tooltip_Color_Picker_Desc"])

    clrFx.unitFrameBgTextureManaColor = CreateColorBox(clrFx, "unitFrameBgTextureManaColor", L["Mana_BG"], function() BBF.UnitFrameBackgroundTexture() end)
    clrFx.unitFrameBgTextureManaColor:SetPoint("LEFT", clrFx.unitFrameBgTextureColor.text, "RIGHT", 4, 0)
    CreateTooltipTwo(clrFx.unitFrameBgTextureManaColor, L["Mana_Bar_Background_Color"], L["Tooltip_Color_Picker_Desc"])

    clrFx.unitFrameBgTexture = CreateTextureDropdown(
        "unitFrameBgTexture",
        clrFx,
        L["Select_Texture"],
        "unitFrameBgTexture",
        function(arg1)
            BBF.UpdateCustomTextures()
            BBF.UnitFrameBackgroundTexture()
        end,
        { anchorFrame = clrFx.unitFrameBgTextureColor, x = 2, y = 4, label = "Texture" }
    )

    clrFx.changePartyRaidFrameBackgroundColor = CreateCheckbox("changePartyRaidFrameBackgroundColor", L["Change_Party_RaidFrame_Background_Color"], clrFx)
    clrFx.changePartyRaidFrameBackgroundColor:SetPoint("TOPLEFT", clrFx.unitFrameBgTextureColor, "BOTTOMLEFT", -16, pixelsBetweenBoxes-31)
    CreateTooltipTwo(clrFx.changePartyRaidFrameBackgroundColor, L["Change_Party_RaidFrame_Background_Color"], L["Tooltip_Change_Party_RaidFrame_Background_Color_Desc"])

    clrFx.partyRaidFrameBackgroundHealthColor = CreateColorBox(clrFx, "partyRaidFrameBackgroundHealthColor", L["Health_BG"], function() BBF.SetCompactUnitFramesBackground() end)
    clrFx.partyRaidFrameBackgroundHealthColor:SetPoint("TOPLEFT", clrFx.changePartyRaidFrameBackgroundColor, "BOTTOMLEFT", 16, 5)
    CreateTooltipTwo(clrFx.partyRaidFrameBackgroundHealthColor, L["Party_Raid_Health_Bar_Background_Color"], L["Tooltip_Color_Picker_Desc"])

    clrFx.partyRaidFrameBackgroundManaColor = CreateColorBox(clrFx, "partyRaidFrameBackgroundManaColor", L["Mana_BG"], function() BBF.SetCompactUnitFramesBackground() end)
    clrFx.partyRaidFrameBackgroundManaColor:SetPoint("LEFT", clrFx.partyRaidFrameBackgroundHealthColor.text, "RIGHT", 4, 0)
    CreateTooltipTwo(clrFx.partyRaidFrameBackgroundManaColor, L["Party_Raid_Mana_Bar_Background_Color"], L["Tooltip_Color_Picker_Desc"])

    clrFx.raidFrameBgTexture = CreateTextureDropdown(
        "raidFrameBgTexture",
        clrFx,
        L["Select_Texture"],
        "raidFrameBgTexture",
        function(arg1)
            BBF.UpdateCustomTextures()
            BBF.SetCompactUnitFramesBackground()
        end,
        { anchorFrame = clrFx.partyRaidFrameBackgroundHealthColor, x = 2, y = 4, label = "Texture" }
    )

    clrFx.addUnitFrameBgTexture:HookScript("OnClick", function(self)
        if self:GetChecked() then
            clrFx.unitFrameBgTextureColor:SetAlpha(1)
            clrFx.unitFrameBgTextureManaColor:SetAlpha(1)
            clrFx.unitFrameBgTexture:SetEnabled(true)
        else
            clrFx.unitFrameBgTextureColor:SetAlpha(0.5)
            clrFx.unitFrameBgTextureManaColor:SetAlpha(0.5)
            clrFx.unitFrameBgTexture:SetEnabled(false)
        end
        BBF.UnitFrameBackgroundTexture()
        BBF.UpdateCustomTextures()

        if BBF.changeUnitFrameBackgroundColorTexture then
            BBF.changeUnitFrameBackgroundColorTexture:SetChecked(self:GetChecked())
            if BBF.unitFrameBgTextureDropdown then
                BBF.unitFrameBgTextureDropdown:SetEnabled(self:GetChecked())
            end
        end
    end)
    BBF.addUnitFrameBgTexture = clrFx.addUnitFrameBgTexture

    clrFx.changePartyRaidFrameBackgroundColor:HookScript("OnClick", function(self)
        if self:GetChecked() then
            clrFx.partyRaidFrameBackgroundHealthColor:SetAlpha(1)
            clrFx.partyRaidFrameBackgroundManaColor:SetAlpha(1)
            clrFx.raidFrameBgTexture:SetEnabled(true)
        else
            clrFx.partyRaidFrameBackgroundHealthColor:SetAlpha(0.5)
            clrFx.partyRaidFrameBackgroundManaColor:SetAlpha(0.5)
            clrFx.raidFrameBgTexture:SetEnabled(false)
        end
        BBF.SetCompactUnitFramesBackground()
        BBF.UpdateFrames()
        BBF.UpdateCustomTextures()

        if BBF.changePartyRaidFrameBackgroundColorTexture then
            BBF.changePartyRaidFrameBackgroundColorTexture:SetChecked(self:GetChecked())
            if BBF.raidFrameBgTextureDropdown then
                BBF.raidFrameBgTextureDropdown:SetEnabled(self:GetChecked())
            end
        end
    end)
    BBF.changePartyRaidFrameBackgroundColor = clrFx.changePartyRaidFrameBackgroundColor

    clrFx.overrideClassColors:HookScript("OnClick", function(self)
        local enabled = self:GetChecked()
        if enabled then
            clrFx.useOneClassColor:Enable()
            clrFx.useOneClassColor:SetAlpha(1)
            clrFx.singleClassColor:SetAlpha(BetterBlizzFramesDB.useOneClassColor and 1 or 0.5)
            for _, classData in ipairs(customHealthbarColors.classColorBoxes) do
                classData.colorBox:SetAlpha(BetterBlizzFramesDB.useOneClassColor and 0.5 or 1)
            end
        else
            clrFx.useOneClassColor:Disable()
            clrFx.useOneClassColor:SetAlpha(0.5)
            clrFx.singleClassColor:SetAlpha(0.5)
            for _, classData in ipairs(customHealthbarColors.classColorBoxes) do
                classData.colorBox:SetAlpha(0.5)
            end
        end
        BBF.UpdateFrames()
    end)
    
    clrFx.overrideClassColors:HookScript("OnShow", function(self)
        local enabled = BetterBlizzFramesDB.overrideClassColors
        if enabled then
            clrFx.useOneClassColor:Enable()
            clrFx.useOneClassColor:SetAlpha(1)
            clrFx.singleClassColor:SetAlpha(BetterBlizzFramesDB.useOneClassColor and 1 or 0.5)
            for _, classData in ipairs(customHealthbarColors.classColorBoxes) do
                classData.colorBox:SetAlpha(BetterBlizzFramesDB.useOneClassColor and 0.5 or 1)
            end
        else
            clrFx.useOneClassColor:Disable()
            clrFx.useOneClassColor:SetAlpha(0.5)
            clrFx.singleClassColor:SetAlpha(0.5)
            for _, classData in ipairs(customHealthbarColors.classColorBoxes) do
                classData.colorBox:SetAlpha(0.5)
            end
        end
    end)

    local classColorTargetNames = CreateCheckbox("classColorTargetNames", L["Class_Color_Names"], BetterBlizzFrames)
    classColorTargetNames:SetPoint("TOPLEFT", customHealthbarColors, "BOTTOMLEFT", 0, pixelsBetweenBoxes)
    CreateTooltipTwo(classColorTargetNames, L["Class_Color_Names"], L["Tooltip_Class_Color_Names_Desc"])

    local classColorLevelText = CreateCheckbox("classColorLevelText", L["Level"], classColorTargetNames)
    classColorLevelText:SetPoint("LEFT", classColorTargetNames.text, "RIGHT", 0, 0)
    CreateTooltip(classColorLevelText, L["Tooltip_Level"])

    classColorTargetNames:HookScript("OnClick", function(self)
        BBF.AllNameChanges()
        if self:GetChecked() then
            classColorLevelText:Enable()
            classColorLevelText:SetAlpha(1)
        else
            classColorLevelText:Disable()
            classColorLevelText:SetAlpha(0)
        end
    end)
    if not BetterBlizzFramesDB.classColorTargetNames then
        classColorLevelText:SetAlpha(0)
    end

    local classColorFrameTexture = CreateCheckbox("classColorFrameTexture", L["Class_Color_FrameTexture"], BetterBlizzFrames)
    classColorFrameTexture:SetPoint("TOPLEFT", classColorTargetNames, "BOTTOMLEFT", 0, pixelsBetweenBoxes)
    classColorFrameTexture:HookScript("OnClick", function(self)
        if not self:GetChecked() then
            StaticPopup_Show("BBF_CONFIRM_RELOAD")
        else
            BBF.HookFrameTextureColor()
        end
    end)
    CreateTooltipTwo(classColorFrameTexture, L["Class_Color_FrameTexture"], L["Tooltip_Class_Color_FrameTexture_Desc"])


    local centerNames = CreateCheckbox("centerNames", L["Center_Name"], BetterBlizzFrames, nil, BBF.SetCenteredNamesCaller)
    centerNames:SetPoint("TOPLEFT", classColorFrameTexture, "BOTTOMLEFT", 0, pixelsBetweenBoxes)
    CreateTooltipTwo(centerNames, L["Center_Names"], L["Center_Names"])
    centerNames:HookScript("OnClick", function()
        StaticPopup_Show("BBF_CONFIRM_RELOAD")
    end)

    local removeRealmNames = CreateCheckbox("removeRealmNames", L["Hide_Realm"], BetterBlizzFrames)
    removeRealmNames:SetPoint("LEFT", centerNames.text, "RIGHT", 0, 0)
    CreateTooltipTwo(removeRealmNames, L["Tooltip_Hide_Realm_Indicator_Desc"], L["Tooltip_Hide_Realm_Indicator_Desc"])

    local formatStatusBarText = CreateCheckbox("formatStatusBarText", L["Format_Numbers"], BetterBlizzFrames, nil, BBF.HookStatusBarText)
    formatStatusBarText:SetPoint("TOPLEFT", centerNames, "BOTTOMLEFT", 0, pixelsBetweenBoxes)
    CreateTooltipTwo(formatStatusBarText, L["Format_Numbers"], L["Tooltip_Format_Numbers_Desc"], "|A:glueannouncementpopup-arrow:20:20|a" .. L["Tooltip_Format_Numbers_Extra"] .. "|A:ParagonReputation_Checkmark:15:15|a")
    formatStatusBarText:HookScript("OnMouseDown", function(self, button)
        if button == "RightButton" then
            if not BetterBlizzFramesDB.formatStatusBarTextExtraDecimals then
                BetterBlizzFramesDB.formatStatusBarTextExtraDecimals = true
            else
                BetterBlizzFramesDB.formatStatusBarTextExtraDecimals = nil
            end
            if GameTooltip:IsShown() and GameTooltip:GetOwner() == self then
                self:GetScript("OnEnter")(self)
            end
            if formatStatusBarText:GetChecked() then
                BBF.HookStatusBarText()
            end
            StaticPopup_Show("BBF_CONFIRM_RELOAD")
        end
    end)

    local singleValueStatusBarText = CreateCheckbox("singleValueStatusBarText", L["No_Max"], formatStatusBarText)
    singleValueStatusBarText:SetPoint("LEFT", formatStatusBarText.text, "RIGHT", 0, 0)
    CreateTooltipTwo(singleValueStatusBarText, L["No_Max_Value"], L["Tooltip_No_Max_Value_Desc"], "|A:glueannouncementpopup-arrow:20:20|a" .. L["Tooltip_Format_Numbers_Extra"])
    singleValueStatusBarText:HookScript("OnClick", function()
        StaticPopup_Show("BBF_CONFIRM_RELOAD")
    end)

    formatStatusBarText:HookScript("OnClick", function(self)
        StaticPopup_Show("BBF_CONFIRM_RELOAD")
        CheckAndToggleCheckboxes(self)
    end)

    local hidePrestigeBadge = CreateCheckbox("hidePrestigeBadge", L["Tooltip_Hide_PvP_Icon"], BetterBlizzFrames, nil, BBF.HideFrames)
    hidePrestigeBadge:SetPoint("TOPLEFT", formatStatusBarText, "BOTTOMLEFT", 0, pixelsBetweenBoxes)
    CreateTooltipTwo(hidePrestigeBadge, L["Hide_Prestige_Honor_Badge_PvP_Icon"], L["Tooltip_Hide_Prestige_Badge_Desc"])

    local hideCombatGlow = CreateCheckbox("hideCombatGlow", L["Hide_Combat_Glow"], BetterBlizzFrames, nil, BBF.HideFrames)
    hideCombatGlow:SetPoint("TOPLEFT", hidePrestigeBadge, "BOTTOMLEFT", 0, pixelsBetweenBoxes)
    CreateTooltip(hideCombatGlow, L["Tooltip_Hide_Combat_Glow"] .. " |A:UI-HUD-UnitFrame-Player-PortraitOn-InCombat:30:80|a")

    local hideUnitFrameShadow = CreateCheckbox("hideUnitFrameShadow", L["Hide_Shadow"], BetterBlizzFrames, nil, BBF.HideFrames)
    hideUnitFrameShadow:SetPoint("LEFT", hideCombatGlow.text, "RIGHT", 0, 0)
    CreateTooltipTwo(hideUnitFrameShadow, L["Hide_Shadow"], L["Tooltip_Hide_Shadow_Desc"])
    hideUnitFrameShadow:HookScript("OnClick", function(self)
        if not self:GetChecked() then
            StaticPopup_Show("BBF_CONFIRM_RELOAD")
        else
            BetterBlizzFramesDB.hideTargetReputationColor = true
            BetterBlizzFramesDB.hideFocusReputationColor = true
            hideTargetReputationColor:SetChecked(true)
            hideFocusReputationColor:SetChecked(true)
            BBF.HideFrames()
        end
    end)

    local hideLevelText = CreateCheckbox("hideLevelText", L["Hide_Max_Level_Text"], BetterBlizzFrames, nil, BBF.HideFrames)
    hideLevelText:SetPoint("TOPLEFT", hideCombatGlow, "BOTTOMLEFT", 0, pixelsBetweenBoxes)
    CreateTooltip(hideLevelText, L["Tooltip_Hide_Max_Level_Text"])
    hideLevelText:HookScript("OnClick", function()
        if BetterBlizzFramesDB.classicFrames then
            StaticPopup_Show("BBF_CONFIRM_RELOAD")
        end
    end)

    local hideLevelTextAlways = CreateCheckbox("hideLevelTextAlways", L["Always"], BetterBlizzFrames, nil, BBF.HideFrames)
    hideLevelTextAlways:SetPoint("LEFT", hideLevelText.Text, "RIGHT", 0, 0)
    CreateTooltip(hideLevelTextAlways, L["Tooltip_Always"])
    hideLevelTextAlways:HookScript("OnClick", function()
        if BetterBlizzFramesDB.classicFrames then
            StaticPopup_Show("BBF_CONFIRM_RELOAD")
        end
    end)

    hideLevelText:HookScript("OnClick", function(self)
        if self:GetChecked() then
            hideLevelTextAlways:Enable()
            hideLevelTextAlways:Show()
        else
            hideLevelTextAlways:Disable()
            hideLevelTextAlways:Hide()
        end
    end)

    if not BetterBlizzFramesDB.hideLevelText then
        hideLevelTextAlways:Hide()
        hideLevelTextAlways:Disable()
    end

    -- local hidePvpIcon = CreateCheckbox("hidePvpIcon", "Hide PvP Icon", BetterBlizzFrames, nil, BBF.HideFrames)
    -- hidePvpIcon:SetPoint("TOPLEFT", hideLevelText, "BOTTOMLEFT", 0, pixelsBetweenBoxes)
    -- CreateTooltip(hidePvpIcon, L["Tooltip_Hide_PvP_Icon"])

    local hideRareDragonTexture = CreateCheckbox("hideRareDragonTexture", L["Hide_Dragon"], BetterBlizzFrames, nil, BBF.HideFrames)
    hideRareDragonTexture:SetPoint("TOPLEFT", hideLevelText, "BOTTOMLEFT", 0, pixelsBetweenBoxes)
    CreateTooltip(hideRareDragonTexture, L["Tooltip_Hide_Dragon"] .. " |A:UI-HUD-UnitFrame-Target-PortraitOn-Boss-Gold:38:28|a")
    hideRareDragonTexture:HookScript("OnClick", function()
        if BetterBlizzFramesDB.classicFrames then
            StaticPopup_Show("BBF_CONFIRM_RELOAD")
        end
    end)

    local hideThreatOnFrame = CreateCheckbox("hideThreatOnFrame", L["Hide_Threat"], BetterBlizzFrames, nil, BBF.HideFrames)
    hideThreatOnFrame:SetPoint("LEFT", hideRareDragonTexture.Text, "RIGHT", 0, 0)
    CreateTooltipTwo(hideThreatOnFrame, L["Hide_Threat_Meter"], L["Tooltip_Hide_Threat_Meter_Desc"])

    local classPortraitsUseSpecIcons = CreateCheckbox("classPortraitsUseSpecIcons", L["Use_Spec_Icons"], BetterBlizzFrames, nil, BBF.SpecPortraits)
    classPortraitsUseSpecIcons:SetPoint("TOPLEFT", hideRareDragonTexture, "BOTTOMLEFT", 0, pixelsBetweenBoxes)
    CreateTooltip(classPortraitsUseSpecIcons, L["Tooltip_Use_Spec_Icons"])
    classPortraitsUseSpecIcons:HookScript("OnClick", function(self)
        if not self:GetChecked() then
            StaticPopup_Show("BBF_CONFIRM_RELOAD")
        end
    end)

    local classPortraitsUseSpecIconsSkipSelf = CreateCheckbox("classPortraitsUseSpecIconsSkipSelf", L["Skip_Self"], BetterBlizzFrames, nil, BBF.SpecPortraits)
    classPortraitsUseSpecIconsSkipSelf:SetPoint("LEFT", classPortraitsUseSpecIcons.Text, "RIGHT", 0, 0)
    CreateTooltipTwo(classPortraitsUseSpecIconsSkipSelf, L["Use_spec_icons_Skip_Self"], L["Tooltip_Skip_Self_Spec_Icon_Desc"])

    classPortraitsUseSpecIcons:HookScript("OnClick", function(self)
        if self:GetChecked() then
            classPortraitsUseSpecIconsSkipSelf:Enable()
            classPortraitsUseSpecIconsSkipSelf:Show()
        else
            classPortraitsUseSpecIconsSkipSelf:Disable()
            classPortraitsUseSpecIconsSkipSelf:Hide()
        end
    end)

    if not BetterBlizzFramesDB.classPortraitsUseSpecIcons then
        classPortraitsUseSpecIconsSkipSelf:Hide()
        classPortraitsUseSpecIconsSkipSelf:Disable()
    end

    local extraFeaturesText = BetterBlizzFrames:CreateFontString(nil, "OVERLAY", "GameFontNormal")
    extraFeaturesText:SetPoint("TOPLEFT", mainGuiAnchor, "BOTTOMLEFT", 460, 30)
    extraFeaturesText:SetText(L["Extra_Features"])
    extraFeaturesText:SetFont(fontLarge, 16)
    extraFeaturesText:SetTextColor(1,1,1)
    local extraFeaturesIcon = BetterBlizzFrames:CreateTexture(nil, "ARTWORK")
    extraFeaturesIcon:SetAtlas("Campaign-QuestLog-LoreBook")
    extraFeaturesIcon:SetSize(24, 24)
    extraFeaturesIcon:SetPoint("RIGHT", extraFeaturesText, "LEFT", -1, 0)

    local combatIndicator = CreateCheckbox("combatIndicator", L["Combat_Indicator"], BetterBlizzFrames)
    combatIndicator:SetPoint("TOPLEFT", extraFeaturesText, "BOTTOMLEFT", -24, pixelsOnFirstBox)
    combatIndicator:HookScript("OnClick", function()
        BBF.CombatIndicatorCaller()
    end)
    CreateTooltipTwo(combatIndicator, L["Combat_Indicator"], L["Tooltip_Combat_Indicator_Desc"], nil, nil, nil, 1)

    local healerIndicator = CreateCheckbox("healerIndicator", L["Healer_Indicator"], BetterBlizzFrames)
    healerIndicator:SetPoint("TOPLEFT", combatIndicator, "BOTTOMLEFT", 0, pixelsBetweenBoxes)
    healerIndicator:HookScript("OnClick", function(self)
        BBF.HealerIndicatorCaller()
        if not self:GetChecked() then
            StaticPopup_Show("BBF_CONFIRM_RELOAD")
        end
    end)
    CreateTooltipTwo(healerIndicator, L["Healer_Indicator"], L["Tooltip_Healer_Indicator_Desc"])

    local absorbIndicator = CreateCheckbox("absorbIndicator", L["Absorb_Indicator"], BetterBlizzFrames, nil, BBF.AbsorbCaller)
    absorbIndicator:SetPoint("TOPLEFT", healerIndicator, "BOTTOMLEFT", 0, pixelsBetweenBoxes)
    absorbIndicator:HookScript("OnClick", function()
        BBF.AbsorbCaller()
    end)
    CreateTooltipTwo(absorbIndicator, L["Absorb_Indicator"], L["Tooltip_Absorb_Indicator_Desc"], nil, nil, nil, 1)

    local racialIndicator = CreateCheckbox("racialIndicator", L["Racial_Indicator"], BetterBlizzFrames, nil, BBF.RacialIndicatorCaller)
    racialIndicator:SetPoint("TOPLEFT", absorbIndicator, "BOTTOMLEFT", 0, pixelsBetweenBoxes)
    racialIndicator:HookScript("OnClick", function()
        BBF.RacialIndicatorCaller()
    end)
    CreateTooltipTwo(racialIndicator, L["Racial_Indicator"], L["Tooltip_Racial_Indicator_Desc"], nil, nil, nil, 1)

    local overShields = CreateCheckbox("overShields", L["Overshields"], BetterBlizzFrames)
    overShields:SetPoint("TOPLEFT", racialIndicator, "BOTTOMLEFT", 0, pixelsBetweenBoxes)
    CreateTooltipTwo(overShields, L["Overshields"], L["Tooltip_Overshields_Desc"], nil, "ANCHOR_LEFT", nil, 2)

    local overShieldsUnitFrames = CreateCheckbox("overShieldsUnitFrames", L["A"], BetterBlizzFrames)
    overShieldsUnitFrames:SetPoint("LEFT", overShields.text, "RIGHT", 0, 0)
    CreateTooltipTwo(overShieldsUnitFrames, L["UnitFrame_Overshields"], L["Tooltip_UnitFrame_Overshields_Desc"], nil, "ANCHOR_LEFT", nil, 1)
    overShieldsUnitFrames:HookScript("OnClick", function(self)
        BBF.HookOverShields()
        StaticPopup_Show("BBF_CONFIRM_RELOAD")
    end)

    local overShieldsCompactUnitFrames = CreateCheckbox("overShieldsCompactUnitFrames", L["B"], BetterBlizzFrames)
    overShieldsCompactUnitFrames:SetPoint("LEFT", overShieldsUnitFrames.text, "RIGHT", 0, 0)
    CreateTooltipTwo(overShieldsCompactUnitFrames, L["Compact_UnitFrames_Overshields"], L["Tooltip_Compact_UnitFrames_Overshields_Desc"], nil, "ANCHOR_LEFT", nil, 2)
    overShieldsCompactUnitFrames:HookScript("OnClick", function(self)
        BBF.HookOverShields()
        StaticPopup_Show("BBF_CONFIRM_RELOAD")
    end)

    overShields:HookScript("OnClick", function(self)
        if self:GetChecked() then
            BetterBlizzFramesDB.overShieldsCompact = true
            BetterBlizzFramesDB.overShieldsUnitFrames = true
            BBF.HookOverShields()
            overShieldsUnitFrames:SetAlpha(1)
            overShieldsUnitFrames:Enable()
            overShieldsUnitFrames:SetChecked(true)
            overShieldsCompactUnitFrames:SetAlpha(1)
            overShieldsCompactUnitFrames:Enable()
            overShieldsCompactUnitFrames:SetChecked(true)
            StaticPopup_Show("BBF_CONFIRM_RELOAD")
        else
            BetterBlizzFramesDB.overShieldsCompact = false
            BetterBlizzFramesDB.overShieldsUnitFrames = false
            overShieldsUnitFrames:SetAlpha(0)
            overShieldsUnitFrames:Disable()
            overShieldsUnitFrames:SetChecked(false)
            overShieldsCompactUnitFrames:SetAlpha(0)
            overShieldsCompactUnitFrames:Disable()
            overShieldsCompactUnitFrames:SetChecked(false)
            StaticPopup_Show("BBF_CONFIRM_RELOAD")
        end
    end)

    if BetterBlizzFramesDB.overShields then
        overShieldsUnitFrames:SetAlpha(1)
        overShieldsUnitFrames:Enable()
        overShieldsCompactUnitFrames:SetAlpha(1)
        overShieldsCompactUnitFrames:Enable()
    else
        overShieldsUnitFrames:SetAlpha(0)
        overShieldsUnitFrames:Disable()
        overShieldsCompactUnitFrames:SetAlpha(0)
        overShieldsCompactUnitFrames:Disable()
    end

    local queueTimer = CreateCheckbox("queueTimer", L["Queue_Timer"], BetterBlizzFrames)
    queueTimer:SetPoint("TOPLEFT", overShields, "BOTTOMLEFT", 0, pixelsBetweenBoxes)
    CreateTooltipTwo(queueTimer, L["Queue_Timer"], L["Tooltip_Queue_Timer_Desc"], nil, "ANCHOR_LEFT")

    local queueTimerAudio = CreateCheckbox("queueTimerAudio", L["SFX"], queueTimer)
    queueTimerAudio:SetPoint("LEFT", queueTimer.text, "RIGHT", 0, 0)
    CreateTooltipTwo(queueTimerAudio, L["Sound_Effect"], L["Tooltip_Sound_Effect_Desc"], L["Tooltip_Sound_Effect_Extra"], "ANCHOR_LEFT")

    local queueTimerWarning = CreateCheckbox("queueTimerWarning", L["Queue_Timer_Warning"], queueTimer)
    queueTimerWarning:SetPoint("LEFT", queueTimerAudio.text, "RIGHT", 0, 0)
    CreateTooltipTwo(queueTimerWarning, L["Sound_Alert"], L["Tooltip_Sound_Alert_Desc"], L["Tooltip_Sound_Alert_Extra"], "ANCHOR_LEFT")

    queueTimerAudio:HookScript("OnClick", function(self)
        if self:GetChecked() then
            EnableElement(queueTimerWarning)
        else
            DisableElement(queueTimerWarning)
        end
    end)

    if not BetterBlizzFramesDB.queueTimerAudio then
        DisableElement(queueTimerWarning)
    end

    queueTimer:HookScript("OnClick", function(self)
        StaticPopup_Show("BBF_CONFIRM_RELOAD")
        CheckAndToggleCheckboxes(queueTimer)
        if not BetterBlizzFramesDB.queueTimerAudio then
            DisableElement(queueTimerWarning)
        end
        if self:GetChecked() then
            BBF.SBUncheck()
            if C_AddOns.IsAddOnLoaded("SafeQueue") then
                C_AddOns.DisableAddOn("SafeQueue")
            end
        end
    end)



    local btnGap = -2
    local starterButton = CreateClassButton(BetterBlizzFrames, "STARTER", "Starter", nil, function()
        ShowProfileConfirmation("Starter", "STARTER", BBF.StarterProfile, "|cff808080(If you want to completely reset BBF there\nis a button in Advanced Settings)|r\n\n")
    end)
    starterButton:SetPoint("TOP", profilesFrame.coreText, "BOTTOM", 0, -3)

    local bodifyButton = CreateClassButton(BetterBlizzFrames, "MAGE", "Bodify", "bodify", function()
        ShowProfileConfirmation("Bodify", "MAGE", BBF.BodifyProfile)
    end)
    bodifyButton:SetPoint("TOP", starterButton, "BOTTOM", 0, btnGap)

    local aeghisButton = CreateClassButton(BetterBlizzFrames, "MAGE", "Aeghis", "aeghis", function()
        ShowProfileConfirmation("Aeghis", "MAGE", BBF.AeghisProfile)
    end)
    aeghisButton:SetPoint("TOP", profilesFrame.streamerText, "BOTTOM", 0, -3)

    local kalvishButton = CreateClassButton(BetterBlizzFrames, "ROGUE", "Kalvish", "kalvish", function()
        ShowProfileConfirmation("Kalvish", "ROGUE", BBF.KalvishProfile)
    end)
    kalvishButton:SetPoint("TOP", aeghisButton, "BOTTOM", 0, btnGap)

    local magnuszButton = CreateClassButton(BetterBlizzFrames, "WARRIOR", "Magnusz", "magnusz", function()
        ShowProfileConfirmation("Magnusz", "WARRIOR", BBF.MagnuszProfile)
    end)
    magnuszButton:SetPoint("TOP", kalvishButton, "BOTTOM", 0, btnGap)

    local mesButton = CreateClassButton(BetterBlizzFrames, "DEATHKNIGHT", "Mes", "notmes", function()
        ShowProfileConfirmation("Mes", "DEATHKNIGHT", BBF.MesProfile)
    end)
    mesButton:SetPoint("TOP", magnuszButton, "BOTTOM", 0, btnGap)

    local mmarkersButton = CreateClassButton(BetterBlizzFrames, "DRUID", "Mmarkers", "mmarkers", function()
        ShowProfileConfirmation("Mmarkers", "DRUID", BBF.MmarkersProfile)
    end)
    mmarkersButton:SetPoint("TOP", mesButton, "BOTTOM", 0, btnGap)

    local mysticallButton = CreateClassButton(BetterBlizzFrames, "MONK", "Mysticall", "mysticallx", function()
        ShowProfileConfirmation("Mysticall", "MONK", BBF.MysticallProfile)
    end)
    mysticallButton:SetPoint("TOP", mmarkersButton, "BOTTOM", 0, btnGap)

    local nahjButton = CreateClassButton(BetterBlizzFrames, "ROGUE", "Nahj", "nahj", function()
        ShowProfileConfirmation("Nahj", "ROGUE", BBF.NahjProfile)
    end)
    nahjButton:SetPoint("TOP", mysticallButton, "BOTTOM", 0, btnGap)

    local pmakeButton = CreateClassButton(BetterBlizzFrames, "MAGE", "Pmake", "pmakewow", function()
        ShowProfileConfirmation("Pmake", "MAGE", BBF.PmakeProfile)
    end)
    pmakeButton:SetPoint("TOP", nahjButton, "BOTTOM", 0, btnGap)

    local snupyButton = CreateClassButton(BetterBlizzFrames, "DRUID", "Snupy", "snupy", function()
        ShowProfileConfirmation("Snupy", "DRUID", BBF.SnupyProfile)
    end)
    snupyButton:SetPoint("TOP", pmakeButton, "BOTTOM", 0, btnGap)

    local trimazButton = CreateClassButton(BetterBlizzFrames, "ROGUE", "Trimaz", "trimaz_wow", function()
        ShowProfileConfirmation("Trimaz", "ROGUE", BBF.TrimazProfile)
    end)
    trimazButton:SetPoint("TOP", snupyButton, "BOTTOM", 0, btnGap)

    local venrukiButton = CreateClassButton(BetterBlizzFrames, "MAGE", "Venruki", "venruki", function()
        ShowProfileConfirmation("Venruki", "MAGE", BBF.VenrukiProfile)
    end)
    venrukiButton:SetPoint("TOP", trimazButton, "BOTTOM", 0, btnGap)

    local wolfButton = CreateClassButton(BetterBlizzFrames, "DRUID", "Wolf", "wlfzx", function()
        ShowProfileConfirmation("Wolf", "DRUID", BBF.WolfProfile)
    end)
    wolfButton:SetPoint("TOP", venrukiButton, "BOTTOM", 0, btnGap)

    local resetBBFButton = CreateFrame("Button", nil, BetterBlizzFrames, "UIPanelButtonTemplate")
    resetBBFButton:SetText(L["Full_Reset"])
    resetBBFButton:SetWidth(104)
    resetBBFButton:SetPoint("BOTTOM", profilesFrame, "BOTTOM", 2, 15)
    resetBBFButton:SetScript("OnClick", function()
        StaticPopup_Show("CONFIRM_RESET_BETTERBLIZZFRAMESDB")
    end)
    CreateTooltip(resetBBFButton, L["Tooltip_Full_Reset"], "ANCHOR_TOP")




    ----------------------
    -- Reload etc
    ----------------------
    local reloadUiButton = CreateFrame("Button", nil, BetterBlizzFrames, "UIPanelButtonTemplate")
    reloadUiButton:SetText(L["Reload_UI"])
    reloadUiButton:SetWidth(96)
    reloadUiButton:SetPoint("RIGHT", SettingsPanel.CloseButton, "LEFT", -3, 0)
    reloadUiButton:SetScript("OnClick", function()
        BetterBlizzFramesDB.reopenOptions = true
        ReloadUI()
    end)

    -- if not SettingsPanel.CloseButton.origPoint then
    --     SettingsPanel.CloseButton.origPoint, SettingsPanel.CloseButton.origRel, SettingsPanel.CloseButton.origAnchor, SettingsPanel.CloseButton.origX, SettingsPanel.CloseButton.origY = SettingsPanel.CloseButton:GetPoint()
    -- end
    -- SettingsPanel.CloseButton:ClearAllPoints()
    -- SettingsPanel.CloseButton:SetPoint("TOPRIGHT", BetterBlizzFrames, "BOTTOMRIGHT", 6, -41)
    -- BetterBlizzFrames:HookScript("OnShow", function()
    --     SettingsPanel.CloseButton:ClearAllPoints()
    --     SettingsPanel.CloseButton:SetPoint("TOPRIGHT", BetterBlizzFrames, "BOTTOMRIGHT", 6, -41)
    -- end)
    -- BetterBlizzFrames:HookScript("OnHide", function()
    --     if BetterBlizzPlates and BetterBlizzPlates:IsShown() then return end
    --     SettingsPanel.CloseButton:ClearAllPoints()
    --     SettingsPanel.CloseButton:SetPoint(SettingsPanel.CloseButton.origPoint, SettingsPanel.CloseButton.origRel, SettingsPanel.CloseButton.origAnchor, SettingsPanel.CloseButton.origX, SettingsPanel.CloseButton.origY)
    -- end)
end

local function guiCastbars()

    ----------------------
    -- Advanced settings
    ----------------------
    local firstLineX = 53
    local firstLineY = -65
    local secondLineX = 222
    local secondLineY = -360
    local thirdLineX = 391
    local thirdLineY = -655
    local fourthLineX = 560

    local BetterBlizzFramesCastbars = CreateFrame("Frame")
    BetterBlizzFramesCastbars.name = L["Castbars"]
    BetterBlizzFramesCastbars.parent = BetterBlizzFrames.name
    --InterfaceOptions_AddCategory(BetterBlizzFramesCastbars)
    local castbarsSubCategory = Settings.RegisterCanvasLayoutSubcategory(BBF.category, BetterBlizzFramesCastbars, BetterBlizzFramesCastbars.name, BetterBlizzFramesCastbars.name)
    castbarsSubCategory.ID = BetterBlizzFramesCastbars.name;
    CreateTitle(BetterBlizzFramesCastbars)

    local bgImg = BetterBlizzFramesCastbars:CreateTexture(nil, "BACKGROUND")
    bgImg:SetAtlas("professions-recipe-background")
    bgImg:SetPoint("CENTER", BetterBlizzFramesCastbars, "CENTER", -8, 4)
    bgImg:SetSize(680, 610)
    bgImg:SetAlpha(0.4)
    bgImg:SetVertexColor(0,0,0)

    local scrollFrame = CreateFrame("ScrollFrame", nil, BetterBlizzFramesCastbars, "UIPanelScrollFrameTemplate")
    scrollFrame:SetSize(700, 612)
    scrollFrame:SetPoint("CENTER", BetterBlizzFramesCastbars, "CENTER", -20, 3)

    local contentFrame = CreateFrame("Frame", nil, scrollFrame)
    contentFrame.name = BetterBlizzFramesCastbars.name
    contentFrame:SetSize(680, 520)
    scrollFrame:SetScrollChild(contentFrame)

    local mainGuiAnchor2 = contentFrame:CreateFontString(nil, "OVERLAY", "GameFontNormal")
    mainGuiAnchor2:SetPoint("TOPLEFT", 55, 20)
    mainGuiAnchor2:SetText(" ")

   ----------------------
    -- Party Castbars
    ----------------------
    local anchorSubPartyCastbar = contentFrame:CreateFontString(nil, "OVERLAY", "GameFontNormal")
    anchorSubPartyCastbar:SetPoint("CENTER", mainGuiAnchor2, "CENTER", secondLineX, firstLineY)
    anchorSubPartyCastbar:SetText(L["Party_Castbars"])

    local partyCastbarBorder = CreateBorderedFrame(anchorSubPartyCastbar, 157, 386, 0, -145, contentFrame)

    local partyCastbars = contentFrame:CreateTexture(nil, "ARTWORK")
    partyCastbars:SetAtlas("ui-castingbar-filling-channel")
    partyCastbars:SetSize(110, 13)
    partyCastbars:SetPoint("BOTTOM", anchorSubPartyCastbar, "TOP", -1, 10)

    local partyCastBarScale = CreateSlider(contentFrame, L["Size"], 0.5, 1.9, 0.01, "partyCastBarScale")
    partyCastBarScale:SetPoint("TOP", anchorSubPartyCastbar, "BOTTOM", 0, -15)

    local partyCastBarXPos = CreateSlider(contentFrame, L["X_Offset"], -200, 200, 1, "partyCastBarXPos", "X")
    partyCastBarXPos:SetPoint("TOP", partyCastBarScale, "BOTTOM", 0, -15)

    local partyCastBarYPos = CreateSlider(contentFrame, L["Y_Offset"], -200, 200, 1, "partyCastBarYPos", "Y")
    partyCastBarYPos:SetPoint("TOP", partyCastBarXPos, "BOTTOM", 0, -15)

    local partyCastBarWidth = CreateSlider(contentFrame, L["Width"], 20, 200, 1, "partyCastBarWidth")
    partyCastBarWidth:SetPoint("TOP", partyCastBarYPos, "BOTTOM", 0, -15)

    local partyCastBarHeight = CreateSlider(contentFrame, L["Height"], 5, 30, 1, "partyCastBarHeight")
    partyCastBarHeight:SetPoint("TOP", partyCastBarWidth, "BOTTOM", 0, -15)

    local partyCastBarIconScale = CreateSlider(contentFrame, L["Icon_Size"], 0.4, 2, 0.01, "partyCastBarIconScale")
    partyCastBarIconScale:SetPoint("TOP", partyCastBarHeight, "BOTTOM", 0, -15)

    local partyCastbarIconXPos = CreateSlider(contentFrame, L["Icon_x_offset"], -50, 50, 1, "partyCastbarIconXPos")
    partyCastbarIconXPos:SetPoint("TOP", partyCastBarIconScale, "BOTTOM", 0, -15)

    local partyCastbarIconYPos = CreateSlider(contentFrame, L["Icon_y_offset"], -50, 50, 1, "partyCastbarIconYPos")
    partyCastbarIconYPos:SetPoint("TOP", partyCastbarIconXPos, "BOTTOM", 0, -15)

    local partyCastBarTestMode = CreateCheckbox("partyCastBarTestMode", L["Test"], contentFrame, nil, BBF.partyCastBarTestMode)
    partyCastBarTestMode:SetPoint("TOPLEFT", partyCastbarIconYPos, "BOTTOMLEFT", 10, -4)
    CreateTooltip(partyCastBarTestMode, L["Tooltip_Castbar_Test"])

    local partyCastBarTimer = CreateCheckbox("partyCastBarTimer", L["Timer"], contentFrame, nil, BBF.partyCastBarTestMode)
    partyCastBarTimer:SetPoint("LEFT", partyCastBarTestMode.Text, "RIGHT", 10, 0)
    CreateTooltip(partyCastBarTimer, L["Tooltip_Castbar_Timer"])

    local partyCastbarSelf = CreateCheckbox("partyCastbarSelf", L["Self"], contentFrame, nil, BBF.partyCastBarTestMode)
    partyCastbarSelf:SetPoint("TOPLEFT", partyCastBarTimer, "BOTTOMLEFT", 0, pixelsBetweenBoxes)
    CreateTooltip(partyCastbarSelf, L["Tooltip_Show_Party_Castbar"])

    local showPartyCastBarIcon = CreateCheckbox("showPartyCastBarIcon", L["Icon"], contentFrame, nil, BBF.partyCastBarTestMode)
    showPartyCastBarIcon:SetPoint("TOPLEFT", partyCastBarTestMode, "BOTTOMLEFT", 0, pixelsBetweenBoxes)

    anchorSubPartyCastbar.classicCastbarsParty = CreateCheckbox("classicCastbarsParty", L["Castbar_Classic"], contentFrame, nil, BBF.partyCastBarTestMode)
    anchorSubPartyCastbar.classicCastbarsParty:SetPoint("TOPLEFT", showPartyCastBarIcon, "BOTTOMLEFT", 0, pixelsBetweenBoxes)
    CreateTooltipTwo(anchorSubPartyCastbar.classicCastbarsParty, L["Castbar_Classic"], L["Tooltip_Castbar_Classic_Party_Desc"])

    anchorSubPartyCastbar.classicCastbarsParty:HookScript("OnClick", function(self)
        if not self:GetChecked() then
            StaticPopup_Show("BBF_CONFIRM_RELOAD")
        end
    end)

    local resetPartyCastbar = CreateFrame("Button", nil, contentFrame, "UIPanelButtonTemplate")
    resetPartyCastbar:SetText(L["Reset"])
    resetPartyCastbar:SetWidth(70)
    resetPartyCastbar:SetPoint("TOP", partyCastbarBorder, "BOTTOM", 0, -2)
    resetPartyCastbar:SetScript("OnClick", function()
        partyCastBarScale:SetValue(1)
        partyCastBarIconScale:SetValue(1)
        partyCastBarXPos:SetValue(0)
        partyCastBarYPos:SetValue(0)
        partyCastbarIconXPos:SetValue(0)
        partyCastbarIconYPos:SetValue(0)
        partyCastBarWidth:SetValue(100)
        partyCastBarHeight:SetValue(12)
        partyCastBarTimer:SetChecked(true)
        BetterBlizzFramesDB.partyCastBarTimer = true
        BBF.CastBarTimerCaller()
    end)


   ----------------------
    -- Target Castbar
    ----------------------
    local anchorSubTargetCastbar = contentFrame:CreateFontString(nil, "OVERLAY", "GameFontNormal")
    anchorSubTargetCastbar:SetPoint("CENTER", mainGuiAnchor2, "CENTER", thirdLineX, firstLineY)
    anchorSubTargetCastbar:SetText(L["Target_Castbar"])

    local targetCastbarBorder = CreateBorderedFrame(anchorSubTargetCastbar, 157, 386, 0, -145, contentFrame)

    local targetCastBar = contentFrame:CreateTexture(nil, "ARTWORK")
    targetCastBar:SetAtlas("ui-castingbar-tier1-empower-2x")
    targetCastBar:SetSize(110, 13)
    targetCastBar:SetPoint("BOTTOM", anchorSubTargetCastbar, "TOP", -1, 10)

    local targetCastBarScale = CreateSlider(contentFrame, L["Size"], 0.1, 1.9, 0.01, "targetCastBarScale")
    targetCastBarScale:SetPoint("TOP", anchorSubTargetCastbar, "BOTTOM", 0, -15)

    local targetCastBarXPos = CreateSlider(contentFrame, L["X_Offset"], -130, 130, 1, "targetCastBarXPos", "X")
    targetCastBarXPos:SetPoint("TOP", targetCastBarScale, "BOTTOM", 0, -15)

    local targetCastBarYPos = CreateSlider(contentFrame, L["Y_Offset"], -130, 130, 1, "targetCastBarYPos", "Y")
    targetCastBarYPos:SetPoint("TOP", targetCastBarXPos, "BOTTOM", 0, -15)

    local targetCastBarWidth = CreateSlider(contentFrame, L["Width"], 60, 220, 1, "targetCastBarWidth")
    targetCastBarWidth:SetPoint("TOP", targetCastBarYPos, "BOTTOM", 0, -15)

    local targetCastBarHeight = CreateSlider(contentFrame, L["Height"], 5, 30, 1, "targetCastBarHeight")
    targetCastBarHeight:SetPoint("TOP", targetCastBarWidth, "BOTTOM", 0, -15)

    local targetCastBarIconScale = CreateSlider(contentFrame, L["Icon_Size"], 0.4, 2, 0.01, "targetCastBarIconScale")
    targetCastBarIconScale:SetPoint("TOP", targetCastBarHeight, "BOTTOM", 0, -15)

    local targetCastbarIconXPos = CreateSlider(contentFrame, L["Icon_x_offset"], -160, 160, 1, "targetCastbarIconXPos", "X")
    targetCastbarIconXPos:SetPoint("TOP", targetCastBarIconScale, "BOTTOM", 0, -15)

    local targetCastbarIconYPos = CreateSlider(contentFrame, L["Icon_y_offset"], -160, 160, 1, "targetCastbarIconYPos", "Y")
    targetCastbarIconYPos:SetPoint("TOP", targetCastbarIconXPos, "BOTTOM", 0, -15)

    local targetStaticCastbar = CreateCheckbox("targetStaticCastbar", L["Static"], contentFrame)
    targetStaticCastbar:SetPoint("TOPLEFT", targetCastbarIconYPos, "BOTTOMLEFT", 10, -4)
    CreateTooltip(targetStaticCastbar, L["Tooltip_Castbar_Static"])

    local targetCastBarTimer = CreateCheckbox("targetCastBarTimer", L["Timer"], contentFrame, nil, BBF.CastBarTimerCaller)
    targetCastBarTimer:SetPoint("LEFT", targetStaticCastbar.Text, "RIGHT", 10, 0)
    CreateTooltip(targetCastBarTimer, L["Tooltip_Castbar_Timer"])

    local targetToTCastbarAdjustment = CreateCheckbox("targetToTCastbarAdjustment", L["ToT_Offset"], contentFrame)
    targetToTCastbarAdjustment:SetPoint("TOPLEFT", targetStaticCastbar, "BOTTOMLEFT", 0, pixelsBetweenBoxes)
    CreateTooltipTwo(targetToTCastbarAdjustment, L["Enable_ToT_Offset"], L["Tooltip_Castbar_ToT_Offset_Desc"])

    local targetToTAdjustmentOffsetY = CreateSlider(targetToTCastbarAdjustment, L["extra"], -20, 50, 1, "targetToTAdjustmentOffsetY", "Y", 55)
    targetToTAdjustmentOffsetY:SetPoint("LEFT", targetToTCastbarAdjustment.text, "RIGHT", 2, -5)
    CreateTooltipTwo(targetToTAdjustmentOffsetY, L["Tooltip_ToT_Adjustment_Offset_Y"], L["Tooltip_Castbar_ToT_Extra_Desc"])

    targetToTCastbarAdjustment:HookScript("OnClick", function(self)
        if self:GetChecked() then
            targetToTAdjustmentOffsetY:Enable()
            targetToTAdjustmentOffsetY:SetAlpha(1)
        else
            targetToTAdjustmentOffsetY:Disable()
            targetToTAdjustmentOffsetY:SetAlpha(0.5)
        end
    end)

    local targetDetachCastbar = CreateCheckbox("targetDetachCastbar", L["Castbar_Detach"], contentFrame)
    targetDetachCastbar:SetPoint("TOPLEFT", targetToTCastbarAdjustment, "BOTTOMLEFT", 0, pixelsBetweenBoxes)
    targetDetachCastbar:HookScript("OnClick", function(self)
        if self:GetChecked() then
            targetCastBarXPos:SetMinMaxValues(-900, 900)
            targetCastBarXPos:SetValue(0)
            targetCastBarYPos:SetMinMaxValues(-900, 900)
            targetCastBarYPos:SetValue(0)
            targetToTCastbarAdjustment:Disable()
            targetToTCastbarAdjustment:SetAlpha(0.5)
            targetToTAdjustmentOffsetY:Disable()
            targetToTAdjustmentOffsetY:SetAlpha(0.5)
            targetStaticCastbar:SetChecked(false)
            BetterBlizzFramesDB.targetStaticCastbar = false
        else
            targetCastBarXPos:SetMinMaxValues(-130, 130)
            targetCastBarXPos:SetValue(0)
            targetToTCastbarAdjustment:Enable()
            targetToTCastbarAdjustment:SetAlpha(1)
            targetToTAdjustmentOffsetY:Enable()
            targetToTAdjustmentOffsetY:SetAlpha(1)
        end
        BBF.ChangeCastbarSizes()
    end)
    CreateTooltip(targetDetachCastbar, L["Tooltip_Detach_From_Frame"])

    if BetterBlizzFramesDB.targetDetachCastbar then
        targetCastBarXPos:SetMinMaxValues(-900, 900)
        targetCastBarYPos:SetMinMaxValues(-900, 900)
        targetToTCastbarAdjustment:Disable()
        targetToTCastbarAdjustment:SetAlpha(0.5)
        targetToTAdjustmentOffsetY:Disable()
        targetToTAdjustmentOffsetY:SetAlpha(0.5)
        targetStaticCastbar:SetChecked(false)
        BetterBlizzFramesDB.targetStaticCastbar = false
    end
    targetStaticCastbar:HookScript("OnClick", function(self)
        if self:GetChecked() then
            targetToTCastbarAdjustment:Disable()
            targetToTCastbarAdjustment:SetAlpha(0.5)
            targetToTAdjustmentOffsetY:Disable()
            targetToTAdjustmentOffsetY:SetAlpha(0.5)
            targetDetachCastbar:SetChecked(false)
            BetterBlizzFramesDB.targetDetachCastbar = false
        else
            targetToTCastbarAdjustment:Enable()
            targetToTCastbarAdjustment:SetAlpha(1)
            targetToTAdjustmentOffsetY:Enable()
            targetToTAdjustmentOffsetY:SetAlpha(1)
        end
    end)
    if BetterBlizzFramesDB.targetStaticCastbar then
        targetToTCastbarAdjustment:Disable()
        targetToTCastbarAdjustment:SetAlpha(0.5)
        targetToTAdjustmentOffsetY:Disable()
        targetToTAdjustmentOffsetY:SetAlpha(0.5)
        targetDetachCastbar:SetChecked(false)
        BetterBlizzFramesDB.targetDetachCastbar = false
    end

    local hideTargetCastbar = CreateCheckbox("hideTargetCastbar", L["Hide_Bar"], contentFrame, nil, BBF.ChangeCastbarSizes)
    hideTargetCastbar:SetPoint("TOPLEFT", targetDetachCastbar, "BOTTOMLEFT", 0, pixelsBetweenBoxes)
    CreateTooltipTwo(hideTargetCastbar, L["Hide_Target_Castbar"], L["Hide_Target_Castbar"])

    local hideTargetCastbarIcon = CreateCheckbox("hideTargetCastbarIcon", L["Hide_Icon"], contentFrame, nil, BBF.ChangeCastbarSizes)
    hideTargetCastbarIcon:SetPoint("LEFT", hideTargetCastbar.text, "RIGHT", 0, 0)
    CreateTooltipTwo(hideTargetCastbarIcon, L["Hide_Target_Castbar_Icon"], L["Hide_Target_Castbar_Icon"])

    local resetTargetCastbar = CreateFrame("Button", nil, contentFrame, "UIPanelButtonTemplate")
    resetTargetCastbar:SetText(L["Reset"])
    resetTargetCastbar:SetWidth(70)
    resetTargetCastbar:SetPoint("TOP", targetCastbarBorder, "BOTTOM", 0, -2)
    resetTargetCastbar:SetScript("OnClick", function()
        targetCastBarScale:SetValue(1)
        targetCastBarIconScale:SetValue(1)
        targetCastBarXPos:SetValue(0)
        targetCastBarYPos:SetValue(0)
        targetCastbarIconXPos:SetValue(0)
        targetCastbarIconYPos:SetValue(0)
        targetCastBarWidth:SetValue(150)
        targetCastBarHeight:SetValue(10)
        targetCastBarTimer:SetChecked(false)
        BetterBlizzFramesDB.targetCastBarTimer = false
        targetStaticCastbar:SetChecked(false)
        BetterBlizzFramesDB.targetStaticCastbar = false
        targetDetachCastbar:SetChecked(false)
        BetterBlizzFramesDB.targetDetachCastbar = false
        targetToTCastbarAdjustment:Enable()
        targetToTCastbarAdjustment:SetAlpha(1)
        targetToTCastbarAdjustment:SetChecked(true)
        targetToTAdjustmentOffsetY:Enable()
        targetToTAdjustmentOffsetY:SetValue(0)
        BetterBlizzFramesDB.targetToTCastbarAdjustment = true
        BBF.CastBarTimerCaller()
        BBF.ChangeCastbarSizes()
    end)


    ----------------------
    -- Pet Castbars
    ----------------------
    local anchorSubPetCastbar = contentFrame:CreateFontString(nil, "OVERLAY", "GameFontNormal")
    anchorSubPetCastbar:SetPoint("CENTER", mainGuiAnchor2, "CENTER", firstLineX, secondLineY - 75)
    anchorSubPetCastbar:SetText(L["Pet_Castbar"])

    local petCastbarBorder = CreateBorderedFrame(anchorSubPetCastbar, 157, 320, 0, -122, contentFrame)

    local petCastbars = contentFrame:CreateTexture(nil, "ARTWORK")
    petCastbars:SetAtlas("ui-castingbar-filling-channel")
    petCastbars:SetDesaturated(true)
    petCastbars:SetVertexColor(1, 0.25, 0.98)
    petCastbars:SetSize(110, 13)
    petCastbars:SetPoint("BOTTOM", anchorSubPetCastbar, "TOP", -1, 10)

    local petCastBarScale = CreateSlider(contentFrame, L["Size"], 0.5, 1.9, 0.01, "petCastBarScale")
    petCastBarScale:SetPoint("TOP", anchorSubPetCastbar, "BOTTOM", 0, -15)

    local petCastBarXPos = CreateSlider(contentFrame, L["X_Offset"], -200, 200, 1, "petCastBarXPos", "X")
    petCastBarXPos:SetPoint("TOP", petCastBarScale, "BOTTOM", 0, -15)

    local petCastBarYPos = CreateSlider(contentFrame, L["Y_Offset"], -200, 200, 1, "petCastBarYPos", "Y")
    petCastBarYPos:SetPoint("TOP", petCastBarXPos, "BOTTOM", 0, -15)

    local petCastBarWidth = CreateSlider(contentFrame, L["Width"], 20, 200, 1, "petCastBarWidth")
    petCastBarWidth:SetPoint("TOP", petCastBarYPos, "BOTTOM", 0, -15)

    local petCastBarHeight = CreateSlider(contentFrame, L["Height"], 5, 30, 1, "petCastBarHeight")
    petCastBarHeight:SetPoint("TOP", petCastBarWidth, "BOTTOM", 0, -15)

    local petCastBarIconScale = CreateSlider(contentFrame, L["Icon_Size"], 0.4, 2, 0.01, "petCastBarIconScale")
    petCastBarIconScale:SetPoint("TOP", petCastBarHeight, "BOTTOM", 0, -15)

    local petCastBarTestMode = CreateCheckbox("petCastBarTestMode", L["Test"], contentFrame, nil, BBF.petCastBarTestMode)
    petCastBarTestMode:SetPoint("TOPLEFT", petCastBarIconScale, "BOTTOMLEFT", 10, -4)
    CreateTooltip(petCastBarTestMode, L["Tooltip_Need_Pet"])

    local petCastBarTimer = CreateCheckbox("petCastBarTimer", L["Timer"], contentFrame, nil, BBF.petCastBarTestMode)
    petCastBarTimer:SetPoint("LEFT", petCastBarTestMode.Text, "RIGHT", 10, 0)
    CreateTooltip(petCastBarTimer, L["Tooltip_Castbar_Timer"])

    local showPetCastBarIcon = CreateCheckbox("showPetCastBarIcon", L["Icon"], contentFrame, nil, BBF.petCastBarTestMode)
    showPetCastBarIcon:SetPoint("TOPLEFT", petCastBarTestMode, "BOTTOMLEFT", 0, pixelsBetweenBoxes)

    local petDetachCastbar = CreateCheckbox("petDetachCastbar", L["Castbar_Detach"], contentFrame, nil, BBF.petCastBarTestMode)
    petDetachCastbar:SetPoint("TOPLEFT", showPetCastBarIcon, "BOTTOMLEFT", 0, pixelsBetweenBoxes)
    petDetachCastbar:HookScript("OnClick", function(self)
        if self:GetChecked() then
            petCastBarXPos:SetMinMaxValues(-900, 900)
            petCastBarXPos:SetValue(0)
            petCastBarYPos:SetMinMaxValues(-900, 900)
            petCastBarYPos:SetValue(0)
        else
            petCastBarXPos:SetMinMaxValues(-130, 130)
            petCastBarXPos:SetValue(0)
        end
        BBF.petCastBarTestMode()
        BBF.ChangeCastbarSizes()
    end)
    CreateTooltip(petDetachCastbar, L["Tooltip_Detach_From_Frame"])

    if BetterBlizzFramesDB.petDetachCastbar then
        petCastBarXPos:SetMinMaxValues(-900, 900)
        petCastBarXPos:SetValue(0)
        petCastBarYPos:SetMinMaxValues(-900, 900)
        petCastBarYPos:SetValue(0)
    end

    local resetpetCastbar = CreateFrame("Button", nil, contentFrame, "UIPanelButtonTemplate")
    resetpetCastbar:SetText(L["Reset"])
    resetpetCastbar:SetWidth(70)
    resetpetCastbar:SetPoint("TOP", petCastbarBorder, "BOTTOM", 0, -2)
    resetpetCastbar:SetScript("OnClick", function()
        petCastBarScale:SetValue(1)
        petCastBarIconScale:SetValue(1)
        petCastBarXPos:SetValue(0)
        petCastBarYPos:SetValue(0)
        petCastBarWidth:SetValue(100)
        petCastBarHeight:SetValue(12)
        petCastBarTimer:SetChecked(true)
        petDetachCastbar:SetChecked(false)
        BetterBlizzFramesDB.petDetachCastbar = false
        BetterBlizzFramesDB.petCastBarTimer = true
        BBF.CastBarTimerCaller()
        BBF.ChangeCastbarSizes()
    end)

   ----------------------
    -- Focus Castbar
    ----------------------
    local anchorSubFocusCastbar = contentFrame:CreateFontString(nil, "OVERLAY", "GameFontNormal")
    anchorSubFocusCastbar:SetPoint("CENTER", mainGuiAnchor2, "CENTER", fourthLineX, firstLineY)
    anchorSubFocusCastbar:SetText(L["Focus_Castbar"])

    local focusCastbarBorder = CreateBorderedFrame(anchorSubFocusCastbar, 157, 386, 0, -145, contentFrame)

    local focusCastBar = contentFrame:CreateTexture(nil, "ARTWORK")
    focusCastBar:SetAtlas("ui-castingbar-full-applyingcrafting")
    focusCastBar:SetSize(110, 16)
    focusCastBar:SetPoint("BOTTOM", anchorSubFocusCastbar, "TOP", -1, 8.5)

    local focusCastBarScale = CreateSlider(contentFrame, L["Size"], 0.1, 1.9, 0.01, "focusCastBarScale")
    focusCastBarScale:SetPoint("TOP", anchorSubFocusCastbar, "BOTTOM", 0, -15)

    local focusCastBarXPos = CreateSlider(contentFrame, L["X_Offset"], -130, 130, 1, "focusCastBarXPos", "X")
    focusCastBarXPos:SetPoint("TOP", focusCastBarScale, "BOTTOM", 0, -15)

    local focusCastBarYPos = CreateSlider(contentFrame, L["Y_Offset"], -130, 130, 1, "focusCastBarYPos", "Y")
    focusCastBarYPos:SetPoint("TOP", focusCastBarXPos, "BOTTOM", 0, -15)

    local focusCastBarWidth = CreateSlider(contentFrame, L["Width"], 60, 220, 1, "focusCastBarWidth")
    focusCastBarWidth:SetPoint("TOP", focusCastBarYPos, "BOTTOM", 0, -15)

    local focusCastBarHeight = CreateSlider(contentFrame, L["Height"], 5, 30, 1, "focusCastBarHeight")
    focusCastBarHeight:SetPoint("TOP", focusCastBarWidth, "BOTTOM", 0, -15)

    local focusCastBarIconScale = CreateSlider(contentFrame, L["Icon_Size"], 0.4, 2, 0.01, "focusCastBarIconScale")
    focusCastBarIconScale:SetPoint("TOP", focusCastBarHeight, "BOTTOM", 0, -15)

    local focusCastbarIconXPos = CreateSlider(contentFrame, L["Icon_x_offset"], -160, 160, 1, "focusCastbarIconXPos", "X")
    focusCastbarIconXPos:SetPoint("TOP", focusCastBarIconScale, "BOTTOM", 0, -15)

    local focusCastbarIconYPos = CreateSlider(contentFrame, L["Icon_y_offset"], -160, 160, 1, "focusCastbarIconYPos", "Y")
    focusCastbarIconYPos:SetPoint("TOP", focusCastbarIconXPos, "BOTTOM", 0, -15)

    local focusStaticCastbar = CreateCheckbox("focusStaticCastbar", L["Static"], contentFrame)
    focusStaticCastbar:SetPoint("TOPLEFT", focusCastbarIconYPos, "BOTTOMLEFT", 10, -4)
    CreateTooltip(focusStaticCastbar, L["Tooltip_Castbar_Static"])

    local focusCastBarTimer = CreateCheckbox("focusCastBarTimer", L["Timer"], contentFrame, nil, BBF.CastBarTimerCaller)
    focusCastBarTimer:SetPoint("LEFT", focusStaticCastbar.Text, "RIGHT", 10, 0)
    CreateTooltip(focusCastBarTimer, L["Tooltip_Castbar_Timer"])

    local focusToTCastbarAdjustment = CreateCheckbox("focusToTCastbarAdjustment", L["ToT_Offset"], contentFrame)
    focusToTCastbarAdjustment:SetPoint("TOPLEFT", focusStaticCastbar, "BOTTOMLEFT", 0, pixelsBetweenBoxes)
    CreateTooltipTwo(focusToTCastbarAdjustment, L["Enable_ToT_Offset"], L["Tooltip_Castbar_ToT_Offset_Desc"])

    local focusToTAdjustmentOffsetY = CreateSlider(focusToTCastbarAdjustment, L["extra"], -20, 50, 1, "focusToTAdjustmentOffsetY", "Y", 55)
    focusToTAdjustmentOffsetY:SetPoint("LEFT", focusToTCastbarAdjustment.text, "RIGHT", 2, -5)
    CreateTooltipTwo(focusToTAdjustmentOffsetY, L["Tooltip_ToT_Adjustment_Offset_Y"], L["Tooltip_Castbar_ToT_Extra_Desc"])

    focusToTCastbarAdjustment:HookScript("OnClick", function(self)
        if self:GetChecked() then
            focusToTAdjustmentOffsetY:Enable()
            focusToTAdjustmentOffsetY:SetAlpha(1)
        else
            focusToTAdjustmentOffsetY:Disable()
            focusToTAdjustmentOffsetY:SetAlpha(0.5)
        end
    end)

    local focusDetachCastbar = CreateCheckbox("focusDetachCastbar", L["Castbar_Detach"], contentFrame)
    focusDetachCastbar:SetPoint("TOPLEFT", focusToTCastbarAdjustment, "BOTTOMLEFT", 0, pixelsBetweenBoxes)
    focusDetachCastbar:HookScript("OnClick", function(self)
        if self:GetChecked() then
            focusCastBarXPos:SetMinMaxValues(-900, 900)
            focusCastBarXPos:SetValue(0)
            focusCastBarYPos:SetMinMaxValues(-900, 900)
            focusCastBarYPos:SetValue(0)
            focusToTCastbarAdjustment:Disable()
            focusToTCastbarAdjustment:SetAlpha(0.5)
            focusToTAdjustmentOffsetY:Disable()
            focusToTAdjustmentOffsetY:SetAlpha(0.5)
            focusStaticCastbar:SetChecked(false)
            BetterBlizzFramesDB.focusStaticCastbar = false
        else
            focusCastBarXPos:SetMinMaxValues(-130, 130)
            focusCastBarXPos:SetValue(0)
            focusToTCastbarAdjustment:Enable()
            focusToTCastbarAdjustment:SetAlpha(1)
            focusToTAdjustmentOffsetY:Enable()
            focusToTAdjustmentOffsetY:SetAlpha(1)
        end
        BBF.ChangeCastbarSizes()
    end)
    CreateTooltip(focusDetachCastbar, L["Tooltip_Detach_From_Frame"])

    if BetterBlizzFramesDB.focusDetachCastbar then
        focusCastBarXPos:SetMinMaxValues(-900, 900)
        focusCastBarYPos:SetMinMaxValues(-900, 900)
        focusToTCastbarAdjustment:Disable()
        focusToTCastbarAdjustment:SetAlpha(0.5)
        focusToTAdjustmentOffsetY:Disable()
        focusToTAdjustmentOffsetY:SetAlpha(0.5)
        focusStaticCastbar:SetChecked(false)
        BetterBlizzFramesDB.focusStaticCastbar = false
    end
    focusStaticCastbar:HookScript("OnClick", function(self)
        if self:GetChecked() then
            focusToTCastbarAdjustment:Disable()
            focusToTCastbarAdjustment:SetAlpha(0.5)
            focusToTAdjustmentOffsetY:Disable()
            focusToTAdjustmentOffsetY:SetAlpha(0.5)
            focusDetachCastbar:SetChecked(false)
        else
            focusToTCastbarAdjustment:Enable()
            focusToTCastbarAdjustment:SetAlpha(1)
            focusToTAdjustmentOffsetY:Enable()
            focusToTAdjustmentOffsetY:SetAlpha(1)
        end
    end)
    if BetterBlizzFramesDB.focusStaticCastbar then
        focusToTCastbarAdjustment:Disable()
        focusToTCastbarAdjustment:SetAlpha(0.5)
        focusToTAdjustmentOffsetY:Disable()
        focusToTAdjustmentOffsetY:SetAlpha(0.5)
        focusDetachCastbar:SetChecked(false)
        BetterBlizzFramesDB.focusDetachCastbar = false
    end

    local hideFocusCastbar = CreateCheckbox("hideFocusCastbar", L["Hide_Bar"], contentFrame, nil, BBF.ChangeCastbarSizes)
    hideFocusCastbar:SetPoint("TOPLEFT", focusDetachCastbar, "BOTTOMLEFT", 0, pixelsBetweenBoxes)
    CreateTooltipTwo(hideFocusCastbar, L["Hide_Bar"], L["Tooltip_Hide_Focus_Castbar"])

    local hideFocusCastbarIcon = CreateCheckbox("hideFocusCastbarIcon", L["Hide_Icon"], contentFrame, nil, BBF.ChangeCastbarSizes)
    hideFocusCastbarIcon:SetPoint("LEFT", hideFocusCastbar.text, "RIGHT", 0, 0)
    CreateTooltipTwo(hideFocusCastbarIcon, L["Hide_Icon"], L["Tooltip_Hide_Focus_Castbar_Icon"])

    local resetFocusCastbar = CreateFrame("Button", nil, contentFrame, "UIPanelButtonTemplate")
    resetFocusCastbar:SetText(L["Reset"])
    resetFocusCastbar:SetWidth(70)
    resetFocusCastbar:SetPoint("TOP", focusCastbarBorder, "BOTTOM", 0, -2)
    resetFocusCastbar:SetScript("OnClick", function()
        focusCastBarScale:SetValue(1)
        focusCastBarIconScale:SetValue(1)
        focusCastBarXPos:SetValue(0)
        focusCastBarYPos:SetValue(0)
        focusCastbarIconXPos:SetValue(0)
        focusCastbarIconYPos:SetValue(0)
        focusCastBarWidth:SetValue(150)
        focusCastBarHeight:SetValue(10)
        focusCastBarTimer:SetChecked(false)
        BetterBlizzFramesDB.focusCastBarTimer = false
        focusStaticCastbar:SetChecked(false)
        BetterBlizzFramesDB.focusStaticCastbar = false
        focusDetachCastbar:SetChecked(false)
        BetterBlizzFramesDB.focusDetachCastbar = false
        focusToTCastbarAdjustment:Enable()
        focusToTCastbarAdjustment:SetAlpha(1)
        focusToTCastbarAdjustment:SetChecked(true)
        focusToTAdjustmentOffsetY:Enable()
        focusToTAdjustmentOffsetY:SetValue(0)
        BetterBlizzFramesDB.focusToTCastbarAdjustment = true
        BBF.CastBarTimerCaller()
        BBF.ChangeCastbarSizes()
    end)


   ----------------------
    -- Player Castbar
    ----------------------
    local anchorSubPlayerCastbar = contentFrame:CreateFontString(nil, "OVERLAY", "GameFontNormal")
    anchorSubPlayerCastbar:SetPoint("CENTER", mainGuiAnchor2, "CENTER", firstLineX, firstLineY)
    anchorSubPlayerCastbar:SetText(L["Player_Castbar"])

    local playerCastbarBorder = CreateBorderedFrame(anchorSubPlayerCastbar, 157, 450, 0, -77, contentFrame)

    local playerCastBar = contentFrame:CreateTexture(nil, "ARTWORK")
    playerCastBar:SetAtlas("ui-castingbar-filling-standard")
    playerCastBar:SetSize(110, 13)
    playerCastBar:SetPoint("BOTTOM", anchorSubPlayerCastbar, "TOP", -1, 10)


    local playerCastBarScale = CreateSlider(contentFrame, L["Size"], 0.1, 1.9, 0.01, "playerCastBarScale")
    playerCastBarScale:SetPoint("TOP", anchorSubPlayerCastbar, "BOTTOM", 0, -15)

    local playerCastbarIconXPos = CreateSlider(contentFrame, L["X_Offset"], -200, 200, 1, "playerCastbarIconXPos", "X")
    playerCastbarIconXPos:SetPoint("TOP", playerCastBarScale, "BOTTOM", 0, -15)

    local playerCastbarIconYPos = CreateSlider(contentFrame, L["Y_Offset"], -200, 200, 1, "playerCastbarIconYPos", "Y")
    playerCastbarIconYPos:SetPoint("TOP", playerCastbarIconXPos, "BOTTOM", 0, -15)

    local playerCastBarIconScale = CreateSlider(contentFrame, L["Icon_Size"], 0.4, 2, 0.01, "playerCastBarIconScale")
    playerCastBarIconScale:SetPoint("TOP", playerCastbarIconYPos, "BOTTOM", 0, -15)

    local playerCastBarWidth = CreateSlider(contentFrame, L["Width"], 60, 230, 1, "playerCastBarWidth")
    --playerCastBarWidth:SetPoint("TOP", playerCastBarYPos, "BOTTOM", 0, -15)
    playerCastBarWidth:SetPoint("TOP", playerCastBarIconScale, "BOTTOM", 0, -15)

    local playerCastBarHeight = CreateSlider(contentFrame, L["Height"], 5, 30, 1, "playerCastBarHeight")
    playerCastBarHeight:SetPoint("TOP", playerCastBarWidth, "BOTTOM", 0, -15)

    local playerCastBarShowIcon = CreateCheckbox("playerCastBarShowIcon", L["Icon"], contentFrame, nil, BBF.ShowPlayerCastBarIcon)
    playerCastBarShowIcon:SetPoint("TOPLEFT", playerCastBarHeight, "BOTTOMLEFT", 10, -4)
    CreateTooltip(playerCastBarShowIcon, L["Tooltip_Player_Castbar_Icon"])

    local playerCastBarTimer = CreateCheckbox("playerCastBarTimer", L["Timer"], contentFrame, nil, BBF.CastBarTimerCaller)
    playerCastBarTimer:SetPoint("LEFT", playerCastBarShowIcon.Text, "RIGHT", 7, 0)
    CreateTooltip(playerCastBarTimer, L["Tooltip_Castbar_Timer"])

    local playerCastBarTimerCentered = CreateCheckbox("playerCastBarTimerCentered", L["Center"], contentFrame, nil, BBF.CastBarTimerCaller)
    --playerStaticCastbar:SetPoint("TOPLEFT", playerCastBarIconScale, "BOTTOMLEFT", 10, -4)
    playerCastBarTimerCentered:SetPoint("LEFT", playerCastBarTimer.Text, "RIGHT", 2, 0)
    CreateTooltip(playerCastBarTimerCentered, L["Tooltip_Player_Castbar_Timer_Center"])

    local playerCastBarNoTextBorder = CreateCheckbox("playerCastBarNoTextBorder", L["Player_Castbar_Simple"], contentFrame, nil, BBF.ChangeCastbarSizes)
    --playerStaticCastbar:SetPoint("TOPLEFT", playerCastBarIconScale, "BOTTOMLEFT", 10, -4)
    playerCastBarNoTextBorder:SetPoint("TOPLEFT", playerCastBarShowIcon, "BOTTOMLEFT", 0, pixelsBetweenBoxes)
    CreateTooltipTwo(playerCastBarNoTextBorder, L["Player_Castbar_Simple"], L["Tooltip_Player_Castbar_Simple_Desc"])

    local classicCastbarsPlayer = CreateCheckbox("classicCastbarsPlayer", L["Classic_Castbar"], contentFrame, nil, BBF.ChangeCastbarSizes)
    classicCastbarsPlayer:SetPoint("TOPLEFT", playerCastBarNoTextBorder, "BOTTOMLEFT", -15, pixelsBetweenBoxes)
    CreateTooltipTwo(classicCastbarsPlayer, L["Classic_Castbar"], L["Tooltip_Classic_Castbar_Desc"])

    local hidePlayerCastbar = CreateCheckbox("hidePlayerCastbar", L["Hide_Bar"], contentFrame, nil, BBF.ChangeCastbarSizes)
    hidePlayerCastbar:SetPoint("TOPLEFT", classicCastbarsPlayer, "BOTTOMLEFT", 0, pixelsBetweenBoxes)
    CreateTooltipTwo(hidePlayerCastbar, L["Hide_Player_Castbar"], L["Hide_Player_Castbar"])

    local hidePlayerCastbarIcon = CreateCheckbox("hidePlayerCastbarIcon", L["Hide_Icon"], contentFrame, nil, BBF.ChangeCastbarSizes)
    hidePlayerCastbarIcon:SetPoint("LEFT", hidePlayerCastbar.text, "RIGHT", 0, 0)
    CreateTooltipTwo(hidePlayerCastbarIcon, L["Hide_Player_Castbar_Icon"], L["Hide_Player_Castbar_Icon"])
    hidePlayerCastbar:HookScript("OnClick", function(self)
        if not self:GetChecked() then
            StaticPopup_Show("BBF_CONFIRM_RELOAD")
        end
    end)

    local classicCastbarsPlayerBorder = CreateCheckbox("classicCastbarsPlayerBorder", L["Border"], classicCastbarsPlayer, nil, BBF.ChangeCastbarSizes)
    classicCastbarsPlayerBorder:SetPoint("LEFT", classicCastbarsPlayer.text, "RIGHT", 0, 0)
    CreateTooltipTwo(classicCastbarsPlayerBorder, L["Classic_Border"], L["Tooltip_Classic_Border_Desc"])

    classicCastbarsPlayer:HookScript("OnClick", function(self)
        CheckAndToggleCheckboxes(self)
        if self:GetChecked() then
            BetterBlizzFramesDB.castbarPixelBorder = nil
        end
        StaticPopup_Show("BBF_CONFIRM_RELOAD")
    end)

    local resetPlayerCastbar = CreateFrame("Button", nil, contentFrame, "UIPanelButtonTemplate")
    resetPlayerCastbar:SetText(L["Reset"])
    resetPlayerCastbar:SetWidth(70)
    resetPlayerCastbar:SetPoint("TOP", playerCastbarBorder, "BOTTOM", 0, -2)
    resetPlayerCastbar:SetScript("OnClick", function()
        playerCastbarIconXPos:SetValue(0)
        playerCastbarIconYPos:SetValue(0)
        playerCastBarScale:SetValue(1)
        playerCastBarIconScale:SetValue(1)
        playerCastBarWidth:SetValue(208)
        playerCastBarHeight:SetValue(11)
        playerCastBarShowIcon:SetChecked(false)
        playerCastBarTimer:SetChecked(false)
        playerCastBarTimerCentered:SetChecked(false)
        BetterBlizzFramesDB.playerCastBarShowIcon = false
        BetterBlizzFramesDB.playerCastBarTimer = false
        BetterBlizzFramesDB.playerStaticCastbar = false
        BetterBlizzFramesDB.playerCastBarTimerCentered = false
        --PlayerCastingBarFrame.showShield = false
        BBF.CastBarTimerCaller()
        BBF.ShowPlayerCastBarIcon()
        BBF.ChangeCastbarSizes()
    end)

    local function UpdateColorSquare(icon, r, g, b, a)
        if r and g and b and a then
            icon:SetVertexColor(r, g, b, a)
        else
            icon:SetVertexColor(r, g, b)
        end
    end

    local function OpenColorPicker(colorType, icon)
        -- Ensure originalColorData has four elements, defaulting alpha (a) to 1 if not present
        local originalColorData = BetterBlizzFramesDB[colorType] or {1, 1, 1, 1}
        if #originalColorData == 3 then
            table.insert(originalColorData, 1) -- Add default alpha value if not present
        end
        local r, g, b, a = unpack(originalColorData)

        local function updateColors()
            UpdateColorSquare(icon, r, g, b, a)
            ColorPickerFrame.Content.ColorSwatchCurrent:SetAlpha(a)
        end

        local function swatchFunc()
            r, g, b = ColorPickerFrame:GetColorRGB()
            BetterBlizzFramesDB[colorType] = {r, g, b, a}
            updateColors()
        end

        local function opacityFunc()
            a = ColorPickerFrame:GetColorAlpha()
            BetterBlizzFramesDB[colorType] = {r, g, b, a}
            updateColors()
        end

        local function cancelFunc()
            r, g, b, a = unpack(originalColorData)
            BetterBlizzFramesDB[colorType] = {r, g, b, a}
            updateColors()
        end

        ColorPickerFrame:SetupColorPickerAndShow({
            r = r, g = g, b = b, opacity = a, hasOpacity = true,
            swatchFunc = swatchFunc, opacityFunc = opacityFunc, cancelFunc = cancelFunc
        })
    end



    local castBarRecolorInterrupt = CreateCheckbox("castBarRecolorInterrupt", L["Interrupt_CD_Color"], contentFrame, nil, BBF.UpdateInterruptIconSettings)
    castBarRecolorInterrupt:SetPoint("LEFT", contentFrame, "TOPRIGHT", -455, -449)
    CreateTooltipTwo(castBarRecolorInterrupt, L["Interrupt_CD_Color"], L["Tooltip_Interrupt_CD_Color_Desc"])

    local castBarRecolorInterruptArenaFrames = CreateCheckbox("castBarRecolorInterruptArenaFrames", L["Arena"], contentFrame, nil, BBF.UpdateInterruptIconSettings)
    castBarRecolorInterruptArenaFrames:SetPoint("LEFT", castBarRecolorInterrupt.Text, "RIGHT", 0, 0)
    CreateTooltipTwo(castBarRecolorInterruptArenaFrames, L["Interrupt_CD_Color_Arena_Frames"], L["Tooltip_Interrupt_CD_Color_Arena_Frames_Desc"])

    local castBarInterruptIconEnabled = CreateCheckbox("castBarInterruptIconEnabled", L["Interrupt_CD_Icon"], contentFrame, nil, BBF.UpdateInterruptIconSettings)
    castBarInterruptIconEnabled:SetPoint("BOTTOMLEFT", castBarRecolorInterrupt, "TOPLEFT", 0, -pixelsBetweenBoxes)
    CreateTooltipTwo(castBarInterruptIconEnabled, L["Interrupt_CD_Icon"], L["Tooltip_Interrupt_CD_Icon_Desc"], L["Tooltip_Interrupt_CD_Icon_Extra"])

    local castBarNoInterruptColor = CreateFrame("Button", nil, castBarRecolorInterrupt, "UIPanelButtonTemplate")
    castBarNoInterruptColor:SetText(L["Interrupt_On_CD"])
    castBarNoInterruptColor:SetPoint("TOPLEFT", castBarRecolorInterrupt, "BOTTOMRIGHT", -35, 3)
    castBarNoInterruptColor:SetSize(139, 20)
    CreateTooltip(castBarNoInterruptColor, L["Tooltip_Interrupt_On_CD"])
    local castBarNoInterruptColorIcon = contentFrame:CreateTexture(nil, "ARTWORK")
    castBarNoInterruptColorIcon:SetAtlas("newplayertutorial-icon-key")
    castBarNoInterruptColorIcon:SetSize(18, 17)
    castBarNoInterruptColorIcon:SetPoint("LEFT", castBarNoInterruptColor, "RIGHT", 0, -1)
    UpdateColorSquare(castBarNoInterruptColorIcon, unpack(BetterBlizzFramesDB["castBarNoInterruptColor"] or {1, 1, 1}))
    castBarNoInterruptColor:SetScript("OnClick", function()
        OpenColorPicker("castBarNoInterruptColor", castBarNoInterruptColorIcon)
    end)

    local castBarDelayedInterruptColor = CreateFrame("Button", nil, castBarRecolorInterrupt, "UIPanelButtonTemplate")
    castBarDelayedInterruptColor:SetText(L["Interrupt_CD_Soon"])
    castBarDelayedInterruptColor:SetPoint("TOPLEFT", castBarNoInterruptColor, "BOTTOMLEFT", 0, -5)
    castBarDelayedInterruptColor:SetSize(139, 20)
    CreateTooltip(castBarDelayedInterruptColor, L["Tooltip_Interrupt_CD_Soon"])
    local castBarDelayedInterruptColorIcon = contentFrame:CreateTexture(nil, "ARTWORK")
    castBarDelayedInterruptColorIcon:SetAtlas("newplayertutorial-icon-key")
    castBarDelayedInterruptColorIcon:SetSize(18, 17)
    castBarDelayedInterruptColorIcon:SetPoint("LEFT", castBarDelayedInterruptColor, "RIGHT", 0, -1)
    UpdateColorSquare(castBarDelayedInterruptColorIcon, unpack(BetterBlizzFramesDB["castBarDelayedInterruptColor"] or {1, 1, 1}))
    castBarDelayedInterruptColor:SetScript("OnClick", function()
        OpenColorPicker("castBarDelayedInterruptColor", castBarDelayedInterruptColorIcon)
    end)


    local buffsOnTopReverseCastbarMovement = CreateCheckbox("buffsOnTopReverseCastbarMovement", L["Buffs_On_Top_Reverse"], contentFrame, nil, BBF.CastbarAdjustCaller)
    buffsOnTopReverseCastbarMovement:SetPoint("LEFT", contentFrame, "TOPRIGHT", -470, -517)
    CreateTooltipTwo(buffsOnTopReverseCastbarMovement, L["Buffs_On_Top_Reverse"], L["Tooltip_Buffs_On_Top_Reverse_Desc"])

    local normalCastbarForEmpoweredCasts = CreateCheckbox("normalCastbarForEmpoweredCasts", L["Normal_Evoker_Castbar"], contentFrame, nil, BBF.HookCastbarsForEvoker)
    normalCastbarForEmpoweredCasts:SetPoint("TOPLEFT", buffsOnTopReverseCastbarMovement, "BOTTOMLEFT", 0, pixelsBetweenBoxes)
    CreateTooltipTwo(normalCastbarForEmpoweredCasts, L["Normal_Evoker_Castbar"], L["Tooltip_Normal_Evoker_Castbar_Desc"])
    normalCastbarForEmpoweredCasts:HookScript("OnClick", function(self)
        if BetterBlizzPlatesDB then
            if self:GetChecked() then
                BetterBlizzPlatesDB.normalCastbarForEmpoweredCasts = true
            else
                BetterBlizzPlatesDB.normalCastbarForEmpoweredCasts = false
            end
        end
    end)

    local quickHideCastbars = CreateCheckbox("quickHideCastbars", L["Quick_Hide_Castbars"], contentFrame)
    quickHideCastbars:SetPoint("TOPLEFT", normalCastbarForEmpoweredCasts, "BOTTOMLEFT", 0, pixelsBetweenBoxes)
    CreateTooltipTwo(quickHideCastbars, L["Quick_Hide_Castbars"], L["Tooltip_Quick_Hide_Castbars_Desc"])
    quickHideCastbars:HookScript("OnClick", function()
        StaticPopup_Show("BBF_CONFIRM_RELOAD")
    end)

    local classicCastbars = CreateCheckbox("classicCastbars", L["Castbar_Classic"], contentFrame, nil, BBF.ChangeCastbarSizes)
    classicCastbars:SetPoint("TOPLEFT", quickHideCastbars, "BOTTOMLEFT", 0, pixelsBetweenBoxes)
    CreateTooltipTwo(classicCastbars, L["Castbar_Classic"], L["Tooltip_Castbar_Classic_Target_Focus_Desc"])
    classicCastbars:HookScript("OnClick", function(self)
        if self:GetChecked() then
            BetterBlizzFramesDB.castbarPixelBorder = nil
        end
        StaticPopup_Show("BBF_CONFIRM_RELOAD")
    end)

    local classicCastbarsModernSpark = CreateCheckbox("classicCastbarsModernSpark", L["Modern_Spark"], contentFrame, nil, BBF.ChangeCastbarSizes)
    classicCastbarsModernSpark:SetPoint("LEFT", classicCastbars.text, "RIGHT", 0, 0)
    CreateTooltipTwo(classicCastbarsModernSpark, L["Modern_Spark"], L["Tooltip_Modern_Spark_Desc"])
    classicCastbarsModernSpark:HookScript("OnClick", function(self)
        StaticPopup_Show("BBF_CONFIRM_RELOAD")
    end)

    local unitframeCastBarNoTextBorder = CreateCheckbox("unitframeCastBarNoTextBorder", L["UnitFrame_Simple_Castbars"], contentFrame, nil, BBF.ChangeCastbarSizes)
    unitframeCastBarNoTextBorder:SetPoint("TOPLEFT", classicCastbars, "BOTTOMLEFT", 0, pixelsBetweenBoxes)
    CreateTooltipTwo(unitframeCastBarNoTextBorder, L["UnitFrame_Simple_Castbars"], L["Tooltip_UnitFrame_Simple_Castbars_Desc"])
    unitframeCastBarNoTextBorder:HookScript("OnClick", function()
        if classicCastbars:GetChecked() then
            BetterBlizzFrames.classicCastbars = nil
            classicCastbars:SetChecked(false)
            StaticPopup_Show("BBF_CONFIRM_RELOAD")
        end
        if anchorSubPartyCastbar.classicCastbarsParty:GetChecked() then
            anchorSubPartyCastbar.classicCastbarsParty:SetChecked(false)
            BetterBlizzFrames.classicCastbarsParty = nil
            StaticPopup_Show("BBF_CONFIRM_RELOAD")
        end
    end)

    local castbarPixelBorder = CreateCheckbox("castbarPixelBorder", L["Pixel_Border_Castbars"], contentFrame, nil, BBF.ChangeCastbarSizes)
    castbarPixelBorder:SetPoint("LEFT", unitframeCastBarNoTextBorder.text, "RIGHT", 0, 0)
    CreateTooltipTwo(castbarPixelBorder, L["Pixel_Border_Castbars"], L["Tooltip_Pixel_Border_Castbars_Desc"])

    local castbarPixelBorderTextInside = CreateCheckbox("castbarPixelBorderTextInside", L["Pixel_Border_Castbars_Text_Inside"], castbarPixelBorder, nil, BBF.ChangeCastbarSizes)
    castbarPixelBorderTextInside:SetPoint("LEFT", castbarPixelBorder.text, "RIGHT", 0, 0)
    CreateTooltipTwo(castbarPixelBorderTextInside, L["Pixel_Border_Castbars_Text_Inside"], L["Tooltip_Pixel_Border_Castbars_Text_Inside_Desc"])

    castbarPixelBorder:HookScript("OnClick", function(self)
        if self:GetChecked() then
            BetterBlizzFramesDB.classicCastbars = nil
            BetterBlizzFramesDB.classicCastbarsPlayer = nil
        end
        EnableElement(castbarPixelBorderTextInside)
        StaticPopup_Show("BBF_CONFIRM_RELOAD")
    end)


    classicCastbars:HookScript("OnClick", function(self)
        if not self:GetChecked() then
            StaticPopup_Show("BBF_CONFIRM_RELOAD")
            DisableElement(classicCastbarsModernSpark)
        else
            EnableElement(classicCastbarsModernSpark)
        end
        if unitframeCastBarNoTextBorder:GetChecked() then
            BetterBlizzFrames.unitframeCastBarNoTextBorder = nil
            unitframeCastBarNoTextBorder:SetChecked(false)
        end
    end)

    if not BetterBlizzFramesDB.classicCastbars then
        DisableElement(classicCastbarsModernSpark)
    end

    local recolorCastbars = CreateCheckbox("recolorCastbars", L["Recolor_Castbars"], contentFrame)
    recolorCastbars:SetPoint("TOPLEFT", unitframeCastBarNoTextBorder, "BOTTOMLEFT", 0, pixelsBetweenBoxes)
    CreateTooltipTwo(recolorCastbars, L["Recolor_Castbars"], L["Tooltip_Recolor_Castbars_Desc"])

    local castbarCastColor = CreateColorBox(recolorCastbars, "castbarCastColor", L["Cast"])
    castbarCastColor:SetPoint("LEFT", recolorCastbars.text, "RIGHT", 0, 0)

    local castbarChannelColor = CreateColorBox(recolorCastbars, "castbarChannelColor", L["Channel"])
    castbarChannelColor:SetPoint("LEFT", castbarCastColor.text, "RIGHT", 0, 0)

    local castbarUninterruptableColor = CreateColorBox(recolorCastbars, "castbarUninterruptableColor", L["Uninterruptable"])
    castbarUninterruptableColor:SetPoint("LEFT", castbarChannelColor.text, "RIGHT", 0, 0)

    recolorCastbars:HookScript("OnClick", function(self)
        local enable = self:GetChecked() and 1 or 0.5
        castbarCastColor:SetAlpha(enable)
        castbarChannelColor:SetAlpha(enable)
        castbarUninterruptableColor:SetAlpha(enable)
        BBF.CastbarRecolorWidgets()
        StaticPopup_Show("BBF_CONFIRM_RELOAD")
    end)

    BetterBlizzFramesCastbars.rightClickTip = BetterBlizzFramesCastbars:CreateFontString(nil, "OVERLAY", "GameFontNormalLarge")
    BetterBlizzFramesCastbars.rightClickTip:SetPoint("BOTTOMLEFT", bgImg, "BOTTOM", -231, -36)
    BetterBlizzFramesCastbars.rightClickTip:SetText("|A:smallquestbang:20:20|a" .. L["Right_Click_Slider_Tip"])
end

local function guiPositionAndScale()

    ----------------------
    -- Advanced settings
    ----------------------
    local firstLineX = 53
    local firstLineY = -65
    local secondLineX = 222
    local secondLineY = -360
    local thirdLineX = 391
    local thirdLineY = -655
    local fourthLineX = 560

    local BetterBlizzFramesSubPanel = CreateFrame("Frame")
    BetterBlizzFramesSubPanel.name = L["Module_Name_Advanced"]
    BetterBlizzFramesSubPanel.parent = BetterBlizzFrames.name
    --InterfaceOptions_AddCategory(BetterBlizzFramesSubPanel)
    local advancedSubCategory = Settings.RegisterCanvasLayoutSubcategory(BBF.category, BetterBlizzFramesSubPanel, BetterBlizzFramesSubPanel.name, BetterBlizzFramesSubPanel.name)
    advancedSubCategory.ID = BetterBlizzFramesSubPanel.name;
    BBF.category.AdvancedSettings = BetterBlizzFramesSubPanel.name
    CreateTitle(BetterBlizzFramesSubPanel)

    local bgImg = BetterBlizzFramesSubPanel:CreateTexture(nil, "BACKGROUND")
    bgImg:SetAtlas("professions-recipe-background")
    bgImg:SetPoint("CENTER", BetterBlizzFramesSubPanel, "CENTER", -8, 4)
    bgImg:SetSize(680, 610)
    bgImg:SetAlpha(0.4)
    bgImg:SetVertexColor(0,0,0)





    local scrollFrame = CreateFrame("ScrollFrame", nil, BetterBlizzFramesSubPanel, "UIPanelScrollFrameTemplate")
    scrollFrame:SetSize(700, 612)
    scrollFrame:SetPoint("CENTER", BetterBlizzFramesSubPanel, "CENTER", -20, 3)

    local contentFrame = CreateFrame("Frame", nil, scrollFrame)
    contentFrame.name = BetterBlizzFramesSubPanel.name
    contentFrame:SetSize(680, 520)
    scrollFrame:SetScrollChild(contentFrame)

    local mainGuiAnchor2 = contentFrame:CreateFontString(nil, "OVERLAY", "GameFontNormal")
    mainGuiAnchor2:SetPoint("TOPLEFT", 55, 20)
    mainGuiAnchor2:SetText(" ")

 --[[
    ----------------------
    -- Focus Target
    ----------------------
    local anchorFocusTarget = contentFrame:CreateFontString(nil, "OVERLAY", "GameFontNormal")
    anchorFocusTarget:SetPoint("CENTER", mainGuiAnchor2, "CENTER", secondLineX, firstLineY)
    anchorFocusTarget:SetText(L["Focus_ToT"])

    CreateBorderBox(anchorFocusTarget)

    local focusTargetFrameIcon = contentFrame:CreateTexture(nil, "ARTWORK")
    focusTargetFrameIcon:SetAtlas("greencross")
    focusTargetFrameIcon:SetSize(32, 32)
    focusTargetFrameIcon:SetPoint("BOTTOM", anchorFocusTarget, "TOP", 0, 0)
    focusTargetFrameIcon:SetTexCoord(0.1953125, 0.8046875, 0.1953125, 0.8046875)

    local focusToTScale = CreateSlider(contentFrame, L["Size"], 0.1, 1.9, 0.1, "focusToTScale")
    focusToTScale:SetPoint("TOP", anchorFocusTarget, "BOTTOM", 0, -15)

    local focusToTXPos = CreateSlider(contentFrame, L["X_Offset"], -100, 100, 1, "focusToTXPos", "X")
    focusToTXPos:SetPoint("TOP", focusToTScale, "BOTTOM", 0, -15)

    local focusToTYPos = CreateSlider(contentFrame, L["Y_Offset"], -100, 100, 1, "focusToTYPos", "Y")
    focusToTYPos:SetPoint("TOP", focusToTXPos, "BOTTOM", 0, -15)

    local focusToTDropdown = CreateAnchorDropdown(
        "focusToTDropdown",
        contentFrame,
        L["Select_Anchor_Point"],
        "focusToTAnchor",
        function(arg1) 
            BBF.MoveToTFrames()
        end,
        { anchorFrame = focusToTYPos, x = -16, y = -35, label = L["Anchor"] }
    )

    local combatIndicatorEnemyOnly = CreateCheckbox("combatIndicatorEnemyOnly", L["Enemies_Only"], contentFrame)
    combatIndicatorEnemyOnly:SetPoint("TOPLEFT", focusToTDropdown, "BOTTOMLEFT", 16, pixelsBetweenBoxes)
 
 ]]
 


 --[[
    ----------------------
    -- Pet Frame
    ----------------------
    local anchorPetFrame = contentFrame:CreateFontString(nil, "OVERLAY", "GameFontNormal")
    anchorPetFrame:SetPoint("CENTER", mainGuiAnchor2, "CENTER", thirdLineX, firstLineY)
    anchorPetFrame:SetText(L["Pet_Frame"])

    CreateBorderBox(anchorPetFrame)

    local partyFrameIcon = contentFrame:CreateTexture(nil, "ARTWORK")
    partyFrameIcon:SetAtlas("greencross")
    partyFrameIcon:SetSize(32, 32)
    partyFrameIcon:SetPoint("BOTTOM", anchorPetFrame, "TOP", 0, 0)
    partyFrameIcon:SetTexCoord(0.1953125, 0.8046875, 0.1953125, 0.8046875)

    local petFrameScale = CreateSlider(contentFrame, L["Size"], 0.1, 1.9, 0.1, "petFrameScale")
    petFrameScale:SetPoint("TOP", anchorPetFrame, "BOTTOM", 0, -15)

    local petFrameXPos = CreateSlider(contentFrame, L["X_Offset"], -100, 100, 1, "petFrameXPos", "X")
    petFrameXPos:SetPoint("TOP", petFrameScale, "BOTTOM", 0, -15)

    local petFrameYPos = CreateSlider(contentFrame, L["Y_Offset"], -100, 100, 1, "petFrameYPos", "Y")
    petFrameYPos:SetPoint("TOP", petFrameXPos, "BOTTOM", 0, -15)

    local petFrameDropdown = CreateAnchorDropdown(
        "petFrameDropdown",
        contentFrame,
        L["Select_Anchor_Point"],
        "petFrameAnchor",
        function(arg1) 
            BBF.MoveToTFrames()
        end,
        { anchorFrame = petFrameYPos, x = -16, y = -35, label = L["Anchor"] }
    )
 
 ]]
 



   ----------------------
    -- Absorb Indicator
    ----------------------
    local anchorSubAbsorb = contentFrame:CreateFontString(nil, "OVERLAY", "GameFontNormal")
    anchorSubAbsorb:SetPoint("CENTER", mainGuiAnchor2, "CENTER", fourthLineX - 30, firstLineY)
    anchorSubAbsorb:SetText(L["Absorb_Indicator"])

    --CreateBorderBox(anchorSubAbsorb)
    CreateBorderedFrame(anchorSubAbsorb, 200, 293, 0, -98, BetterBlizzFramesSubPanel)

    local absorbIndicator = contentFrame:CreateTexture(nil, "ARTWORK")
    absorbIndicator:SetAtlas("ParagonReputation_Glow")
    absorbIndicator:SetSize(56, 56)
    absorbIndicator:SetPoint("BOTTOM", anchorSubAbsorb, "TOP", -1, -10)
    CreateTooltip(absorbIndicator, L["Tooltip_Absorb_Indicator"])

    local absorbIndicatorScale = CreateSlider(contentFrame, L["Size"], 0.1, 1.9, 0.01, "absorbIndicatorScale")
    absorbIndicatorScale:SetPoint("TOP", anchorSubAbsorb, "BOTTOM", 0, -15)

    local absorbIndicatorXPos = CreateSlider(contentFrame, L["X_Offset"], -100, 100, 1, "playerAbsorbXPos", "X")
    absorbIndicatorXPos:SetPoint("TOP", absorbIndicatorScale, "BOTTOM", 0, -15)

    local absorbIndicatorYPos = CreateSlider(contentFrame, L["Y_Offset"], -100, 100, 1, "playerAbsorbYPos", "Y")
    absorbIndicatorYPos:SetPoint("TOP", absorbIndicatorXPos, "BOTTOM", 0, -15)

    local playerAbsorbAnchorDropdown = CreateAnchorDropdown(
        "playerAbsorbAnchorDropdown",
        contentFrame,
        L["Select_Anchor_Point"],
        "playerAbsorbAnchor",
        function(arg1)
        BBF.AbsorbCaller()
    end,
        { anchorFrame = absorbIndicatorYPos, x = -16, y = -35, label = L["Anchor"] }
    )

    local absorbIndicatorTestMode = CreateCheckbox("absorbIndicatorTestMode", L["Test"], contentFrame, nil, BBF.AbsorbCaller)
    absorbIndicatorTestMode:SetPoint("TOPLEFT", playerAbsorbAnchorDropdown, "BOTTOMLEFT", 10, pixelsBetweenBoxes)

    local absorbIndicatorFlipIconText = CreateCheckbox("absorbIndicatorFlipIconText", L["Flip_Icon_Text"], contentFrame, nil, BBF.AbsorbCaller)
    absorbIndicatorFlipIconText:SetPoint("LEFT", absorbIndicatorTestMode.text, "RIGHT", 5, 0)




--[[
    local absorbIndicatorEnemyOnly = CreateCheckbox("absorbIndicatorEnemyOnly", L["Enemy_Only"], contentFrame)
    absorbIndicatorEnemyOnly:SetPoint("TOPLEFT", absorbIndicatorTestMode, "BOTTOMLEFT", 0, pixelsBetweenBoxes)

    local absorbIndicatorOnPlayersOnly = CreateCheckbox("absorbIndicatorOnPlayersOnly", L["Players_Only"], contentFrame)
    absorbIndicatorOnPlayersOnly:SetPoint("TOPLEFT", absorbIndicatorEnemyOnly, "BOTTOMLEFT", 0, pixelsBetweenBoxes)

]]


    --
    local playerAbsorbAmount = CreateCheckbox("playerAbsorbAmount", L["Player"], contentFrame, nil, BBF.AbsorbCaller)
    playerAbsorbAmount:SetPoint("TOPLEFT", absorbIndicatorTestMode, "BOTTOMLEFT", -5, -14)
    CreateTooltip(playerAbsorbAmount, L["Tooltip_Absorb_Show_Player"])

    local playerAbsorbIcon = CreateCheckbox("playerAbsorbIcon", L["Icon"], contentFrame, nil, BBF.AbsorbCaller)
    playerAbsorbIcon:SetPoint("TOPLEFT", playerAbsorbAmount, "BOTTOMLEFT", 0, pixelsBetweenBoxes)
    CreateTooltip(playerAbsorbIcon, L["Tooltip_Absorb_Icon"])

    local targetAbsorbAmount = CreateCheckbox("targetAbsorbAmount", L["Target"], contentFrame, nil, BBF.AbsorbCaller)
    targetAbsorbAmount:SetPoint("LEFT", playerAbsorbAmount.Text, "RIGHT", 5, 0)
    CreateTooltip(targetAbsorbAmount, L["Tooltip_Absorb_Show_Target"])

    local targetAbsorbIcon = CreateCheckbox("targetAbsorbIcon", L["Icon"], contentFrame, nil, BBF.AbsorbCaller)
    targetAbsorbIcon:SetPoint("TOPLEFT", targetAbsorbAmount, "BOTTOMLEFT", 0, pixelsBetweenBoxes)
    CreateTooltip(targetAbsorbIcon, L["Tooltip_Absorb_Icon"])

    local focusAbsorbAmount = CreateCheckbox("focusAbsorbAmount", L["Focus"], contentFrame, nil, BBF.AbsorbCaller)
    focusAbsorbAmount:SetPoint("LEFT", targetAbsorbAmount.Text, "RIGHT", 5, 0)
    CreateTooltip(focusAbsorbAmount, L["Tooltip_Absorb_Show_Focus"])

    local focusAbsorbIcon = CreateCheckbox("focusAbsorbIcon", L["Icon"], contentFrame, nil, BBF.AbsorbCaller)
    focusAbsorbIcon:SetPoint("TOPLEFT", focusAbsorbAmount, "BOTTOMLEFT", 0, pixelsBetweenBoxes)
    CreateTooltip(focusAbsorbIcon, L["Tooltip_Absorb_Icon"])










    --------------------------
    -- Combat indicator
    ----------------------
    local anchorSubOutOfCombat = contentFrame:CreateFontString(nil, "OVERLAY", "GameFontNormal")
    anchorSubOutOfCombat:SetPoint("CENTER", mainGuiAnchor2, "CENTER", secondLineX-145, firstLineY)
    anchorSubOutOfCombat:SetText(L["Combat_Indicator"])

    --CreateBorderBox(anchorSubOutOfCombat)
    CreateBorderedFrame(anchorSubOutOfCombat, 200, 293, 0, -98, BetterBlizzFramesSubPanel)

    local combatIconSub = contentFrame:CreateTexture(nil, "ARTWORK")
    combatIconSub:SetTexture("Interface\\Icons\\ABILITY_DUALWIELD")
    combatIconSub:SetSize(34, 34)
    combatIconSub:SetPoint("BOTTOM", anchorSubOutOfCombat, "TOP", 0, 1)
    CreateTooltip(combatIconSub, L["Tooltip_Combat_Indicator"])

    local combatIndicatorScale = CreateSlider(contentFrame, L["Size"], 0.1, 1.9, 0.01, "combatIndicatorScale")
    combatIndicatorScale:SetPoint("TOP", anchorSubOutOfCombat, "BOTTOM", 0, -15)

    local combatIndicatorXPos = CreateSlider(contentFrame, L["X_Offset"], -50, 50, 1, "combatIndicatorXPos", "X")
    combatIndicatorXPos:SetPoint("TOP", combatIndicatorScale, "BOTTOM", 0, -15)

    local combatIndicatorYPos = CreateSlider(contentFrame, L["Y_Offset"], -50, 50, 1, "combatIndicatorYPos", "Y")
    combatIndicatorYPos:SetPoint("TOP", combatIndicatorXPos, "BOTTOM", 0, -15)

    local combatIndicatorDropdown = CreateAnchorDropdown(
        "combatIndicatorDropdown",
        contentFrame,
        L["Select_Anchor_Point"],
        "combatIndicatorAnchor",
        function(arg1)
            BBF.CombatIndicatorCaller()
        end,
        { anchorFrame = combatIndicatorYPos, x = -16, y = -35, label = L["Anchor"] }
    )

    local combatIndicatorArenaOnly = CreateCheckbox("combatIndicatorArenaOnly", L["Arena_Only"], contentFrame)
    combatIndicatorArenaOnly:SetPoint("TOPLEFT", combatIndicatorDropdown, "BOTTOMLEFT", 5, pixelsBetweenBoxes)
    combatIndicatorArenaOnly:HookScript("OnClick", function(self)
        BBF.CombatIndicatorCaller()
    end)
    CreateTooltip(combatIndicatorArenaOnly, L["Tooltip_Arena_Only"])

    local combatIndicatorShowSap = CreateCheckbox("combatIndicatorShowSap", L["No_Combat"], contentFrame)
    combatIndicatorShowSap:SetPoint("TOPLEFT", combatIndicatorArenaOnly, "BOTTOMLEFT", 0, pixelsBetweenBoxes)
    combatIndicatorShowSap:HookScript("OnClick", function(self)
        BBF.CombatIndicatorCaller()
    end)
    CreateTooltip(combatIndicatorShowSap, L["Tooltip_No_Combat"])

    local combatIndicatorShowSwords = CreateCheckbox("combatIndicatorShowSwords", L["In_Combat"], contentFrame)
    combatIndicatorShowSwords:SetPoint("LEFT", combatIndicatorShowSap.Text, "RIGHT", 5, 0)
    combatIndicatorShowSwords:HookScript("OnClick", function(self)
        BBF.CombatIndicatorCaller()
    end)
    CreateTooltip(combatIndicatorShowSwords, L["Tooltip_In_Combat"])

    local combatIndicatorPlayersOnly = CreateCheckbox("combatIndicatorPlayersOnly", L["Players_Only"], contentFrame)
    combatIndicatorPlayersOnly:SetPoint("LEFT", combatIndicatorArenaOnly.Text, "RIGHT", 5, 0)
    combatIndicatorPlayersOnly:HookScript("OnClick", function(self)
        BBF.CombatIndicatorCaller()
    end)
    CreateTooltip(combatIndicatorPlayersOnly, L["Tooltip_Players_Only"])

    local playerCombatIndicator = CreateCheckbox("playerCombatIndicator", L["Player"], contentFrame)
    playerCombatIndicator:SetPoint("TOPLEFT", combatIndicatorShowSap, "BOTTOMLEFT", -5, -10)
    playerCombatIndicator:HookScript("OnClick", function(self)
        BBF.CombatIndicatorCaller()
    end)

    local targetCombatIndicator = CreateCheckbox("targetCombatIndicator", L["Target"], contentFrame)
    targetCombatIndicator:SetPoint("LEFT", playerCombatIndicator.Text, "RIGHT", 5, 0)
    targetCombatIndicator:HookScript("OnClick", function(self)
        BBF.CombatIndicatorCaller()
    end)

    local focusCombatIndicator = CreateCheckbox("focusCombatIndicator", L["Focus"], contentFrame)
    focusCombatIndicator:SetPoint("LEFT", targetCombatIndicator.Text, "RIGHT", 5, 0)
    focusCombatIndicator:HookScript("OnClick", function(self)
        BBF.CombatIndicatorCaller()
    end)


    --------------------------
    -- Healer Indicator
    ----------------------
    local anchorSubHealerIndicator = contentFrame:CreateFontString(nil, "OVERLAY", "GameFontNormal")
    anchorSubHealerIndicator:SetPoint("CENTER", mainGuiAnchor2, "CENTER", secondLineX+81, firstLineY)
    anchorSubHealerIndicator:SetText(L["Healer_Indicator"])

    --CreateBorderBox(anchorSubHealerIndicator)
    CreateBorderedFrame(anchorSubHealerIndicator, 200, 293, 0, -98, BetterBlizzFramesSubPanel)

    local healerIconSub = contentFrame:CreateTexture(nil, "ARTWORK")
    healerIconSub:SetAtlas("bags-icon-addslots")
    healerIconSub:SetSize(34, 34)
    healerIconSub:SetPoint("BOTTOM", anchorSubHealerIndicator, "TOP", 0, 1)
    CreateTooltip(healerIconSub, L["Tooltip_Healer_Indicator"])

    local healerIndicatorScale = CreateSlider(contentFrame, L["Size"], 0.8, 2.5, 0.01, "healerIndicatorScale")
    healerIndicatorScale:SetPoint("TOP", anchorSubHealerIndicator, "BOTTOM", 0, -15)

    local healerIndicatorXPos = CreateSlider(contentFrame, L["X_Offset"], -50, 50, 1, "healerIndicatorXPos", "X")
    healerIndicatorXPos:SetPoint("TOP", healerIndicatorScale, "BOTTOM", 0, -15)

    local healerIndicatorYPos = CreateSlider(contentFrame, L["Y_Offset"], -50, 50, 1, "healerIndicatorYPos", "Y")
    healerIndicatorYPos:SetPoint("TOP", healerIndicatorXPos, "BOTTOM", 0, -15)

    local healerIndicatorDropdown = CreateAnchorDropdown(
        "healerIndicatorDropdown",
        contentFrame,
        L["Select_Anchor_Point"],
        "healerIndicatorAnchor",
        function(arg1)
            BBF.HealerIndicatorCaller()
        end,
        { anchorFrame = healerIndicatorYPos, x = -16, y = -35, label = L["Anchor"] }
    )

    local healerIndicatorIcon = CreateCheckbox("healerIndicatorIcon", L["Icon"], contentFrame)
    healerIndicatorIcon:SetPoint("TOPLEFT", healerIndicatorDropdown, "BOTTOMLEFT", 24, pixelsBetweenBoxes)
    healerIndicatorIcon:HookScript("OnClick", function(self)
        if self:GetChecked() and not BetterBlizzFramesDB.healerIndicator then
            BetterBlizzFramesDB.healerIndicator = true
        end
        BBF.HealerIndicatorCaller()
        if not self:GetChecked() then
            StaticPopup_Show("BBF_CONFIRM_RELOAD")
        end
    end)
    CreateTooltip(healerIndicatorIcon, L["Tooltip_Healer_Icon_Show"])

    local healerIndicatorPortrait = CreateCheckbox("healerIndicatorPortrait", L["Portrait"], contentFrame)
    healerIndicatorPortrait:SetPoint("LEFT", healerIndicatorIcon.Text, "RIGHT", 5, 0)
    healerIndicatorPortrait:HookScript("OnClick", function(self)
        if self:GetChecked() and not BetterBlizzFramesDB.healerIndicator then
            BetterBlizzFramesDB.healerIndicator = true
        end
        BBF.HealerIndicatorCaller()
        if not self:GetChecked() then
            StaticPopup_Show("BBF_CONFIRM_RELOAD")
        end
    end)
    CreateTooltip(healerIndicatorPortrait, L["Tooltip_Healer_Portrait_Change"])



    --------------------------
    -- Racial indicator
    ----------------------
    local anchorSubracialIndicator = contentFrame:CreateFontString(nil, "OVERLAY", "GameFontNormal")
    anchorSubracialIndicator:SetPoint("CENTER", mainGuiAnchor2, "CENTER", secondLineX-145, secondLineY - 15)
    anchorSubracialIndicator:SetText(L["Racial_Indicator"])

    --CreateBorderBox(anchorSubracialIndicator)
    CreateBorderedFrame(anchorSubracialIndicator, 200, 293, 0, -98, BetterBlizzFramesSubPanel)

    local racialIndicatorIcon = contentFrame:CreateTexture(nil, "ARTWORK")
    racialIndicatorIcon:SetTexture("Interface\\Icons\\ability_ambush")
    racialIndicatorIcon:SetSize(34, 34)
    racialIndicatorIcon:SetPoint("BOTTOM", anchorSubracialIndicator, "TOP", 0, 1)
    CreateTooltip(racialIndicatorIcon, L["Tooltip_Racial_Indicator_Enable"])

    local racialIndicatorScale = CreateSlider(contentFrame, L["Size"], 0.1, 1.9, 0.01, "racialIndicatorScale")
    racialIndicatorScale:SetPoint("TOP", anchorSubracialIndicator, "BOTTOM", 0, -15)

    local racialIndicatorXPos = CreateSlider(contentFrame, L["X_Offset"], -50, 50, 1, "racialIndicatorXPos", "X")
    racialIndicatorXPos:SetPoint("TOP", racialIndicatorScale, "BOTTOM", 0, -15)

    local racialIndicatorYPos = CreateSlider(contentFrame, L["Y_Offset"], -50, 50, 1, "racialIndicatorYPos", "Y")
    racialIndicatorYPos:SetPoint("TOP", racialIndicatorXPos, "BOTTOM", 0, -15)

    local racialIndicatorOrc = CreateCheckbox("racialIndicatorOrc", L["Orc"], contentFrame)
    racialIndicatorOrc:SetPoint("TOPLEFT", racialIndicatorYPos, "BOTTOMLEFT", 5, -5)
    racialIndicatorOrc:HookScript("OnClick", function(self)
        BBF.RacialIndicatorCaller()
    end)
    CreateTooltip(racialIndicatorOrc, L["Tooltip_Show_Orc"])

    local racialIndicatorHuman = CreateCheckbox("racialIndicatorHuman", L["Human"], contentFrame)
    racialIndicatorHuman:SetPoint("TOPLEFT", racialIndicatorOrc, "BOTTOMLEFT", 0, pixelsBetweenBoxes)
    racialIndicatorHuman:HookScript("OnClick", function(self)
        BBF.RacialIndicatorCaller()
    end)
    CreateTooltip(racialIndicatorHuman, L["Tooltip_Show_Human"])

    local racialIndicatorDwarf = CreateCheckbox("racialIndicatorDwarf", L["Dwarf"], contentFrame)
    racialIndicatorDwarf:SetPoint("TOPLEFT", racialIndicatorHuman, "BOTTOMLEFT", 0, pixelsBetweenBoxes)
    racialIndicatorDwarf:HookScript("OnClick", function(self)
        BBF.RacialIndicatorCaller()
    end)
    CreateTooltip(racialIndicatorDwarf, L["Tooltip_Show_Dwarf"])

    local racialIndicatorNelf = CreateCheckbox("racialIndicatorNelf", L["Night_Elf"], contentFrame)
    racialIndicatorNelf:SetPoint("LEFT", racialIndicatorOrc.Text, "RIGHT", 25, 0)
    racialIndicatorNelf:HookScript("OnClick", function(self)
        BBF.RacialIndicatorCaller()
    end)
    CreateTooltip(racialIndicatorNelf, L["Tooltip_Night_Elf"])

    local racialIndicatorUndead = CreateCheckbox("racialIndicatorUndead", L["Undead"], contentFrame)
    racialIndicatorUndead:SetPoint("TOPLEFT", racialIndicatorNelf, "BOTTOMLEFT", 0, pixelsBetweenBoxes)
    racialIndicatorUndead:HookScript("OnClick", function(self)
        BBF.RacialIndicatorCaller()
    end)
    CreateTooltip(racialIndicatorUndead, L["Tooltip_Undead"])

    local racialIndicatorDarkIronDwarf = CreateCheckbox("racialIndicatorDarkIronDwarf", L["DI_Dwarf"], contentFrame)
    racialIndicatorDarkIronDwarf:SetPoint("TOPLEFT", racialIndicatorUndead, "BOTTOMLEFT", 0, pixelsBetweenBoxes)
    racialIndicatorDarkIronDwarf:HookScript("OnClick", function(self)
        BBF.RacialIndicatorCaller()
    end)
    CreateTooltip(racialIndicatorDarkIronDwarf, L["Tooltip_DI_Dwarf"])

    local targetRacialIndicator = CreateCheckbox("targetRacialIndicator", L["Target"], contentFrame)
    targetRacialIndicator:SetPoint("TOPLEFT", racialIndicatorDwarf, "BOTTOMLEFT", 0, -10)
    targetRacialIndicator:HookScript("OnClick", function(self)
        BBF.RacialIndicatorCaller()
    end)
    CreateTooltip(targetRacialIndicator, L["Tooltip_Target"])

    local focusRacialIndicator = CreateCheckbox("focusRacialIndicator", L["Focus"], contentFrame)
    focusRacialIndicator:SetPoint("LEFT", targetRacialIndicator.Text, "RIGHT", 12, 0)
    focusRacialIndicator:HookScript("OnClick", function(self)
        BBF.RacialIndicatorCaller()
    end)
    CreateTooltip(focusRacialIndicator, L["Tooltip_Focus"])

    local racialIndicatorRaceIcons = CreateCheckbox("racialIndicatorRaceIcons", L["Race_Icon"], contentFrame)
    racialIndicatorRaceIcons:SetPoint("TOPLEFT", targetRacialIndicator, "BOTTOMLEFT", 12, pixelsBetweenBoxes)
    racialIndicatorRaceIcons:HookScript("OnClick", function(self)
        BBF.RacialIndicatorCaller()
    end)
    CreateTooltip(racialIndicatorRaceIcons, L["Tooltip_Race_Icon"])

    ----------------------
    -- Castbar Interrupt Icon
    ----------------------
    local anchorSubInterruptIcon = contentFrame:CreateFontString(nil, "OVERLAY", "GameFontNormal")
    anchorSubInterruptIcon:SetPoint("CENTER", mainGuiAnchor2, "CENTER", secondLineX+81, secondLineY-15)
    anchorSubInterruptIcon:SetText(L["Interrupt_Icon_AS"])

    --CreateBorderBox(anchorSubInterruptIcon)
    CreateBorderedFrame(anchorSubInterruptIcon, 200, 293, 0, -98, BetterBlizzFramesSubPanel)

    local castBarInterruptIcon = contentFrame:CreateTexture(nil, "ARTWORK")
    castBarInterruptIcon:SetTexture("Interface\\Icons\\ability_kick")
    castBarInterruptIcon:SetSize(34, 34)
    castBarInterruptIcon:SetPoint("BOTTOM", anchorSubInterruptIcon, "TOP", 0, 0)
    CreateTooltip(castBarInterruptIcon, L["Show_Interrupt_Icon_Next_Castbar"])

    local castBarInterruptIconScale = CreateSlider(contentFrame, L["Size"], 0.1, 1.9, 0.01, "castBarInterruptIconScale")
    castBarInterruptIconScale:SetPoint("TOP", anchorSubInterruptIcon, "BOTTOM", 0, -15)

    local castBarInterruptIconXPos = CreateSlider(contentFrame, L["X_Offset"], -100, 100, 1, "castBarInterruptIconXPos", "X")
    castBarInterruptIconXPos:SetPoint("TOP", castBarInterruptIconScale, "BOTTOM", 0, -15)

    local castBarInterruptIconYPos = CreateSlider(contentFrame, L["Y_Offset"], -100, 100, 1, "castBarInterruptIconYPos", "Y")
    castBarInterruptIconYPos:SetPoint("TOP", castBarInterruptIconXPos, "BOTTOM", 0, -15)

    local castBarInterruptIconAnchorDropdown = CreateAnchorDropdown(
        "castBarInterruptIconAnchorDropdown",
        contentFrame,
        L["Select_Anchor_Point"],
        "castBarInterruptIconAnchor",
        function(arg1)
        BBF.UpdateInterruptIconSettings()
    end,
        { anchorFrame = castBarInterruptIconYPos, x = -16, y = -35, label = L["Anchor"] }
    )

    local castBarInterruptIconTarget = CreateCheckbox("castBarInterruptIconTarget", L["Target"], contentFrame, nil, BBF.UpdateInterruptIconSettings)
    castBarInterruptIconTarget:SetPoint("TOPLEFT", castBarInterruptIconAnchorDropdown, "BOTTOMLEFT", 24, pixelsBetweenBoxes)
    CreateTooltipTwo(castBarInterruptIconTarget, L["Show_On_Target"])

    local castBarInterruptIconFocus = CreateCheckbox("castBarInterruptIconFocus", L["Focus"], contentFrame, nil, BBF.UpdateInterruptIconSettings)
    castBarInterruptIconFocus:SetPoint("LEFT", castBarInterruptIconTarget.text, "RIGHT", 5, 0)
    CreateTooltipTwo(castBarInterruptIconFocus, L["Show_On_Focus"])

    local castBarInterruptIconShowActiveOnly = CreateCheckbox("castBarInterruptIconShowActiveOnly", L["Tooltip_Only_Show_If_Available_Desc"], contentFrame, nil, BBF.UpdateInterruptIconSettings)
    castBarInterruptIconShowActiveOnly:SetPoint("TOPLEFT", castBarInterruptIconTarget, "BOTTOMLEFT", -28, pixelsBetweenBoxes)
    CreateTooltipTwo(castBarInterruptIconShowActiveOnly, L["Tooltip_Only_Show_If_Available_Desc"], L["Tooltip_Only_Show_If_Available_Desc"])

    local interruptIconBorder = CreateCheckbox("interruptIconBorder", L["Border_Status_Color"], contentFrame, nil, BBF.UpdateInterruptIconSettings)
    interruptIconBorder:SetPoint("TOPLEFT", castBarInterruptIconShowActiveOnly, "BOTTOMLEFT", 0, pixelsBetweenBoxes)
    CreateTooltipTwo(interruptIconBorder, L["Border_Status_Color"], L["Tooltip_Border_Status_Color_Desc"])

    local reloadUiButton2 = CreateFrame("Button", nil, BetterBlizzFramesSubPanel, "UIPanelButtonTemplate")
    reloadUiButton2:SetText(L["Label_Reload_Ui"])
    reloadUiButton2:SetWidth(85)
    reloadUiButton2:SetPoint("TOP", BetterBlizzFramesSubPanel, "BOTTOMRIGHT", -140, -9)
    reloadUiButton2:SetScript("OnClick", function()
        BetterBlizzFramesDB.reopenOptions = true
        ReloadUI()
    end)

    local resetBBFButton = CreateFrame("Button", nil, BetterBlizzFramesSubPanel, "UIPanelButtonTemplate")
    resetBBFButton:SetText(L["Reset_BetterBlizzFrames"])
    resetBBFButton:SetWidth(165)
    resetBBFButton:SetPoint("RIGHT", reloadUiButton2, "LEFT", -533, 0)
    resetBBFButton:SetScript("OnClick", function()
        StaticPopup_Show("CONFIRM_RESET_BETTERBLIZZFRAMESDB")
    end)
    CreateTooltip(resetBBFButton, L["Tooltip_Full_Reset"])

    BetterBlizzFramesSubPanel.rightClickTip = BetterBlizzFramesSubPanel:CreateFontString(nil, "OVERLAY", "GameFontNormalLarge")
    BetterBlizzFramesSubPanel.rightClickTip:SetPoint("RIGHT", reloadUiButton2, "LEFT", -80, -2)
    BetterBlizzFramesSubPanel.rightClickTip:SetText("|A:smallquestbang:20:20|a" .. L["Right_Click_Slider_Tip"])
end

local function guiFrameLook()
    ----------------------
    -- Frame Auras
    ----------------------
    local guiFrameLook = CreateFrame("Frame")
    guiFrameLook.name = L["Module_Name_Font_Texture"]
    guiFrameLook.parent = BetterBlizzFrames.name
    --InterfaceOptions_AddCategory(guiFrameAuras)
    local aurasSubCategory = Settings.RegisterCanvasLayoutSubcategory(BBF.category, guiFrameLook, guiFrameLook.name, guiFrameLook.name)
    aurasSubCategory.ID = guiFrameLook.name;
    CreateTitle(guiFrameLook)

    local bgImg = guiFrameLook:CreateTexture(nil, "BACKGROUND")
    bgImg:SetAtlas("professions-recipe-background")
    bgImg:SetPoint("CENTER", guiFrameLook, "CENTER", -8, 4)
    bgImg:SetSize(680, 610)
    bgImg:SetAlpha(0.4)
    bgImg:SetVertexColor(0,0,0)

    local mainGuiAnchor = guiFrameLook:CreateFontString(nil, "OVERLAY", "GameFontNormal")
    mainGuiAnchor:SetPoint("TOPLEFT", 15, -15)
    mainGuiAnchor:SetText(" ")

    local settingsText = guiFrameLook:CreateFontString(nil, "OVERLAY", "GameFontNormal")
    settingsText:SetPoint("TOPLEFT", mainGuiAnchor, "BOTTOMLEFT", 0, 30)
    settingsText:SetText(L["Font_And_Texture_WIP"])
    local generalSettingsIcon = guiFrameLook:CreateTexture(nil, "ARTWORK")
    generalSettingsIcon:SetAtlas("optionsicon-brown")
    generalSettingsIcon:SetSize(22, 22)
    generalSettingsIcon:SetPoint("RIGHT", settingsText, "LEFT", -3, -1)

    local howToImport = guiFrameLook:CreateFontString(nil, "OVERLAY", "GameFontNormal")
    howToImport:SetFont(fontLarge, 16)
    howToImport:SetPoint("CENTER", mainGuiAnchor, "BOTTOMLEFT", 415, -365)
    howToImport:SetText(L["How_To_Import"])

    local howStepOne = guiFrameLook:CreateFontString(nil, "OVERLAY", "GameFontNormal")
    howStepOne:SetJustifyH("LEFT")
    howStepOne:SetFont(fontSmall, 12)
    howStepOne:SetPoint("TOPLEFT", howToImport, "BOTTOMLEFT", -20, -10)
    howStepOne:SetText(L["How_Custom_Media"])

    local fontEditBox = CreateFrame("EditBox", nil, guiFrameLook, "InputBoxTemplate")
    fontEditBox:SetSize(330, 20)
    fontEditBox:SetPoint("TOPLEFT", howStepOne, "BOTTOMLEFT", 5, -5)
    fontEditBox:SetAutoFocus(false)
    fontEditBox:SetText("BBF.LSM:Register(\"font\", \"My Font Name\", [[Interface\\AddOns\\CustomMedia\\MyFontFile.ttf]], BBF.allLocales)")
    fontEditBox:HighlightText()
    fontEditBox:SetCursorPosition(0)
    fontEditBox:SetScript("OnTextChanged", function(self)
        fontEditBox:SetText("BBF.LSM:Register(\"font\", \"My Font Name\", [[Interface\\AddOns\\CustomMedia\\MyFontFile.ttf]], BBF.allLocales)")
    end)
    fontEditBox:SetScript("OnMouseUp", function(self)
        self:SetFocus()
        self:HighlightText()
    end)

    local howStepTwo = guiFrameLook:CreateFontString(nil, "OVERLAY", "GameFontNormal")
    howStepTwo:SetJustifyH("LEFT")
    howStepTwo:SetFont(fontSmall, 12)
    howStepTwo:SetPoint("TOPLEFT", fontEditBox, "BOTTOMLEFT", -5, -13)
    howStepTwo:SetText(L["How_Custom_Media_2"])

    local textureEditBox = CreateFrame("EditBox", nil, guiFrameLook, "InputBoxTemplate")
    textureEditBox:SetSize(330, 20)
    textureEditBox:SetPoint("TOPLEFT", howStepTwo, "BOTTOMLEFT", 5, -5)
    textureEditBox:SetAutoFocus(false)
    textureEditBox:SetText("BBF.LSM:Register(\"statusbar\", \"My Texture Name\", [[Interface\\AddOns\\CustomMedia\\MyTextureFile.tga]])")
    textureEditBox:HighlightText()
    textureEditBox:SetCursorPosition(0)
    textureEditBox:SetScript("OnTextChanged", function(self)
        textureEditBox:SetText("BBF.LSM:Register(\"statusbar\", \"My Texture Name\", [[Interface\\AddOns\\CustomMedia\\MyTextureFile.tga]])")
    end)
    textureEditBox:SetScript("OnMouseUp", function(self)
        self:SetFocus()
        self:HighlightText()
    end)

    local howStepThree = guiFrameLook:CreateFontString(nil, "OVERLAY", "GameFontNormal")
    howStepThree:SetJustifyH("LEFT")
    howStepThree:SetFont(fontSmall, 12)
    howStepThree:SetPoint("TOPLEFT", textureEditBox, "BOTTOMLEFT", -5, -13)
    howStepThree:SetText(L["How_Custom_Media_3"])

    local changeUnitFrameFont = CreateCheckbox("changeUnitFrameFont", L["Tooltip_Change_UnitFrame_Font_Desc"], guiFrameLook)
    changeUnitFrameFont:SetPoint("TOPLEFT", settingsText, "BOTTOMLEFT", -4, pixelsOnFirstBox)
    CreateTooltipTwo(changeUnitFrameFont, L["Tooltip_Change_UnitFrame_Font_Desc"], L["Tooltip_Change_UnitFrame_Font_Etc_Desc"])

    local unitFrameFontColor = CreateCheckbox("unitFrameFontColor", L["Color"], guiFrameLook)
    unitFrameFontColor:SetPoint("LEFT", changeUnitFrameFont.Text, "RIGHT", 0, 0)
    CreateTooltipTwo(unitFrameFontColor, L["Color"], L["Tooltip_Color_Change_Font_Desc"])
    unitFrameFontColor:HookScript("OnClick", function()
        BBF.FontColors()
    end)
    unitFrameFontColor:SetScript("OnMouseDown", function(self, button)
        if button == "RightButton" then
            OpenColorOptions(BetterBlizzFramesDB.unitFrameFontColorRGB,  BBF.FontColors)
        end
    end)

    local unitFrameFontColorLvl = CreateCheckbox("unitFrameFontColorLvl", L["FontTexture_Color_Level"], guiFrameLook)
    unitFrameFontColorLvl:SetPoint("LEFT", unitFrameFontColor.Text, "RIGHT", 0, 0)
    CreateTooltipTwo(unitFrameFontColorLvl, L["FontTexture_Color_Level"], L["Tooltip_Color_Level_Font_Desc"])
    unitFrameFontColorLvl:HookScript("OnClick", function()
        BBF.FontColors()
    end)

    local unitFrameFont = CreateFontDropdown(
        "unitFrameFont",
        guiFrameLook,
        L["Select_Font"],
        "unitFrameFont",
        function(arg1)
            BBF.SetCustomFonts()
        end,
        { anchorFrame = changeUnitFrameFont, x = 55, y = 1, label = L["Font"] }
    )

    -- For font outline
    local unitFrameFontOutline = CreateSimpleDropdown("FontOutlineDropdown", guiFrameLook, L["Outline_Label"], "unitFrameFontOutline", {
        "THICKOUTLINE", "THINOUTLINE", "NONE"
    }, function(selectedSize)
        BBF.SetCustomFonts()
    end, { anchorFrame = unitFrameFont, x = 0, y = -5 }, 155)

    -- For font size
    local fontSizeOptions = {}
    for i = 6, 24 do
        table.insert(fontSizeOptions, tostring(i))
    end

    local unitFrameFontSize = CreateSimpleDropdown("FontSizeDropdown", guiFrameLook, L["Size"], "unitFrameFontSize", fontSizeOptions, function(selectedSize)
        BBF.SetCustomFonts()
    end, { anchorFrame = unitFrameFontOutline, x = 0, y = -5 }, 155)

    changeUnitFrameFont:HookScript("OnClick", function(self)
        BBF.SetCustomFonts()
        if not self:GetChecked() then
            StaticPopup_Show("BBF_CONFIRM_RELOAD")
            unitFrameFont:Disable()
            unitFrameFontOutline:Disable()
            unitFrameFontSize:Disable()
        else
            unitFrameFont:Enable()
            unitFrameFontOutline:Enable()
            unitFrameFontSize:Enable()
        end
    end)

    if not changeUnitFrameFont:GetChecked() then
        unitFrameFont:Disable()
        unitFrameFontOutline:Disable()
        unitFrameFontSize:Disable()
    end





    local changeUnitFrameValueFont = CreateCheckbox("changeUnitFrameValueFont", L["Tooltip_Change_UnitFrame_Number_Font_Desc"], guiFrameLook)
    changeUnitFrameValueFont:SetPoint("TOPLEFT", changeUnitFrameFont, "BOTTOMLEFT", 0, -100)
    CreateTooltipTwo(changeUnitFrameValueFont, L["Tooltip_Change_UnitFrame_Number_Font_Desc"], L["Tooltip_Change_UnitFrame_Number_Font_Etc_Desc"])

    local unitFrameValueFontColor = CreateCheckbox("unitFrameValueFontColor", L["Color"], guiFrameLook)
    unitFrameValueFontColor:SetPoint("LEFT", changeUnitFrameValueFont.Text, "RIGHT", 0, 0)
    CreateTooltipTwo(unitFrameValueFontColor, L["UnitFrame_Numbers_Font_Color"], L["Tooltip_UnitFrame_Numbers_Font_Color_Desc"])
    unitFrameValueFontColor:HookScript("OnClick", function()
        BBF.FontColors()
    end)
    unitFrameValueFontColor:SetScript("OnMouseDown", function(self, button)
        if button == "RightButton" then
            OpenColorOptions(BetterBlizzFramesDB.unitFrameValueFontColorRGB,  BBF.FontColors)
        end
    end)

    local unitFrameValueFont = CreateFontDropdown(
        "unitFrameValueFont",
        guiFrameLook,
        L["Select_Font"],
        "unitFrameValueFont",
        function(arg1)
            BBF.SetCustomFonts()
        end,
        { anchorFrame = changeUnitFrameValueFont, x = 55, y = 1, label = L["Font"] }
    )

    -- For font outline
    local unitFrameValueFontOutline = CreateSimpleDropdown("FontOutlineDropdown", guiFrameLook, L["Outline_Label"], "unitFrameValueFontOutline", {
        "THICKOUTLINE", "THINOUTLINE", "NONE"
    }, function(selectedSize)
        BBF.SetCustomFonts()
    end, { anchorFrame = unitFrameValueFont, x = 0, y = -5 }, 155)

    local unitFrameValueFontSize = CreateSimpleDropdown("FontSizeDropdown", guiFrameLook, L["Size"], "unitFrameValueFontSize", fontSizeOptions, function(selectedSize)
        BBF.SetCustomFonts()
    end, { anchorFrame = unitFrameValueFontOutline, x = 0, y = -5 }, 155)

    changeUnitFrameValueFont:HookScript("OnClick", function(self)
        BBF.SetCustomFonts()
        if not self:GetChecked() then
            StaticPopup_Show("BBF_CONFIRM_RELOAD")
            unitFrameValueFont:Disable()
            unitFrameValueFontOutline:Disable()
            unitFrameValueFontSize:Disable()
        else
            unitFrameValueFont:Enable()
            unitFrameValueFontOutline:Enable()
            unitFrameValueFontSize:Enable()
        end
    end)

    if not changeUnitFrameValueFont:GetChecked() then
        unitFrameValueFont:Disable()
        unitFrameValueFontOutline:Disable()
        unitFrameValueFontSize:Disable()
    end





    local changePartyFrameFont = CreateCheckbox("changePartyFrameFont", L["Change_Party_Font"], guiFrameLook)
    changePartyFrameFont:SetPoint("TOPLEFT", changeUnitFrameValueFont, "BOTTOMLEFT", 0, -100)
    CreateTooltipTwo(changePartyFrameFont, L["Change_Party_Font"], L["Tooltip_Change_PartyFrames_Font_Desc"])

    local partyFrameFontColor = CreateCheckbox("partyFrameFontColor", L["Color"], guiFrameLook)
    partyFrameFontColor:SetPoint("LEFT", changePartyFrameFont.Text, "RIGHT", 0, 0)
    CreateTooltipTwo(partyFrameFontColor, L["Color"], L["Tooltip_Change_Party_Font_Color_Desc"])
    partyFrameFontColor:HookScript("OnClick", function()
        BBF.FontColors()
    end)
    partyFrameFontColor:SetScript("OnMouseDown", function(self, button)
        if button == "RightButton" then
            OpenColorOptions(BetterBlizzFramesDB.partyFrameFontColorRGB,  BBF.FontColors)
        end
    end)

    local partyFrameFont = CreateFontDropdown(
        "partyFrameFont",
        guiFrameLook,
        L["Select_Font"],
        "partyFrameFont",
        function(arg1)
            BBF.SetCustomFonts()
        end,
        { anchorFrame = changePartyFrameFont, x = 55, y = 1, label = L["Font"] }
    )

    -- For font outline
    local partyFrameFontOutline = CreateSimpleDropdown("FontOutlineDropdown", guiFrameLook, L["Outline_Label"], "partyFrameFontOutline", {
        "THICKOUTLINE", "THINOUTLINE", "NONE"
    }, function(selectedSize)
        BBF.SetCustomFonts()
    end, { anchorFrame = partyFrameFont, x = 0, y = -5 }, 155)

    local partyFrameFontSize = CreateSimpleDropdown("FontSizeDropdown", guiFrameLook, L["Size"], "partyFrameFontSize", fontSizeOptions, function(selectedSize)
        BBF.SetCustomFonts()
    end, { anchorFrame = partyFrameFontOutline, x = 0, y = -5 }, 77.5)
    CreateTooltipTwo(partyFrameFontSize, L["Tooltip_Name_Size"])

    local partyFrameStatusFontSize = CreateSimpleDropdown("FontSizeDropdown", guiFrameLook, "", "partyFrameStatusFontSize", fontSizeOptions, function(selectedSize)
        BBF.SetCustomFonts()
    end, { anchorFrame = partyFrameFontSize, x = 77.5, y = 25 }, 77.5)
    CreateTooltipTwo(partyFrameStatusFontSize, L["Tooltip_Status_Text_Size"])

    changePartyFrameFont:HookScript("OnClick", function(self)
        BBF.SetCustomFonts()
        if not self:GetChecked() then
            StaticPopup_Show("BBF_CONFIRM_RELOAD")
            partyFrameFont:Disable()
            partyFrameFontOutline:Disable()
            partyFrameFontSize:Disable()
            partyFrameStatusFontSize:Disable()
        else
            partyFrameFont:Enable()
            partyFrameFontOutline:Enable()
            partyFrameFontSize:Enable()
            partyFrameStatusFontSize:Enable()
        end
    end)

    if not changePartyFrameFont:GetChecked() then
        partyFrameFont:Disable()
        partyFrameFontOutline:Disable()
        partyFrameFontSize:Disable()
        partyFrameStatusFontSize:Disable()
    end


    local changeActionBarFont = CreateCheckbox("changeActionBarFont", L["Change_ActionBar_Font"], guiFrameLook)
    changeActionBarFont:SetPoint("TOPLEFT", changePartyFrameFont, "BOTTOMLEFT", 0, -100)
    CreateTooltipTwo(changeActionBarFont, L["Change_ActionBar_Font"], L["Tooltip_Change_ActionBar_Font_Etc_Desc"])

    local actionBarFontColor = CreateCheckbox("actionBarFontColor", L["Color"], guiFrameLook)
    actionBarFontColor:SetPoint("LEFT", changeActionBarFont.Text, "RIGHT", 0, 0)
    CreateTooltipTwo(actionBarFontColor, L["Color"], L["Tooltip_Change_ActionBar_Font_Color_Desc"])
    actionBarFontColor:HookScript("OnClick", function()
        BBF.FontColors()
    end)
    actionBarFontColor:SetScript("OnMouseDown", function(self, button)
        if button == "RightButton" then
            OpenColorOptions(BetterBlizzFramesDB.actionBarFontColorRGB,  BBF.FontColors)
        end
    end)

    local actionBarChangeCharge = CreateCheckbox("actionBarChangeCharge", L["Charges"], guiFrameLook)
    actionBarChangeCharge:SetPoint("LEFT", actionBarFontColor.Text, "RIGHT", 0, 0)
    CreateTooltipTwo(actionBarChangeCharge, L["Charges"], L["Tooltip_Charges_Font_Desc"])

    local actionBarFont = CreateFontDropdown(
        "actionBarFont",
        guiFrameLook,
        L["Select_Font"],
        "actionBarFont",
        function(arg1)
            BBF.SetCustomFonts()
        end,
        { anchorFrame = changeActionBarFont, x = 55, y = 1, label = L["Font"] }
    )

    -- For font outline
    local actionBarFontOutline = CreateSimpleDropdown("FontOutlineDropdown", guiFrameLook, L["Outline_Label"], "actionBarFontOutline", {
        "THICKOUTLINE", "THINOUTLINE", "NONE"
    }, function(selectedSize)
        BBF.SetCustomFonts()
    end, { anchorFrame = actionBarFont, x = 0, y = -5 }, 77.5)
    CreateTooltipTwo(actionBarFontOutline, L["Tooltip_Macro_Text_Outline"])

    local actionBarKeyFontOutline = CreateSimpleDropdown("FontOutlineDropdown", guiFrameLook, "", "actionBarKeyFontOutline", {
        "THICKOUTLINE", "THINOUTLINE", "NONE"
    }, function(selectedSize)
        BBF.SetCustomFonts()
    end, { anchorFrame = actionBarFontOutline, x = 77.5, y = 25 }, 77.5)
    CreateTooltipTwo(actionBarKeyFontOutline, L["Tooltip_Keybinding_Text_Outline"])

    local actionBarFontSize = CreateSimpleDropdown("FontSizeDropdown", guiFrameLook, L["Size"], "actionBarFontSize", fontSizeOptions, function(selectedSize)
        BBF.SetCustomFonts()
    end, { anchorFrame = actionBarFontOutline, x = 0, y = -5 }, 77.5)
    CreateTooltipTwo(actionBarFontSize, L["Tooltip_Macro_Text_Size"])

    local actionBarKeyFontSize = CreateSimpleDropdown("FontSizeDropdown", guiFrameLook, "", "actionBarKeyFontSize", fontSizeOptions, function(selectedSize)
        BBF.SetCustomFonts()
    end, { anchorFrame = actionBarFontSize, x = 77.5, y = 25 }, 77.5)
    CreateTooltipTwo(actionBarKeyFontSize, L["Tooltip_Keybinding_Text_Size"])

    local actionBarChargeFontSize = CreateSimpleDropdown("FontSizeDropdown", guiFrameLook, "", "actionBarChargeFontSize", fontSizeOptions, function(selectedSize)
        BBF.SetCustomFonts()
    end, { anchorFrame = actionBarFontSize, x = 77.5, y = 0 }, 77.5)
    CreateTooltipTwo(actionBarChargeFontSize, L["Tooltip_Charge_Text_Size"])

    local function ToggleDropdowns(enable)
        for _, dd in ipairs({
            actionBarFont,
            actionBarFontOutline,
            actionBarKeyFontOutline,
            actionBarFontSize,
            actionBarKeyFontSize
        }) do
            dd:SetEnabled(enable)
        end
        actionBarChargeFontSize:SetEnabled(enable and actionBarChangeCharge:GetChecked())
    end

    changeActionBarFont:HookScript("OnClick", function(self)
        BBF.SetCustomFonts()
        if not self:GetChecked() then
            StaticPopup_Show("BBF_CONFIRM_RELOAD")
        end
        ToggleDropdowns(self:GetChecked())
    end)

    actionBarChangeCharge:HookScript("OnClick", function(self)
        BBF.FontColors()
        actionBarChargeFontSize:SetEnabled(changeActionBarFont:GetChecked() and self:GetChecked())
    end)

    ToggleDropdowns(changeActionBarFont:GetChecked())










    local changeAllFontsIngame = CreateCheckbox("changeAllFontsIngame", L["Tooltip_One_Font_All_Text_Desc"], guiFrameLook)
    changeAllFontsIngame:SetPoint("TOPLEFT", changeActionBarFont, "BOTTOMLEFT", 0, -115)
    CreateTooltipTwo(changeAllFontsIngame, L["Tooltip_One_Font_All_Text_Desc"], L["Tooltip_One_Font_All_Text_Desc"], L["Tooltip_One_Font_All_Text_Extra"])

    local allIngameFont = CreateFontDropdown(
        "allIngameFont",
        guiFrameLook,
        L["Select_Font"],
        "allIngameFont",
        function(arg1)
            BBF.SetCustomFonts()
        end,
        { anchorFrame = changeAllFontsIngame, x = 55, y = 1, label = L["Font"] }
    )

    changeAllFontsIngame:HookScript("OnClick", function(self)
        BBF.SetCustomFonts()
        if not self:GetChecked() then
            StaticPopup_Show("BBF_CONFIRM_RELOAD")
        end
        allIngameFont:SetEnabled(self:GetChecked())
    end)
    allIngameFont:SetEnabled(changeAllFontsIngame:GetChecked())







    local changeUnitFrameHealthbarTexture = CreateCheckbox("changeUnitFrameHealthbarTexture", L["Tooltip_Change_UnitFrame_Healthbar_Texture_Desc"], guiFrameLook)
    changeUnitFrameHealthbarTexture:SetPoint("TOPLEFT", settingsText, "BOTTOMLEFT", 260, pixelsOnFirstBox)
    if not BetterBlizzFramesDB.classicFrames then
        CreateTooltipTwo(changeUnitFrameHealthbarTexture, L["Tooltip_Change_UnitFrame_Healthbar_Texture_Desc"], L["Tooltip_Change_UnitFrame_Healthbar_Texture_Desc"])
    else
        CreateTooltipTwo(changeUnitFrameHealthbarTexture, L["Tooltip_Change_UnitFrame_Healthbar_Texture_Desc"], L["Tooltip_Change_UnitFrame_Healthbar_Texture_RightClick_Desc"])
            changeUnitFrameHealthbarTexture:HookScript("OnMouseDown", function(self, button)
            if button == "RightButton" then
                if not BetterBlizzFramesDB.changeUnitFrameHealthbarTextureRepColor then
                    BetterBlizzFramesDB.changeUnitFrameHealthbarTextureRepColor = true
                else
                    BetterBlizzFramesDB.changeUnitFrameHealthbarTextureRepColor = nil
                end
                local function retexture(tex)
                    if not tex then return end
                    tex:SetTexture((BetterBlizzFramesDB.changeUnitFrameHealthbarTextureRepColor and LSM:Fetch(LSM.MediaType.STATUSBAR, BetterBlizzFramesDB.unitFrameHealthbarTexture) or "Interface\\TargetingFrame\\UI-TargetingFrame-LevelBackground"))
                end
                retexture(PlayerFrame.PlayerFrameContent.PlayerFrameContentMain.ReputationColor)
                retexture(TargetFrame.TargetFrameContent.TargetFrameContentMain.ReputationColor)
                retexture(FocusFrame.TargetFrameContent.TargetFrameContentMain.ReputationColor)
            end
        end)
    end

    if BetterBlizzFramesDB.classicFrames then
        local text = guiFrameLook:CreateFontString(nil, "OVERLAY")
        text:SetFont(fontSmall, 12)
        text:SetText(L["Classic_Frames_Label"])
        text:SetTextColor(1,0,0)
        CreateTooltipTwo(text, L["Classic_Frames_Healthbar"], L["Tooltip_Classic_Frames_Healthbar_Desc"], nil, "ANCHOR_BOTTOMRIGHT")
        text:SetPoint("LEFT", changeUnitFrameHealthbarTexture.Text, "RIGHT", 5, 0)
    end

    local unitFrameHealthbarTexture = CreateTextureDropdown(
        "unitFrameHealthbarTexture",
        guiFrameLook,
        L["Select_Texture"],
        "unitFrameHealthbarTexture",
        function(arg1)
            BBF.UpdateCustomTextures()
        end,
        { anchorFrame = changeUnitFrameHealthbarTexture, x = 5, y = 3, label = "Texture" }
    )

    changeUnitFrameHealthbarTexture:HookScript("OnClick", function(self)
        unitFrameHealthbarTexture:SetEnabled(self:GetChecked())
        BBF.UpdateCustomTextures()
        if not self:GetChecked() then
            StaticPopup_Show("BBF_CONFIRM_RELOAD")
        end
    end)
    unitFrameHealthbarTexture:SetEnabled(changeUnitFrameHealthbarTexture:GetChecked())

    local changeUnitFrameManabarTexture = CreateCheckbox("changeUnitFrameManabarTexture", L["Tooltip_Change_UnitFrame_Manabar_Texture_Desc"], guiFrameLook)
    changeUnitFrameManabarTexture:SetPoint("TOPLEFT", changeUnitFrameHealthbarTexture, "BOTTOMLEFT", 0, -25)
    CreateTooltipTwo(changeUnitFrameManabarTexture, L["Tooltip_Change_UnitFrame_Manabar_Texture_Desc"], L["Tooltip_Change_UnitFrame_Manabar_Texture_Desc"])

    local changeUnitFrameManaBarTextureKeepFancy = CreateCheckbox("changeUnitFrameManaBarTextureKeepFancy", L["Keep_Fancy_Manabars"], changeUnitFrameManabarTexture)
    changeUnitFrameManaBarTextureKeepFancy:SetPoint("LEFT", changeUnitFrameManabarTexture.Text, "RIGHT", 0, 0)
    CreateTooltipTwo(changeUnitFrameManaBarTextureKeepFancy, L["Keep_Fancy_Manabars"], L["Tooltip_Keep_Fancy_Manabars_Desc"])
    changeUnitFrameManaBarTextureKeepFancy:HookScript("OnClick", function()
        StaticPopup_Show("BBF_CONFIRM_RELOAD")
    end)

    local unitFrameManabarTexture = CreateTextureDropdown(
        "unitFrameManabarTexture",
        guiFrameLook,
        L["Select_Texture"],
        "unitFrameManabarTexture",
        function(arg1)
            BBF.UpdateCustomTextures()
        end,
        { anchorFrame = changeUnitFrameManabarTexture, x = 5, y = 3, label = "Texture" }
    )
    changeUnitFrameManabarTexture:HookScript("OnClick", function(self)
        unitFrameManabarTexture:SetEnabled(self:GetChecked())
        BBF.UpdateCustomTextures()
        if not self:GetChecked() then
            StaticPopup_Show("BBF_CONFIRM_RELOAD")
        end
        CheckAndToggleCheckboxes(self)
    end)
    unitFrameManabarTexture:SetEnabled(changeUnitFrameManabarTexture:GetChecked())

    if BetterBlizzFramesDB.classicFrames then

        local changeUnitFrameNameBgTexture = CreateCheckbox("changeUnitFrameNameBgTexture", L["Change_Name_Bg_Texture"], guiFrameLook)
        changeUnitFrameNameBgTexture:SetPoint("TOPLEFT", settingsText, "BOTTOMLEFT", 465, -23)
        CreateTooltipTwo(changeUnitFrameNameBgTexture, L["Change_Name_Bg_Texture"], L["Tooltip_Change_Name_Bg_Texture_Desc"])

        local unitFrameNameBgTexture = CreateTextureDropdown(
            "unitFrameNameBgTexture",
            guiFrameLook,
            L["Select_Texture"],
            "unitFrameNameBgTexture",
            function(arg1)
                BBF.UpdateCustomTextures()
            end,
            { anchorFrame = changeUnitFrameNameBgTexture, x = 5, y = 3, label = "Texture" }
        )
        changeUnitFrameNameBgTexture:HookScript("OnClick", function(self)
            unitFrameNameBgTexture:SetEnabled(self:GetChecked())
            BBF.UpdateCustomTextures()
            if not self:GetChecked() then
                StaticPopup_Show("BBF_CONFIRM_RELOAD")
            end
        end)
        unitFrameNameBgTexture:SetEnabled(changeUnitFrameNameBgTexture:GetChecked())
    end

    local changeUnitFrameCastbarTexture = CreateCheckbox("changeUnitFrameCastbarTexture", L["Change_Castbar_Texture"], guiFrameLook)
    changeUnitFrameCastbarTexture:SetPoint("TOPLEFT", changeUnitFrameManabarTexture, "BOTTOMLEFT", 0, -25)
    CreateTooltipTwo(changeUnitFrameCastbarTexture, L["Change_Castbar_Texture"], L["Tooltip_Change_Castbar_Texture_Desc"])

    local unitFrameCastbarTexture = CreateTextureDropdown(
        "unitFrameCastbarTexture",
        guiFrameLook,
        L["Select_Texture"],
        "unitFrameCastbarTexture",
        function(arg1)
            BBF.UpdateCustomTextures()
        end,
        { anchorFrame = changeUnitFrameCastbarTexture, x = 5, y = 3, label = "Texture" }
    )
    changeUnitFrameCastbarTexture:HookScript("OnClick", function(self)
        unitFrameCastbarTexture:SetEnabled(self:GetChecked())
        BBF.UpdateCustomTextures()
        if not self:GetChecked() then
            StaticPopup_Show("BBF_CONFIRM_RELOAD")
        end
    end)
    unitFrameCastbarTexture:SetEnabled(changeUnitFrameCastbarTexture:GetChecked())

    local changeUnitFrameBackgroundTexture = CreateCheckbox("addUnitFrameBgTexture", L["Change_UnitFrame_Background_Texture"], guiFrameLook)
    changeUnitFrameBackgroundTexture:SetPoint("TOPLEFT", changeUnitFrameCastbarTexture, "BOTTOMLEFT", 0, -25)
    CreateTooltipTwo(changeUnitFrameBackgroundTexture, L["Change_UnitFrame_Background_Texture"], L["Tooltip_Change_UnitFrame_Background_Texture_Desc"])

    local unitFrameBgTexture = CreateTextureDropdown(
        "unitFrameBgTexture",
        guiFrameLook,
        L["Select_Texture"],
        "unitFrameBgTexture",
        function(arg1)
            BBF.UpdateCustomTextures()
            BBF.UnitFrameBackgroundTexture()
        end,
        { anchorFrame = changeUnitFrameBackgroundTexture, x = 5, y = 3, label = "Texture" }
    )

    local unitFrameBgTextureColorFL = CreateColorBox(guiFrameLook, "unitFrameBgTextureColor", "Health BG", function() BBF.UnitFrameBackgroundTexture() end)
    unitFrameBgTextureColorFL:SetPoint("LEFT", unitFrameBgTexture, "RIGHT", 10, 0)
    CreateTooltipTwo(unitFrameBgTextureColorFL, "Health Bar Background Color", "Left-click to change.\n\n|cff32f795Shift+Right-click to reset to default.|r")

    local unitFrameBgTextureManaColorFL = CreateColorBox(guiFrameLook, "unitFrameBgTextureManaColor", "Mana BG", function() BBF.UnitFrameBackgroundTexture() end)
    unitFrameBgTextureManaColorFL:SetPoint("LEFT", unitFrameBgTextureColorFL.text, "RIGHT", 4, 0)
    CreateTooltipTwo(unitFrameBgTextureManaColorFL, "Mana Bar Background Color", "Left-click to change.\n\n|cff32f795Shift+Right-click to reset to default.|r")

    changeUnitFrameBackgroundTexture:HookScript("OnClick", function(self)
        local alpha = self:GetChecked() and 1 or 0.5
        unitFrameBgTextureColorFL:SetAlpha(alpha)
        unitFrameBgTextureManaColorFL:SetAlpha(alpha)
        unitFrameBgTexture:SetEnabled(self:GetChecked())
        BBF.UpdateCustomTextures()
        BBF.UnitFrameBackgroundTexture()
        BBF.UpdateFrames()
        
        if BBF.addUnitFrameBgTexture then
            BBF.addUnitFrameBgTexture:SetChecked(self:GetChecked())
            if BBF.addUnitFrameBgTexture.parent then
                local clrFx = BBF.addUnitFrameBgTexture.parent
                if clrFx.unitFrameBgTextureColor then
                    clrFx.unitFrameBgTextureColor:SetAlpha(alpha)
                end
                if clrFx.unitFrameBgTextureManaColor then
                    clrFx.unitFrameBgTextureManaColor:SetAlpha(alpha)
                end
                if clrFx.unitFrameBgTexture then
                    clrFx.unitFrameBgTexture:SetEnabled(self:GetChecked())
                end
            end
        end
        
        if not self:GetChecked() then
            StaticPopup_Show("BBF_CONFIRM_RELOAD")
        end
    end)
    BBF.changeUnitFrameBackgroundColorTexture = changeUnitFrameBackgroundTexture
    BBF.unitFrameBgTextureDropdown = unitFrameBgTexture
    unitFrameBgTexture:SetEnabled(changeUnitFrameBackgroundTexture:GetChecked())
    local unitFrameBgAlpha = changeUnitFrameBackgroundTexture:GetChecked() and 1 or 0.5
    unitFrameBgTextureColorFL:SetAlpha(unitFrameBgAlpha)
    unitFrameBgTextureManaColorFL:SetAlpha(unitFrameBgAlpha)

    local changeRaidFrameHealthbarTexture = CreateCheckbox("changeRaidFrameHealthbarTexture", L["Tooltip_Change_RaidFrame_Healthbar_Texture_Desc"], guiFrameLook)
    changeRaidFrameHealthbarTexture:SetPoint("TOPLEFT", changeUnitFrameBackgroundTexture, "BOTTOMLEFT", 0, -40)
    CreateTooltipTwo(changeRaidFrameHealthbarTexture, L["Tooltip_Change_RaidFrame_Healthbar_Texture_Desc"], L["Tooltip_Change_RaidFrame_Healthbar_Texture_Etc_Desc"])

    local raidFrameHealthbarTexture = CreateTextureDropdown(
        "raidFrameHealthbarTexture",
        guiFrameLook,
        L["Select_Texture"],
        "raidFrameHealthbarTexture",
        function(arg1)
            BBF.UpdateCustomTextures()
        end,
        { anchorFrame = changeRaidFrameHealthbarTexture, x = 5, y = 3, label = "Texture" }
    )

    changeRaidFrameHealthbarTexture:HookScript("OnClick", function(self)
        raidFrameHealthbarTexture:SetEnabled(self:GetChecked())
        BBF.UpdateCustomTextures()
        if not self:GetChecked() then
            StaticPopup_Show("BBF_CONFIRM_RELOAD")
        end
    end)
    raidFrameHealthbarTexture:SetEnabled(changeRaidFrameHealthbarTexture:GetChecked())

    local changeRaidFrameManabarTexture = CreateCheckbox("changeRaidFrameManabarTexture", L["Tooltip_Change_RaidFrame_Manabar_Texture_Desc"], guiFrameLook)
    changeRaidFrameManabarTexture:SetPoint("TOPLEFT", changeRaidFrameHealthbarTexture, "BOTTOMLEFT", 0, -25)
    CreateTooltipTwo(changeRaidFrameManabarTexture, L["Tooltip_Change_RaidFrame_Manabar_Texture_Desc"], L["Tooltip_Change_RaidFrame_Manabar_Texture_Etc_Desc"])

    local raidFrameManabarTexture = CreateTextureDropdown(
        "raidFrameManabarTexture",
        guiFrameLook,
        L["Select_Texture"],
        "raidFrameManabarTexture",
        function(arg1)
            BBF.UpdateCustomTextures()
        end,
        { anchorFrame = changeRaidFrameManabarTexture, x = 5, y = 3, label = "Texture" }
    )

    changeRaidFrameManabarTexture:HookScript("OnClick", function(self)
        raidFrameManabarTexture:SetEnabled(self:GetChecked())
        BBF.UpdateCustomTextures()
    end)
    raidFrameManabarTexture:SetEnabled(changeRaidFrameManabarTexture:GetChecked())


    local changePartyRaidFrameBackgroundColor = CreateCheckbox("changePartyRaidFrameBackgroundColor", L["Change_RaidFrame_Background_Texture"], guiFrameLook)
    changePartyRaidFrameBackgroundColor:SetPoint("TOPLEFT", changeRaidFrameManabarTexture, "BOTTOMLEFT", 0, -25)
    CreateTooltipTwo(changePartyRaidFrameBackgroundColor, L["Change_RaidFrame_Background_Texture"], L["Tooltip_Change_RaidFrame_Background_Texture_Desc"])

    local raidFrameBgTexture = CreateTextureDropdown(
        "raidFrameBgTexture",
        guiFrameLook,
        L["Select_Texture"],
        "raidFrameBgTexture",
        function(arg1)
            BBF.UpdateCustomTextures()
            BBF.SetCompactUnitFramesBackground()
        end,
        { anchorFrame = changePartyRaidFrameBackgroundColor, x = 5, y = 3, label = "Texture" }
    )

    local partyRaidFrameBackgroundHealthColorFL = CreateColorBox(guiFrameLook, "partyRaidFrameBackgroundHealthColor", "Health BG", function() BBF.SetCompactUnitFramesBackground() end)
    partyRaidFrameBackgroundHealthColorFL:SetPoint("LEFT", raidFrameBgTexture, "RIGHT", 10, 0)
    CreateTooltipTwo(partyRaidFrameBackgroundHealthColorFL, "Party/Raid Health Bar Background Color", "Left-click to change.\n\n|cff32f795Shift+Right-click to reset to default.|r")

    local partyRaidFrameBackgroundManaColorFL = CreateColorBox(guiFrameLook, "partyRaidFrameBackgroundManaColor", "Mana BG", function() BBF.SetCompactUnitFramesBackground() end)
    partyRaidFrameBackgroundManaColorFL:SetPoint("LEFT", partyRaidFrameBackgroundHealthColorFL.text, "RIGHT", 4, 0)
    CreateTooltipTwo(partyRaidFrameBackgroundManaColorFL, "Party/Raid Mana Bar Background Color", "Left-click to change.\n\n|cff32f795Shift+Right-click to reset to default.|r")

    changePartyRaidFrameBackgroundColor:HookScript("OnClick", function(self)
        local alpha = self:GetChecked() and 1 or 0.5
        partyRaidFrameBackgroundHealthColorFL:SetAlpha(alpha)
        partyRaidFrameBackgroundManaColorFL:SetAlpha(alpha)
        raidFrameBgTexture:SetEnabled(self:GetChecked())
        BBF.UpdateCustomTextures()
        BBF.SetCompactUnitFramesBackground()
        BBF.UpdateFrames()
        
        if BBF.changePartyRaidFrameBackgroundColor then
            BBF.changePartyRaidFrameBackgroundColor:SetChecked(self:GetChecked())
            if BBF.changePartyRaidFrameBackgroundColor.parent then
                local clrFx = BBF.changePartyRaidFrameBackgroundColor.parent
                if clrFx.partyRaidFrameBackgroundHealthColor then
                    clrFx.partyRaidFrameBackgroundHealthColor:SetAlpha(alpha)
                end
                if clrFx.partyRaidFrameBackgroundManaColor then
                    clrFx.partyRaidFrameBackgroundManaColor:SetAlpha(alpha)
                end
                if clrFx.raidFrameBgTexture then
                    clrFx.raidFrameBgTexture:SetEnabled(self:GetChecked())
                end
            end
        end
        
        if not self:GetChecked() then
            StaticPopup_Show("BBF_CONFIRM_RELOAD")
        end
    end)
    BBF.changePartyRaidFrameBackgroundColorTexture = changePartyRaidFrameBackgroundColor
    BBF.raidFrameBgTextureDropdown = raidFrameBgTexture
    raidFrameBgTexture:SetEnabled(changePartyRaidFrameBackgroundColor:GetChecked())
    local raidFrameBgAlpha = changePartyRaidFrameBackgroundColor:GetChecked() and 1 or 0.5
    partyRaidFrameBackgroundHealthColorFL:SetAlpha(raidFrameBgAlpha)
    partyRaidFrameBackgroundManaColorFL:SetAlpha(raidFrameBgAlpha)











end

local function guiFrameAuras()
    ----------------------
    -- Frame Auras
    ----------------------
    local guiFrameAuras = CreateFrame("Frame")
    guiFrameAuras.name = L["Module_Name_Auras"]
    guiFrameAuras.parent = BetterBlizzFrames.name
    --InterfaceOptions_AddCategory(guiFrameAuras)
    local aurasSubCategory = Settings.RegisterCanvasLayoutSubcategory(BBF.category, guiFrameAuras, guiFrameAuras.name, guiFrameAuras.name)
    BBF.aurasSubCategory = guiFrameAuras.name
    CreateTitle(guiFrameAuras)

    local bgImg = guiFrameAuras:CreateTexture(nil, "BACKGROUND")
    bgImg:SetAtlas("professions-recipe-background")
    bgImg:SetPoint("CENTER", guiFrameAuras, "CENTER", -8, 4)
    bgImg:SetSize(680, 610)
    bgImg:SetAlpha(0.4)
    bgImg:SetVertexColor(0,0,0)

    local scrollFrame = CreateFrame("ScrollFrame", nil, guiFrameAuras, "UIPanelScrollFrameTemplate")
    scrollFrame:SetSize(700, 612)
    scrollFrame:SetPoint("CENTER", guiFrameAuras, "CENTER", -20, 3)

    local contentFrame = CreateFrame("Frame", nil, scrollFrame)
    contentFrame.name = guiFrameAuras.name
    contentFrame:SetSize(680, 520)
    scrollFrame:SetScrollChild(contentFrame)

    local playerAuraFiltering = CreateCheckbox("playerAuraFiltering", L["Enable_Aura_Settings"], contentFrame)
    playerAuraFiltering.name = guiFrameAuras.name
    CreateTooltipTwo(playerAuraFiltering, L["Enable_Aura_Settings"], L["Tooltip_Enable_Aura_Settings_TargetFocus_Desc"])
    playerAuraFiltering:SetPoint("TOPLEFT", contentFrame, "TOPLEFT", 50, -20)
    playerAuraFiltering:HookScript("OnClick", function (self)
        if self:GetChecked() then
            if BetterBlizzFramesDB.targetToTXPos == 0 then
                StaticPopup_Show("BBF_TOT_MESSAGE")
                BetterBlizzFramesDB.targetToTXPos = 31
                BBF.targetToTXPos:SetValue(31)
                BetterBlizzFramesDB.focusToTXPos = 31
                BBF.focusToTXPos:SetValue(31)
                BBF.MoveToTFrames()
            else
                StaticPopup_Show("BBF_CONFIRM_RELOAD")
            end
        else
            if BetterBlizzFramesDB.targetToTXPos == 31 then
                BBF.Print(L["Chat_Aura_Settings_Off"])
                BetterBlizzFramesDB.targetToTXPos = 0
                BBF.targetToTXPos:SetValue(0)
                BetterBlizzFramesDB.focusToTXPos = 0
                BBF.focusToTXPos:SetValue(0)
                BBF.MoveToTFrames()
            end
            StaticPopup_Show("BBF_CONFIRM_RELOAD")
        end
    end)

    local enableMasque = CreateCheckbox("enableMasque", L["Add_Masque_Support"], contentFrame)
    enableMasque:SetPoint("LEFT", playerAuraFiltering.Text, "RIGHT", 5, 0)
    CreateTooltipTwo(enableMasque, L["Add_Masque_Support"], L["Tooltip_Masque_Support"], L["Tooltip_Masque_Support_Extra"], nil, nil, 4)
    enableMasque:HookScript("OnClick", function()
        StaticPopup_Show("BBF_CONFIRM_RELOAD")
    end)
    enableMasque:Disable()
    enableMasque:SetAlpha(0.5)


    local targetAndFocusAuraSettings = contentFrame:CreateFontString(nil, "OVERLAY", "GameFontNormal")
    targetAndFocusAuraSettings:SetPoint("TOP", playerAuraFiltering, "BOTTOMRIGHT", 50, -5)
    targetAndFocusAuraSettings:SetText(L["Target_And_Focus_Aura_Settings"])

    --------------------------
    -- Frame settings
    --------------------------

    local targetAndFocusAuraScale = CreateSlider(playerAuraFiltering, L["All_Aura_Size"], 0.7, 2, 0.01, "targetAndFocusAuraScale")
    targetAndFocusAuraScale:SetPoint("TOP", targetAndFocusAuraSettings, "BOTTOM", 0, -20)
    CreateTooltip(targetAndFocusAuraScale, L["Tooltip_All_Aura_Size"])

    local targetAndFocusSmallAuraScale = CreateSlider(playerAuraFiltering, L["Small_Aura_Size"], 0.7, 2, 0.01, "targetAndFocusSmallAuraScale")
    targetAndFocusSmallAuraScale:SetPoint("TOP", targetAndFocusAuraScale, "BOTTOM", 0, -20)
    CreateTooltip(targetAndFocusSmallAuraScale, L["Tooltip_Small_Aura_Size"])

    local sameSizeAuras = CreateCheckbox("sameSizeAuras", L["Same_Size"], playerAuraFiltering)
    sameSizeAuras:SetPoint("LEFT", targetAndFocusSmallAuraScale, "RIGHT", 3, 2)
    CreateTooltipTwo(sameSizeAuras, L["Same_Size"], L["Tooltip_Same_Size"])
    sameSizeAuras:HookScript("OnClick", function(self)
        if self:GetChecked() then
            DisableElement(targetAndFocusSmallAuraScale)
        else
            EnableElement(targetAndFocusSmallAuraScale)
        end
    end)
    if BetterBlizzFramesDB.sameSizeAuras then
        DisableElement(targetAndFocusSmallAuraScale)
    end

    local targetAndFocusAurasPerRow = CreateSlider(playerAuraFiltering, L["Max_Auras_Per_Row"], 1, 12, 1, "targetAndFocusAurasPerRow")
    targetAndFocusAurasPerRow:SetPoint("TOPLEFT", targetAndFocusSmallAuraScale, "BOTTOMLEFT", 0, -17)

    local targetAndFocusAuraOffsetX = CreateSlider(playerAuraFiltering, L["X_Offset"], -50, 50, 1, "targetAndFocusAuraOffsetX", "X")
    targetAndFocusAuraOffsetX:SetPoint("TOPLEFT", targetAndFocusAurasPerRow, "BOTTOMLEFT", 0, -17)

    local targetAndFocusAuraOffsetY = CreateSlider(playerAuraFiltering, L["Y_Offset"], -50, 50, 1, "targetAndFocusAuraOffsetY", "Y")
    targetAndFocusAuraOffsetY:SetPoint("TOPLEFT", targetAndFocusAuraOffsetX, "BOTTOMLEFT", 0, -17)

    local targetAndFocusHorizontalGap = CreateSlider(playerAuraFiltering, L["Horizontal_Gap"], 0, 18, 0.5, "targetAndFocusHorizontalGap", "X")
    targetAndFocusHorizontalGap:SetPoint("TOPLEFT", targetAndFocusAuraOffsetY, "BOTTOMLEFT", 0, -17)

    local targetAndFocusVerticalGap = CreateSlider(playerAuraFiltering, L["Vertical_Gap"], 0, 18, 0.5, "targetAndFocusVerticalGap", "Y")
    targetAndFocusVerticalGap:SetPoint("TOPLEFT", targetAndFocusHorizontalGap, "BOTTOMLEFT", 0, -17)

    local auraTypeGap = CreateSlider(playerAuraFiltering, L["Aura_Type_Gap"], 0, 30, 1, "auraTypeGap", "Y")
    auraTypeGap:SetPoint("TOPLEFT", targetAndFocusVerticalGap, "BOTTOMLEFT", 0, -17)
    CreateTooltip(auraTypeGap, L["Tooltip_Aura_Type_Gap"])

    local auraStackSize = CreateSlider(playerAuraFiltering, L["Aura_Stack_Size"], 0.4, 2, 0.01, "auraStackSize")
    auraStackSize:SetPoint("TOPLEFT", auraTypeGap, "BOTTOMLEFT", 0, -17)
    CreateTooltipTwo(auraStackSize, L["Aura_Stack_Size"], L["Tooltip_Aura_Stack_Size"])

    local showAuraCdText = CreateCheckbox("showAuraCdText", L["Show_Aura_Timer_Text"], playerAuraFiltering)
    CreateTooltipTwo(showAuraCdText, L["Show_Aura_Timer_Text"], L["Tooltip_Show_Aura_Timer_Text"])

    local auraCdTextSize = CreateSlider(showAuraCdText, L["Aura_CD_Text_Size"], 0.25, 1.5, 0.01, "auraCdTextSize")
    auraCdTextSize:SetPoint("TOPLEFT", auraStackSize, "BOTTOMLEFT", 0, -17)
    CreateTooltip(auraCdTextSize, L["Tooltip_Aura_CD_Text_Size"])

    showAuraCdText:SetPoint("LEFT", auraCdTextSize, "RIGHT", 3, 2)
    showAuraCdText:HookScript("OnClick", function(self)
        if self:GetChecked() then
            EnableElement(auraCdTextSize)
        else
            DisableElement(auraCdTextSize)
        end
    end)

--[=[
    local maxTargetBuffs = CreateSlider(playerAuraFiltering, L["Max_Buffs"], 1, 32, 1, "maxTargetBuffs")
    maxTargetBuffs:SetPoint("TOPLEFT", targetAndFocusVerticalGap, "BOTTOMLEFT", 0, -17)
    maxTargetBuffs:Disable()
    maxTargetBuffs:SetAlpha(0.5)

    local maxTargetDebuffs = CreateSlider(playerAuraFiltering, L["Max_Debuffs"], 1, 32, 1, "maxTargetDebuffs")
    maxTargetDebuffs:SetPoint("TOPLEFT", maxTargetBuffs, "BOTTOMLEFT", 0, -17)
    maxTargetDebuffs:Disable()
    maxTargetDebuffs:SetAlpha(0.5)

]=]



    local changePurgeTextureColor = CreateCheckbox("changePurgeTextureColor", L["Change_Purge_Texture_Color"], playerAuraFiltering)
    changePurgeTextureColor:SetPoint("TOPLEFT", auraCdTextSize, "BOTTOMLEFT", 0, -2)
    CreateTooltip(changePurgeTextureColor, L["Change_Purge_Texture_Color"])

    local increaseAuraStrata = CreateCheckbox("increaseAuraStrata", L["Increase_Aura_Frame_Strata"], playerAuraFiltering)
    increaseAuraStrata:SetPoint("TOPLEFT", changePurgeTextureColor, "BOTTOMLEFT", 0, pixelsBetweenBoxes)
    CreateTooltipTwo(increaseAuraStrata, L["Increase_Aura_Frame_Strata"], L["Tooltip_Increase_Aura_Frame_Strata"])
    increaseAuraStrata:HookScript("OnClick", function(self)
        if not self:GetChecked() then
            StaticPopup_Show("BBF_CONFIRM_RELOAD")
        end
    end)

    local pixelBorderAuras = CreateCheckbox("pixelBorderAuras", L["Pixel_Border_Auras"], playerAuraFiltering)
    pixelBorderAuras:SetPoint("TOPLEFT", increaseAuraStrata, "BOTTOMLEFT", 0, pixelsBetweenBoxes)
    CreateTooltipTwo(pixelBorderAuras, L["Pixel_Border_Auras"], L["Tooltip_Pixel_Border_Auras_Desc"])
    pixelBorderAuras:HookScript("OnClick", function(self)
        StaticPopup_Show("BBF_CONFIRM_RELOAD")
    end)

    local hideTargetBuffs = CreateCheckbox("hideTargetBuffs", L["Hide_Target_Buffs"], playerAuraFiltering)
    hideTargetBuffs:SetPoint("TOPLEFT", pixelBorderAuras, "BOTTOMLEFT", 0, pixelsBetweenBoxes)
    CreateTooltipTwo(hideTargetBuffs, L["Hide_Target_Buffs"], L["Tooltip_Hide_Target_Buffs_Desc"])
    hideTargetBuffs:HookScript("OnClick", function(self)
        StaticPopup_Show("BBF_CONFIRM_RELOAD")
    end)

    local hideTargetDebuffs = CreateCheckbox("hideTargetDebuffs", L["Hide_Target_Debuffs"], playerAuraFiltering)
    hideTargetDebuffs:SetPoint("TOPLEFT", hideTargetBuffs, "BOTTOMLEFT", 0, pixelsBetweenBoxes)
    CreateTooltipTwo(hideTargetDebuffs, L["Hide_Target_Debuffs"], L["Tooltip_Hide_Target_Debuffs_Desc"])
    hideTargetDebuffs:HookScript("OnClick", function(self)
        StaticPopup_Show("BBF_CONFIRM_RELOAD")
    end)

    local hideFocusBuffs = CreateCheckbox("hideFocusBuffs", L["Hide_Focus_Buffs"], playerAuraFiltering)
    hideFocusBuffs:SetPoint("TOPLEFT", hideTargetDebuffs, "BOTTOMLEFT", 0, pixelsBetweenBoxes)
    CreateTooltipTwo(hideFocusBuffs, L["Hide_Focus_Buffs"], L["Tooltip_Hide_Focus_Buffs_Desc"])
    hideFocusBuffs:HookScript("OnClick", function(self)
        StaticPopup_Show("BBF_CONFIRM_RELOAD")
    end)

    local hideFocusDebuffs = CreateCheckbox("hideFocusDebuffs", L["Hide_Focus_Debuffs"], playerAuraFiltering)
    hideFocusDebuffs:SetPoint("TOPLEFT", hideFocusBuffs, "BOTTOMLEFT", 0, pixelsBetweenBoxes)
    CreateTooltipTwo(hideFocusDebuffs, L["Hide_Focus_Debuffs"], L["Tooltip_Hide_Focus_Debuffs_Desc"])
    hideFocusDebuffs:HookScript("OnClick", function(self)
        StaticPopup_Show("BBF_CONFIRM_RELOAD")
    end)


    local function OpenColorPicker(entryColors)
        local colorData = entryColors or {0, 1, 0, 1}
        local r, g, b = colorData[1] or 1, colorData[2] or 1, colorData[3] or 1
        local a = colorData[4] or 1

        local function updateColors(newR, newG, newB, newA)
            entryColors[1] = newR
            entryColors[2] = newG
            entryColors[3] = newB
            entryColors[4] = newA or 1

            BBF.RefreshAllAuraFrames()
        end

        local function swatchFunc()
            r, g, b = ColorPickerFrame:GetColorRGB()
            updateColors(r, g, b, a)
        end

        local function opacityFunc()
            a = ColorPickerFrame:GetColorAlpha()
            updateColors(r, g, b, a)
        end

        local function cancelFunc(previousValues)
            if previousValues then
                r, g, b, a = previousValues.r, previousValues.g, previousValues.b, previousValues.a
                updateColors(r, g, b, a)
            end
        end

        ColorPickerFrame.previousValues = { r = r, g = g, b = b, a = a }

        ColorPickerFrame:SetupColorPickerAndShow({
            r = r, g = g, b = b, opacity = a, hasOpacity = true,
            swatchFunc = swatchFunc, opacityFunc = opacityFunc, cancelFunc = cancelFunc
        })
    end

    local dispelGlowButton = CreateFrame("Button", nil, playerAuraFiltering, "UIPanelButtonTemplate")
    dispelGlowButton:SetText(L["Color"])
    dispelGlowButton:SetPoint("LEFT", changePurgeTextureColor.text, "RIGHT", -1, 0)
    dispelGlowButton:SetSize(43, 18)
    dispelGlowButton:SetScript("OnClick", function()
        OpenColorPicker(BetterBlizzFramesDB.purgeTextureColorRGB)
    end)
    CreateTooltip(dispelGlowButton, L["Change_Purge_Texture_Color"])


    playerAuraFiltering:HookScript("OnClick", function (self)
        if self:GetChecked() then
            --asd
        else
            StaticPopup_Show("BBF_CONFIRM_RELOAD")
        end

        CheckAndToggleCheckboxes(playerAuraFiltering)
    end)

    local playerAuraSettings = contentFrame:CreateFontString(nil, "OVERLAY", "GameFontNormal")
    playerAuraSettings:SetPoint("TOP", playerAuraFiltering, "BOTTOMRIGHT", 350, -5)
    playerAuraSettings:SetText(L["Player_Aura_Settings"])

    local enablePlayerBuffFiltering = CreateCheckbox("enablePlayerBuffFiltering", L["Enable_Player_Aura_Adjustments"], playerAuraFiltering)
    enablePlayerBuffFiltering:SetPoint("TOPLEFT", playerAuraSettings, "BOTTOMLEFT", -10, 0)

    local playerAuraSpacingX = CreateSlider(enablePlayerBuffFiltering, L["Horizontal_Padding"], 0, 10, 1, "playerAuraSpacingX", "X")
    playerAuraSpacingX:SetPoint("TOP", playerAuraSettings, "BOTTOM", 0, -40)
    CreateTooltip(playerAuraSpacingX, L["Tooltip_Horizontal_Aura_Padding"], "ANCHOR_LEFT")

    local playerAuraSpacingY = CreateSlider(enablePlayerBuffFiltering, L["Vertical_Padding"], -10, 10, 1, "playerAuraSpacingY", "Y")
    playerAuraSpacingY:SetPoint("TOP", playerAuraSpacingX, "BOTTOM", 0, -15)

    enablePlayerBuffFiltering:HookScript("OnClick", function (self)
        CheckAndToggleCheckboxes(enablePlayerBuffFiltering)
        if not self:GetChecked() then
            StaticPopup_Show("BBF_CONFIRM_RELOAD")
        end
    end)

    local betaHighlightIcon = playerAuraFiltering:CreateTexture(nil, "BACKGROUND")
    betaHighlightIcon:SetAtlas("CharacterCreate-NewLabel")
    betaHighlightIcon:SetSize(42, 34)
    betaHighlightIcon:SetPoint("RIGHT", playerAuraFiltering, "LEFT", 8, 0)
end

local function guiMisc()
    local guiMisc = CreateFrame("Frame")
    guiMisc.name = L["Module_Name_Misc"]
    guiMisc.parent = BetterBlizzFrames.name
    --InterfaceOptions_AddCategory(guiMisc)
    local guiMiscSubcategory = Settings.RegisterCanvasLayoutSubcategory(BBF.category, guiMisc, guiMisc.name, guiMisc.name)
    guiMiscSubcategory.ID = guiMisc.name;
    CreateTitle(guiMisc)

    local bgImg = guiMisc:CreateTexture(nil, "BACKGROUND")
    bgImg:SetAtlas("professions-recipe-background")
    bgImg:SetPoint("CENTER", guiMisc, "CENTER", -8, 4)
    bgImg:SetSize(680, 610)
    bgImg:SetAlpha(0.4)
    bgImg:SetVertexColor(0,0,0)

    local settingsText = guiMisc:CreateFontString(nil, "OVERLAY", "GameFontNormal")
    settingsText:SetPoint("TOPLEFT", guiMisc, "TOPLEFT", 20, 0)
    settingsText:SetText(L["Misc_Settings"])
    local miscSettingsIcon = guiMisc:CreateTexture(nil, "ARTWORK")
    miscSettingsIcon:SetAtlas("optionsicon-brown")
    miscSettingsIcon:SetSize(22, 22)
    miscSettingsIcon:SetPoint("RIGHT", settingsText, "LEFT", -3, -1)

    local enableBigDebuffs = CreateCheckbox("enableBigDebuffs", L["Enable_Big_Debuffs"], guiMisc, nil, BBF.EnableBigDebuffs)
    enableBigDebuffs:SetPoint("TOPLEFT", settingsText, "BOTTOMLEFT", -4, pixelsOnFirstBox)
    CreateTooltipTwo(enableBigDebuffs, L["Enable_Big_Debuffs"], L["Tooltip_Big_Debuffs_Desc"])

    local normalizeGameMenu = CreateCheckbox("normalizeGameMenu", L["Normal_Size_Game_Menu"], guiMisc)
    normalizeGameMenu:SetPoint("TOPLEFT", enableBigDebuffs, "BOTTOMLEFT", 0, pixelsBetweenBoxes)
    CreateTooltipTwo(normalizeGameMenu, L["Normal_Size_Game_Menu"], L["Tooltip_Normal_Size_Game_Menu_Desc"])
    normalizeGameMenu:HookScript("OnClick", function(self)
        if self:GetChecked() then
            BBF.NormalizeGameMenu(true)
        else
            BBF.NormalizeGameMenu(false)
        end
    end)

    local classColorFriendlist = CreateCheckbox("classColorFriendlist", L["Class_Color_Friendlist"], guiMisc)
    classColorFriendlist:SetPoint("TOPLEFT", normalizeGameMenu, "BOTTOMLEFT", 0, pixelsBetweenBoxes)
    CreateTooltipTwo(classColorFriendlist, L["Class_Color_Friendlist"], L["Tooltip_Class_Color_Friendlist_Desc"])
    classColorFriendlist:HookScript("OnClick", function(self)
        StaticPopup_Show("BBF_CONFIRM_RELOAD")
    end)

    local minimizeObjectiveTracker = CreateCheckbox("minimizeObjectiveTracker", L["Minimize_Objective_Better"], guiMisc, nil, BBF.MinimizeObjectiveTracker)
    minimizeObjectiveTracker:SetPoint("TOPLEFT", classColorFriendlist, "BOTTOMLEFT", 0, pixelsBetweenBoxes)
    CreateTooltipTwo(minimizeObjectiveTracker, L["Minimize_Objective_Better"], L["Tooltip_Minimize_Objective_Better_Desc"] .. " |A:UI-QuestTrackerButton-Collapse-All:19:19|a")

    local hideUiErrorFrame = CreateCheckbox("hideUiErrorFrame", L["Hide_UI_Error_Frame"], guiMisc, nil, BBF.HideFrames)
    hideUiErrorFrame:SetPoint("TOPLEFT", minimizeObjectiveTracker, "BOTTOMLEFT", 0, pixelsBetweenBoxes)
    CreateTooltipTwo(hideUiErrorFrame, L["Hide_UI_Error_Frame"], L["Tooltip_Hide_UI_Error"])

    local fadeMicroMenu = CreateCheckbox("fadeMicroMenu", L["Fade_Micro_Menu"], guiMisc, nil, BBF.FadeMicroMenu)
    fadeMicroMenu:SetPoint("TOPLEFT", hideUiErrorFrame, "BOTTOMLEFT", 0, pixelsBetweenBoxes)
    CreateTooltipTwo(fadeMicroMenu, L["Fade_Micro_Menu"], L["Tooltip_Fade_Micro_Menu_Desc"])

    local fadeMicroMenuExceptQueue = CreateCheckbox("fadeMicroMenuExceptQueue", L["Except_Queue_Eye"], fadeMicroMenu, nil, BBF.FadeMicroMenu)
    fadeMicroMenuExceptQueue:SetPoint("LEFT", fadeMicroMenu.text, "RIGHT", 0, 0)
    CreateTooltipTwo(fadeMicroMenuExceptQueue, L["Except_Queue_Eye"], L["Tooltip_Except_Queue_Eye_Desc"])

    fadeMicroMenu:HookScript("OnClick", function(self)
        CheckAndToggleCheckboxes(self)
        if not self:GetChecked() then
            StaticPopup_Show("BBF_CONFIRM_RELOAD")
        end
    end)

    local moveQueueStatusEye = CreateCheckbox("moveQueueStatusEye", L["Move_Queue_Eye"], guiMisc, nil, BBF.MoveQueueStatusEye)
    moveQueueStatusEye:SetPoint("TOPLEFT", fadeMicroMenu, "BOTTOMLEFT", 0, pixelsBetweenBoxes)
    CreateTooltipTwo(moveQueueStatusEye, L["Move_Queue_Eye"], L["Tooltip_Move_Queue_Eye_Desc"])

    moveQueueStatusEye:HookScript("OnClick", function(self)
        if not self:GetChecked() then
            StaticPopup_Show("BBF_CONFIRM_RELOAD")
        end
    end)

    local reduceEditModeSelectionAlpha = CreateCheckbox("reduceEditModeSelectionAlpha", L["Reduce_Edit_Mode_Glow"], guiMisc)
    reduceEditModeSelectionAlpha:SetPoint("TOPLEFT", moveQueueStatusEye, "BOTTOMLEFT", 0, pixelsBetweenBoxes)
    CreateTooltipTwo(reduceEditModeSelectionAlpha, L["Reduce_Edit_Mode_Glow"], L["Tooltip_Reduce_Edit_Mode_Glow_Desc"])
    reduceEditModeSelectionAlpha:HookScript("OnClick", function(self)
        if self:GetChecked() then
            BetterBlizzFramesDB.editModeSelectionAlpha = 0.15
            BBF.ReduceEditModeAlpha()
            if BBF.EditModeAlphaSlider then
                BBF.EditModeAlphaSlider:SetValue(0.15)
            end
        else
            BetterBlizzFramesDB.editModeSelectionAlpha = 1
            BBF.ReduceEditModeAlpha(true)
            if BBF.EditModeAlphaSlider then
                BBF.EditModeAlphaSlider:SetValue(1)
            end
        end
    end)

    local hideBagsBar = CreateCheckbox("hideBagsBar", L["Hide_Bags_Bar"], guiMisc, nil, BBF.HideFrames)
    hideBagsBar:SetPoint("TOPLEFT", reduceEditModeSelectionAlpha, "BOTTOMLEFT", 0, pixelsBetweenBoxes)
    CreateTooltipTwo(hideBagsBar, L["Hide_Bags_Bar"], L["Tooltip_Hide_Bags_Bar_Desc"])

    hideBagsBar:HookScript("OnClick", function(self)
        if not self:GetChecked() then
            StaticPopup_Show("BBF_CONFIRM_RELOAD")
        end
    end)

    local showLastNameNpc = CreateCheckbox("showLastNameNpc", L["Tooltip_Only_Last_Name_NPCs_Desc"], guiMisc, nil, BBF.AllNameChanges)
    showLastNameNpc:SetPoint("TOPLEFT", hideBagsBar, "BOTTOMLEFT", 0, pixelsBetweenBoxes)
    CreateTooltipTwo(showLastNameNpc, L["Tooltip_Only_Last_Name_NPCs_Desc"], L["Tooltip_Only_Last_Name_NPCs_Simple_Desc"])


    local moveableFPSCounter = CreateCheckbox("moveableFPSCounter", L["Moveable_FPS_Counter"], guiMisc, nil, BBF.MoveableFPSCounter)
    moveableFPSCounter:SetPoint("TOPLEFT", showLastNameNpc, "BOTTOMLEFT", 0, pixelsBetweenBoxes)
    CreateTooltipTwo(moveableFPSCounter, L["Moveable_FPS_Counter"], L["Tooltip_Moveable_FPS_Counter_Desc"])
    moveableFPSCounter:SetScript("OnMouseDown", function(self, button)
        if button == "RightButton" then
            if IsShiftKeyDown() then
                BetterBlizzFramesDB.fpsCounterFontOutline = true
                BBF.MoveableFPSCounter(false, true)
            else
                BetterBlizzFramesDB.fpsCounterFontOutline = nil
                BBF.MoveableFPSCounter(true)
            end
        end
    end)

    local removeAddonListCategories = CreateCheckbox("removeAddonListCategories", L["Improved_AddonList"], guiMisc, nil, BBF.RemoveAddonCategories)
    removeAddonListCategories:SetPoint("TOPLEFT", moveableFPSCounter, "BOTTOMLEFT", 0, pixelsBetweenBoxes)
    CreateTooltipTwo(removeAddonListCategories, L["Improved_AddonList"], L["Tooltip_Improved_AddonList_Desc"])

    local hideMinimap = CreateCheckbox("hideMinimap", L["Hide_Minimap"], guiMisc, nil, BBF.MinimapHider)
    hideMinimap:SetPoint("TOPLEFT", removeAddonListCategories, "BOTTOMLEFT", 0, pixelsBetweenBoxes)

    local hideMinimapButtons = CreateCheckbox("hideMinimapButtons", L["Hide_Minimap_Buttons"], guiMisc, nil, BBF.HideFrames)
    hideMinimapButtons:SetPoint("TOPLEFT", hideMinimap, "BOTTOMLEFT", 0, pixelsBetweenBoxes)
    hideMinimapButtons:HookScript("OnClick", function(self)
        if not self:GetChecked() then
            StaticPopup_Show("BBF_CONFIRM_RELOAD")
        end
    end)

    local hideMinimapAuto = CreateCheckbox("hideMinimapAuto", L["Hide_Minimap_Arena"], guiMisc)
    hideMinimapAuto:SetPoint("TOPLEFT", hideMinimapButtons, "BOTTOMLEFT", 0, pixelsBetweenBoxes)
    CreateTooltip(hideMinimapAuto, L["Tooltip_Minimap_Arena"])
    hideMinimapAuto:HookScript("OnClick", function()
        CheckAndToggleCheckboxes(hideMinimapAuto)
        BBF.MinimapHider()
    end)

    local hideMinimapAutoQueueEye = CreateCheckbox("hideMinimapAutoQueueEye", L["Hide_Queue_Eye_Arena"], guiMisc)
    hideMinimapAutoQueueEye:SetPoint("TOPLEFT", hideMinimapAuto, "BOTTOMLEFT", 0, pixelsBetweenBoxes)
    CreateTooltip(hideMinimapAutoQueueEye, L["Tooltip_Queue_Eye_Arena"])
    hideMinimapAutoQueueEye:HookScript("OnClick", function()
        BBF.MinimapHider()
    end)

    local hideObjectiveTracker = CreateCheckbox("hideObjectiveTracker", L["Hide_Objective_Arena"], guiMisc)
    hideObjectiveTracker:SetPoint("TOPLEFT", hideMinimapAutoQueueEye, "BOTTOMLEFT", 0, pixelsBetweenBoxes)
    CreateTooltip(hideObjectiveTracker, L["Tooltip_Objective_Arena"])
    hideObjectiveTracker:HookScript("OnClick", function()
        BBF.MinimapHider()
    end)

    local recolorTempHpLoss = CreateCheckbox("recolorTempHpLoss", L["Recolor_Temp_HP"], guiMisc)
    recolorTempHpLoss:SetPoint("TOPLEFT", hideObjectiveTracker, "BOTTOMLEFT", 0, pixelsBetweenBoxes)
    CreateTooltipTwo(recolorTempHpLoss, L["Recolor_Temp_HP"], L["Tooltip_Recolor_Temp_HP_Desc"])
    recolorTempHpLoss:HookScript("OnClick", function()
        BBF.RecolorHpTempLoss()
    end)

    local hideAllAbsorbGlow = CreateCheckbox("hideAllAbsorbGlow", L["Hide_All_Absorb_Glow"], guiMisc)
    hideAllAbsorbGlow:SetPoint("TOPLEFT", recolorTempHpLoss, "BOTTOMLEFT", 0, pixelsBetweenBoxes)
    CreateTooltipTwo(hideAllAbsorbGlow, L["Hide_All_Absorb_Glow"], L["Tooltip_Hide_All_Absorb_Glow_Desc"])
    hideAllAbsorbGlow:HookScript("OnClick", function()
        StaticPopup_Show("BBF_CONFIRM_RELOAD")
    end)

    local zoomActionBarIcons = CreateCheckbox("zoomActionBarIcons", "Zoom ActionBar Icons", guiMisc)
    zoomActionBarIcons:SetPoint("TOPLEFT", hideAllAbsorbGlow, "BOTTOMLEFT", 0, pixelsBetweenBoxes)
    CreateTooltipTwo(zoomActionBarIcons, "Zoom ActionBar Icons", "Zoom in on the icons on the action bar icons a little.")
    zoomActionBarIcons:HookScript("OnClick", function()
        BBF.ZoomDefaultActionbarIcons(zoomActionBarIcons:GetChecked())
    end)

    local hideActionBarHotKey = CreateCheckbox("hideActionBarHotKey", L["Hide_ActionBar_Keybinds"], guiMisc, nil, BBF.HideFrames)
    hideActionBarHotKey:SetPoint("TOPLEFT", zoomActionBarIcons, "BOTTOMLEFT", 0, pixelsBetweenBoxes)
    CreateTooltip(hideActionBarHotKey, L["Tooltip_Hide_Keybinds"])

    local hideActionBarMacroName = CreateCheckbox("hideActionBarMacroName", L["Hide_ActionBar_Macro"], guiMisc, nil, BBF.HideFrames)
    hideActionBarMacroName:SetPoint("TOPLEFT", hideActionBarHotKey, "BOTTOMLEFT", 0, pixelsBetweenBoxes)
    CreateTooltip(hideActionBarMacroName, L["Tooltip_Hide_Macro"])

    local hideActionBarQualityIcon = CreateCheckbox("hideActionBarQualityIcon", L["Hide_ActionBar_Quality"], guiMisc, nil, BBF.HideFrames)
    hideActionBarQualityIcon:SetPoint("TOPLEFT", hideActionBarMacroName, "BOTTOMLEFT", 0, pixelsBetweenBoxes)
    CreateTooltip(hideActionBarQualityIcon, L["Tooltip_Hide_Quality"])

    local hideStanceBar = CreateCheckbox("hideStanceBar", L["Hide_StanceBar"], guiMisc, nil, BBF.HideFrames)
    hideStanceBar:SetPoint("TOPLEFT", hideActionBarQualityIcon, "BOTTOMLEFT", 0, pixelsBetweenBoxes)

    local hideDragonFlying = CreateCheckbox("hideDragonFlying", L["Auto_Hide_Dragonriding"], guiMisc)
    hideDragonFlying:SetPoint("TOPLEFT", hideStanceBar, "BOTTOMLEFT", 0, pixelsBetweenBoxes)
    CreateTooltip(hideDragonFlying, L["Tooltip_Dragonriding"])

    local stealthIndicatorPlayer = CreateCheckbox("stealthIndicatorPlayer", L["Tooltip_Stealth_Indicator"], guiMisc, nil, BBF.StealthIndicator)
    stealthIndicatorPlayer:SetPoint("TOPLEFT", hideDragonFlying, "BOTTOMLEFT", 0, pixelsBetweenBoxes)
    stealthIndicatorPlayer:HookScript("OnClick", function(self)
        if not self:GetChecked() then
            StaticPopup_Show("BBF_CONFIRM_RELOAD")
        end
    end)
    CreateTooltip(stealthIndicatorPlayer, L["Tooltip_Stealth"])

    local useMiniPlayerFrame = CreateCheckbox("useMiniPlayerFrame", L["Mini_PlayerFrame"], guiMisc)
    useMiniPlayerFrame:SetPoint("TOPLEFT", stealthIndicatorPlayer, "BOTTOMLEFT", 0, pixelsBetweenBoxes)
    CreateTooltip(useMiniPlayerFrame, L["Tooltip_Mini_Player"])
    useMiniPlayerFrame:HookScript("OnClick", function(self)
        BBF.MiniFrame(PlayerFrame)
        if not self:GetChecked() then
            StaticPopup_Show("BBF_CONFIRM_RELOAD")
        end
    end)

    local useMiniTargetFrame = CreateCheckbox("useMiniTargetFrame", L["Mini_TargetFrame"], guiMisc)
    useMiniTargetFrame:SetPoint("LEFT", useMiniPlayerFrame.Text, "RIGHT", 0, 0)
    CreateTooltip(useMiniTargetFrame, L["Tooltip_Mini_Target"])
    useMiniTargetFrame:HookScript("OnClick", function(self)
        BBF.MiniFrame(TargetFrame)
        if not self:GetChecked() then
            StaticPopup_Show("BBF_CONFIRM_RELOAD")
        end
    end)

    local useMiniFocusFrame = CreateCheckbox("useMiniFocusFrame", L["Mini_FocusFrame"], guiMisc)
    useMiniFocusFrame:SetPoint("LEFT", useMiniTargetFrame.Text, "RIGHT", 0, 0)
    CreateTooltip(useMiniFocusFrame, L["Tooltip_Mini_Focus"])
    useMiniFocusFrame:HookScript("OnClick", function(self)
        BBF.MiniFrame(FocusFrame)
        if not self:GetChecked() then
            StaticPopup_Show("BBF_CONFIRM_RELOAD")
        end
    end)

    local surrenderArena = CreateCheckbox("surrenderArena", L["Surrender_Arena"], guiMisc)
    surrenderArena:SetPoint("TOPLEFT", useMiniPlayerFrame, "BOTTOMLEFT", 0, pixelsBetweenBoxes)
    CreateTooltipTwo(surrenderArena, L["Surrender_Arena"], L["Tooltip_Surrender_Arena_Desc"])

    -- local druidOverstacks = CreateCheckbox("druidOverstacks", L["Druid_Berserk_Blue"], guiMisc)
    -- druidOverstacks:SetPoint("TOPLEFT", surrenderArena, "BOTTOMLEFT", 0, pixelsBetweenBoxes)
    -- CreateTooltipTwo(druidOverstacks, L["Druid_Berserk_Blue"], L["Tooltip_Druid_Berserk"])
    -- druidOverstacks:HookScript("OnClick", function(self)
    --     BBF.DruidBlueComboPoints()
    --     if not self:GetChecked() then
    --         StaticPopup_Show("BBF_CONFIRM_RELOAD")
    --     end
    -- end) -- isMidnight

    local druidAlwaysShowCombos = CreateCheckbox("druidAlwaysShowCombos", L["Druid_Always_Combos"], guiMisc)
    druidAlwaysShowCombos:SetPoint("TOPLEFT", surrenderArena, "BOTTOMLEFT", 0, pixelsBetweenBoxes)
    CreateTooltipTwo(druidAlwaysShowCombos, L["Druid_Always_Combos"], L["Tooltip_Druid_Always_Combos_Desc"])
    druidAlwaysShowCombos:HookScript("OnClick", function(self)
        BBF.DruidAlwaysShowCombos()
        if not self:GetChecked() then
            StaticPopup_Show("BBF_CONFIRM_RELOAD")
        end
    end)

    local createAltManaBarDruid = CreateCheckbox("createAltManaBarDruid", L["Druid_Manabar_CatBear"], guiMisc)
    createAltManaBarDruid:SetPoint("TOPLEFT", druidAlwaysShowCombos, "BOTTOMLEFT", 0, pixelsBetweenBoxes)
    CreateTooltipTwo(createAltManaBarDruid, L["Druid_Manabar_CatBear"], L["Tooltip_Druid_Manabar_Desc"])
        createAltManaBarDruid:HookScript("OnClick", function(self)
        BBF.CreateAltManaBar()
        if not self:GetChecked() then
            StaticPopup_Show("BBF_CONFIRM_RELOAD")
        end
    end)

    local hideTalkingHeads = CreateCheckbox("hideTalkingHeads", L["Hide_Talking_Heads"], guiMisc, nil, BBF.HideTalkingHeads)
    hideTalkingHeads:SetPoint("TOPLEFT", createAltManaBarDruid, "BOTTOMLEFT", 0, pixelsBetweenBoxes)
    CreateTooltipTwo(hideTalkingHeads, L["Hide_Talking_Heads"], L["Tooltip_Hide_Talking_Heads_Desc"])
    hideTalkingHeads:HookScript("OnClick", function(self)
        if not self:GetChecked() then
            StaticPopup_Show("BBF_CONFIRM_RELOAD")
        end
    end)

    local hideExpAndHonorBar = CreateCheckbox("hideExpAndHonorBar", L["Hide_XP_Honor"], guiMisc, nil, BBF.HideFrames)
    hideExpAndHonorBar:SetPoint("TOPLEFT", hideTalkingHeads, "BOTTOMLEFT", 0, pixelsBetweenBoxes)
    CreateTooltipTwo(hideExpAndHonorBar, L["Hide_XP_Honor"], L["Tooltip_Hide_XP_Honor_Desc"])
    hideExpAndHonorBar:HookScript("OnClick", function(self)
        if not self:GetChecked() then
            StaticPopup_Show("BBF_CONFIRM_RELOAD")
        end
    end)

    local disableCastbarMovement = CreateCheckbox("disableCastbarMovement", L["Disable_Castbar_Movement"], guiMisc, nil, BBF.HideFrames)
    disableCastbarMovement:SetPoint("TOPLEFT", hideExpAndHonorBar, "BOTTOMLEFT", 0, pixelsBetweenBoxes)
    CreateTooltipTwo(disableCastbarMovement, L["Disable_Castbar_Movement"], L["Tooltip_Disable_Castbar_Movement_Desc"])
    disableCastbarMovement:HookScript("OnClick", function(self)
        StaticPopup_Show("BBF_CONFIRM_RELOAD")
    end)

    -- local disableAddonProfiling = CreateCheckbox("disableAddonProfiling", "Disable AddOn Profiler", guiMisc)
    -- disableAddonProfiling:SetPoint("TOPLEFT", hideExpAndHonorBar, "BOTTOMLEFT", 0, pixelsBetweenBoxes)
    -- CreateTooltipTwo(disableAddonProfiling, L["Disable_AddOn_Profiler"], L["Tooltip_Disable_AddOn_Profiler"])
    -- disableAddonProfiling:HookScript("OnClick", function(self)
    --     StaticPopup_Show("BBF_CONFIRM_RELOAD")
    -- end)

    local arenaOptimizer = CreateCheckbox("arenaOptimizer", L["Arena_Optimizer"], guiMisc)
    arenaOptimizer:SetPoint("TOPLEFT", disableCastbarMovement, "BOTTOMLEFT", 0, pixelsBetweenBoxes)
    CreateTooltipTwo(arenaOptimizer, L["Arena_Optimizer"], L["Tooltip_Arena_Optimizer"])
    arenaOptimizer:HookScript("OnClick", function(self)
        BBF.ArenaOptimizer(not self:GetChecked(), true)
        StaticPopup_Show("BBF_CONFIRM_RELOAD")
    end)

    local gladWinTracker = CreateCheckbox("gladWinTracker", L["Glad_Win_Tracker"], guiMisc)
    gladWinTracker:SetPoint("TOPLEFT", arenaOptimizer, "BOTTOMLEFT", 0, pixelsBetweenBoxes)
    CreateTooltipTwo(gladWinTracker, L["Glad_Win_Tracker"], L["Tooltip_Glad_Tracker"])
    gladWinTracker:HookScript("OnClick", function(self)
        BBF.GladWinTracker()
        if not self:GetChecked() then
            StaticPopup_Show("BBF_CONFIRM_RELOAD")
        end
    end)

    local uiWidgetPowerBarScale = CreateSlider(guiMisc, L["UIWidgetPowerBarFrame_Scale"], 0.4, 1.8, 0.01, "uiWidgetPowerBarScale")
    uiWidgetPowerBarScale:SetPoint("LEFT", gladWinTracker.text, "RIGHT", 55, 0)
    CreateTooltipTwo(uiWidgetPowerBarScale, L["UIWidgetPowerBarFrame_Scale"], L["Tooltip_UIWidgetPowerBar_Scale_Desc"])

    local hideUnitFramePlayerMana = CreateCheckbox("hideUnitFramePlayerMana", L["Hide_PlayerFrame_Mana"], guiMisc, nil, BBF.UpdateNoPortraitManaVisibility)
    hideUnitFramePlayerMana:SetPoint("TOPLEFT", settingsText, "BOTTOMLEFT", 320, pixelsOnFirstBox)
    CreateTooltipTwo(hideUnitFramePlayerMana, L["Hide_PlayerFrame_Mana"], L["Tooltip_Hide_Player_Mana"])

    local hideUnitFramePlayerSecondResource = CreateCheckbox("hideUnitFramePlayerSecondResource", L["Hide_PlayerFrame_2nd_Bar"], guiMisc, nil, BBF.UpdateNoPortraitManaVisibility)
    hideUnitFramePlayerSecondResource:SetPoint("TOPLEFT", hideUnitFramePlayerMana, "BOTTOMLEFT", 0, pixelsBetweenBoxes)
    CreateTooltipTwo(hideUnitFramePlayerSecondResource, L["Hide_PlayerFrame_2nd_Bar"], L["Tooltip_Hide_2nd_Bar"])

    local hideUnitFrameTargetMana = CreateCheckbox("hideUnitFrameTargetMana", L["Hide_TargetFrame_Mana"], guiMisc, nil, BBF.UpdateNoPortraitManaVisibility)
    hideUnitFrameTargetMana:SetPoint("TOPLEFT", hideUnitFramePlayerSecondResource, "BOTTOMLEFT", 0, pixelsBetweenBoxes)
    CreateTooltipTwo(hideUnitFrameTargetMana, L["Hide_TargetFrame_Mana"], L["Tooltip_Hide_Target_Mana"])

    local hideUnitFrameFocusMana = CreateCheckbox("hideUnitFrameFocusMana", L["Hide_FocusFrame_Mana"], guiMisc, nil, BBF.UpdateNoPortraitManaVisibility)
    hideUnitFrameFocusMana:SetPoint("TOPLEFT", hideUnitFrameTargetMana, "BOTTOMLEFT", 0, pixelsBetweenBoxes)
    CreateTooltipTwo(hideUnitFrameFocusMana, L["Hide_FocusFrame_Mana"], L["Tooltip_Hide_Focus_Mana"])

    local hideDefaultPartyFramesMana = CreateCheckbox("hideDefaultPartyFramesMana", L["Hide_Default_PartyFrames_Mana"], guiMisc, nil, BBF.UpdateNoPortraitManaVisibility)
    hideDefaultPartyFramesMana:SetPoint("TOPLEFT", hideUnitFrameFocusMana, "BOTTOMLEFT", 0, pixelsBetweenBoxes)
    CreateTooltipTwo(hideDefaultPartyFramesMana, L["Hide_Default_PartyFrames_Mana"], L["Tooltip_Hide_Default_PartyFrames_Mana_Desc"])

    local cdManagerCenterIcons = CreateCheckbox("cdManagerCenterIcons", L["CDM_Center_Icons"], guiMisc, nil, BBF.HookCooldownManagerTweaks)
    cdManagerCenterIcons:SetPoint("TOPLEFT", hideDefaultPartyFramesMana, "BOTTOMLEFT", 0, pixelsBetweenBoxes)
    CreateTooltipTwo(cdManagerCenterIcons, L["CDM_Center_Icons"], L["CDM_Center_Icons_Tooltip"])
    cdManagerCenterIcons:HookScript("OnClick", function(self)
        StaticPopup_Show("BBF_CONFIRM_RELOAD")
    end)

    local hideOgRaidFrameBg = CreateCheckbox("hideOgRaidFrameBg", L["Hide_Party_RaidFrame_Background"], guiMisc, nil, BBF.HideFrames)
    hideOgRaidFrameBg:SetPoint("TOPLEFT", cdManagerCenterIcons, "BOTTOMLEFT", 0, pixelsBetweenBoxes)
    CreateTooltipTwo(hideOgRaidFrameBg, L["Hide_Party_RaidFrame_Background"], L["Tooltip_Hide_Party_RaidFrame_Background_Desc"])

    local hideActionBar1 = CreateCheckbox("hideActionBar1", L["Hide_ActionBar1"], guiMisc, nil, BBF.HideFrames)
    hideActionBar1:SetPoint("TOPLEFT", hideOgRaidFrameBg, "BOTTOMLEFT", 0, pixelsBetweenBoxes)
    CreateTooltipTwo(hideActionBar1, L["Hide_ActionBar1"], L["Tooltip_Hide_ActionBar1"])

    local hideActionBarBigProcGlow = CreateCheckbox("hideActionBarBigProcGlow", L["Hide_ActionBar_Big_Proc_Glow"], guiMisc, nil, BBF.ActionBarMods)
    hideActionBarBigProcGlow:SetPoint("TOPLEFT", hideActionBar1, "BOTTOMLEFT", 0, pixelsBetweenBoxes)
    CreateTooltipTwo(hideActionBarBigProcGlow, L["Hide_Actionbar_Big_Proc_Glow"], L["Tooltip_Hide_ActionBar_Big_Proc_Glow_Desc"])

    local hideActionBarCastAnimation = CreateCheckbox("hideActionBarCastAnimation", L["Hide_ActionBar_Cast_Animation"], guiMisc, nil, BBF.ActionBarMods)
    hideActionBarCastAnimation:SetPoint("TOPLEFT", hideActionBarBigProcGlow, "BOTTOMLEFT", 0, pixelsBetweenBoxes)
    CreateTooltipTwo(hideActionBarCastAnimation, L["Hide_ActionBar_Cast_Animation"], L["Tooltip_Hide_ActionBar_Cast_Animation_Desc"])

    local hideActionBarActiveOverlay = CreateCheckbox("hideActionBarActiveOverlay", L["Hide_ActionBar_Active_Overlay"], guiMisc, nil, BBF.HideFrames)
    hideActionBarActiveOverlay:SetPoint("TOPLEFT", hideActionBarCastAnimation, "BOTTOMLEFT", 0, pixelsBetweenBoxes)
    CreateTooltipTwo(hideActionBarActiveOverlay, L["Hide_ActionBar_Active_Overlay"], L["Tooltip_Hide_ActionBar_Active_Overlay"])

    local fixActionBarCDs = CreateCheckbox("fixActionBarCDs", L["Fix_ActionBar_Cooldowns_CC"], guiMisc, nil, BBF.ShowCooldownDuringCC)
    fixActionBarCDs:SetPoint("TOPLEFT", hideActionBarActiveOverlay, "BOTTOMLEFT", 0, pixelsBetweenBoxes)
    CreateTooltipTwo(fixActionBarCDs, L["Fix_ActionBar_Cooldowns_CC"], L["Tooltip_Fix_ActionBar_CDs_Desc"])

    local fixActionBarCDsAlwaysHideCD = CreateCheckbox("fixActionBarCDsAlwaysHideCD", L["Hide_CC_Duration"], fixActionBarCDs, nil, BBF.ShowCooldownDuringCC)
    fixActionBarCDsAlwaysHideCD:SetPoint("LEFT", fixActionBarCDs.text, "RIGHT", 0, 0)
    CreateTooltipTwo(fixActionBarCDsAlwaysHideCD, L["Always_Hide_CC_Duration"], L["Tooltip_Always_Hide_CC_Duration_Desc"])
    fixActionBarCDsAlwaysHideCD:HookScript("OnClick", function(self)
        StaticPopup_Show("BBF_CONFIRM_RELOAD")
    end)

    fixActionBarCDs:HookScript("OnClick", function(self)
        CheckAndToggleCheckboxes(self)
        if not self:GetChecked() then
            StaticPopup_Show("BBF_CONFIRM_RELOAD")
        end
    end)

    local raiseTargetFrameLevel = CreateCheckbox("raiseTargetFrameLevel", L["Raise_TargetFrame_Layer"], guiMisc, nil, BBF.RaiseTargetFrameLevel)
    raiseTargetFrameLevel:SetPoint("TOPLEFT", fixActionBarCDs, "BOTTOMLEFT", 0, pixelsBetweenBoxes)
    CreateTooltipTwo(raiseTargetFrameLevel, L["Raise_TargetFrame_Layer"], L["Tooltip_Raise_TargetFrame_Layer_Desc"])

    local raiseTargetCastbarStrata = CreateCheckbox("raiseTargetCastbarStrata", L["Raise_Castbar_Stratas"], guiMisc, nil, BBF.RaiseTargetCastbarStratas)
    raiseTargetCastbarStrata:SetPoint("TOPLEFT", raiseTargetFrameLevel, "BOTTOMLEFT", 0, pixelsBetweenBoxes)
    CreateTooltipTwo(raiseTargetCastbarStrata, L["Raise_Castbar_Stratas"], L["Tooltip_Raise_Castbar_Strata_Desc"])

    local enableLegacyComboPoints = CreateCheckbox("enableLegacyComboPoints", L["Legacy_Combo_Points"], guiMisc)
    enableLegacyComboPoints:SetPoint("TOPLEFT", raiseTargetCastbarStrata, "BOTTOMLEFT", 0, pixelsBetweenBoxes)
    CreateTooltipTwo(enableLegacyComboPoints, L["Legacy_Combo_Points"], L["Tooltip_Legacy_Combo_Points_Desc"])
    enableLegacyComboPoints:HookScript("OnClick", function(self)
        StaticPopup_Show("BBF_CONFIRM_RELOAD")
        if not self:GetChecked() then
            BetterBlizzFramesDB.legacyCombosTurnedOff = true
        else
            BetterBlizzFramesDB.legacyCombosTurnedOff = nil
        end
        if not InCombatLockdown() then
            BBF.FixLegacyComboPointsLocation()
        end
        CheckAndToggleCheckboxes(self)
    end)

    function BBF.OpenLegacyComboSliderWindow(launch)
        if not BBF.ComboSliderWindow then
            local f = CreateFrame("Frame", "BBFComboSliderWindow", UIParent, "BasicFrameTemplateWithInset")
            f:SetSize(210, 165)
            f:SetPoint("RIGHT", enableLegacyComboPoints, "LEFT", -10, 0)
            f:SetMovable(true)
            f:EnableMouse(true)
            f:RegisterForDrag("LeftButton")
            f:SetScript("OnDragStart", f.StartMoving)
            f:SetScript("OnDragStop", f.StopMovingOrSizing)
            f:SetFrameStrata("DIALOG")
            f:SetClampedToScreen(true)
            f:SetToplevel(true)

            f.title = f:CreateFontString(nil, "OVERLAY", "GameFontHighlight")
            f.title:SetPoint("TOP", f, "TOP", 0, -6)
            f.title:SetText(L["Legacy_Combo_Position"])

            BBF.ComboSliderWindow = f

            local sizeSlider = CreateSlider(f, L["Size"], 0.6, 1.3, 0.01, "legacyComboScale", nil, 140)
            sizeSlider:SetPoint("TOP", f, "TOP", 0, -45)
            CreateTooltipTwo(sizeSlider, L["Tooltip_Legacy_Combo_Points_Size"])

            local xOffsetSlider = CreateSlider(f, L["X_Offset"], -60, 10, 0.5, "legacyComboXPos", true, 140)
            xOffsetSlider:SetPoint("TOP", sizeSlider, "TOP", 0, -30)
            CreateTooltipTwo(xOffsetSlider, L["Tooltip_Legacy_Combo_Points_X_Offset"])

            local yOffsetSlider = CreateSlider(f, L["Y_Offset"], -60, 10, 0.5, "legacyComboYPos", true, 140)
            yOffsetSlider:SetPoint("TOP", xOffsetSlider, "TOP", 0, -30)
            CreateTooltipTwo(yOffsetSlider, L["Tooltip_FocusToT_Adjustment_Offset_Y"])

            local defaultButton = CreateFrame("Button", nil, f, "UIPanelButtonTemplate")
            defaultButton:SetSize(80, 22)
            defaultButton:SetText(L["Default"])
            defaultButton:SetPoint("BOTTOM", f, "BOTTOM", 0, 10)

            defaultButton:SetScript("OnClick", function()
                BetterBlizzFramesDB.legacyComboXPos = -28
                BetterBlizzFramesDB.legacyComboYPos = -25
                BetterBlizzFramesDB.legacyComboScale = 0.85
                BBF.UpdateLegacyComboPosition()
                sizeSlider:SetValue(0.85)
                xOffsetSlider:SetValue(-28)
                yOffsetSlider:SetValue(-25)
            end)

            f:Hide()
        end

        if launch then
            BBF.ComboSliderWindow:Hide()
            return
        end

        if BBF.ComboSliderWindow:IsShown() then
            BBF.ComboSliderWindow:Hide()
        else
            BBF.ComboSliderWindow:Show()
        end
    end
    BBF.OpenLegacyComboSliderWindow(true)

    enableLegacyComboPoints:SetScript("OnMouseDown", function(self, button)
        if button == "RightButton" then
            BBF.OpenLegacyComboSliderWindow()
        end
    end)

    local legacyBlueComboPoints = CreateCheckbox("legacyBlueComboPoints", L["Blue_Combos"], enableLegacyComboPoints)
    legacyBlueComboPoints:SetPoint("LEFT", enableLegacyComboPoints.text, "RIGHT", 0, 0)
    legacyBlueComboPoints:HookScript("OnClick", function()
        StaticPopup_Show("BBF_CONFIRM_RELOAD")
    end)
    CreateTooltipTwo(legacyBlueComboPoints, L["Blue_Legacy_Combo_Points"], L["Tooltip_Blue_Legacy_Combo_Points_Desc"])

    local alwaysShowLegacyComboPoints = CreateCheckbox("alwaysShowLegacyComboPoints", L["Show_Always"], enableLegacyComboPoints)
    alwaysShowLegacyComboPoints:SetPoint("LEFT", legacyBlueComboPoints.text, "RIGHT", 0, 0)
    alwaysShowLegacyComboPoints:HookScript("OnClick", function()
        BBF.AlwaysShowLegacyComboPoints()
    end)
    CreateTooltipTwo(alwaysShowLegacyComboPoints, L["Show_Always"], L["Tooltip_Show_Always_Legacy_Desc"])

    local enableLegacyComboPointsMulticlass = CreateCheckbox("enableLegacyComboPointsMulticlass", L["Tooltip_Legacy_Combo_Points_More_Classes_Desc"], enableLegacyComboPoints)
    enableLegacyComboPointsMulticlass:SetPoint("TOPLEFT", enableLegacyComboPoints, "BOTTOMLEFT", 0, pixelsBetweenBoxes)
    CreateTooltipTwo(enableLegacyComboPointsMulticlass, L["Tooltip_Legacy_Combo_Points_More_Classes_Desc"], L["Tooltip_Legacy_Combo_Multiclass_Desc"])
    enableLegacyComboPointsMulticlass:HookScript("OnClick", function()
        StaticPopup_Show("BBF_CONFIRM_RELOAD")
        BBF.GenericLegacyComboSupport()
    end)

    local legacyMulticlassComboClassColor = CreateCheckbox("legacyMulticlassComboClassColor", L["Class_Color_Combo"], enableLegacyComboPointsMulticlass)
    legacyMulticlassComboClassColor:SetPoint("LEFT", enableLegacyComboPointsMulticlass.text, "RIGHT", 0, 0)
    legacyMulticlassComboClassColor:HookScript("OnClick", function()
        BBF.ClassColorLegacyCombos()
    end)
    CreateTooltipTwo(legacyMulticlassComboClassColor, L["Class_Color_Legacy_Combos"], L["Tooltip_Class_Color_Legacy_Combos_Desc"])


    local instantComboPoints = CreateCheckbox("instantComboPoints", L["Instant_Combo_Points"], guiMisc, nil, BBF.InstantComboPoints)
    instantComboPoints:SetPoint("TOPLEFT", enableLegacyComboPointsMulticlass, "BOTTOMLEFT", 0, pixelsBetweenBoxes)
    CreateTooltipTwo(instantComboPoints, L["Instant_Combo_Points"],
    "Remove the combo point animations for instant feedback.\n\nCurrently works for:\n|cFFFFF569Rogue|r\n|cFFFF7D0ADruid|r\n|cFF00FF96Monk|r\n|cFF3FC7EBMage|r\n|cFFF58CBAPaladin|r\n|cFFAAAAAALegacy Combos (Rogue & Druid)|r")
    instantComboPoints:HookScript("OnClick", function(self)
        if not self:GetChecked() then
            StaticPopup_Show("BBF_CONFIRM_RELOAD")
            if BetterBlizzPlatesDB then
                BetterBlizzPlatesDB.instantComboPoints = false
            end
        end
    end)

    local moveResource = CreateCheckbox("moveResource", L["Move_Resource"], guiMisc)
    moveResource:SetPoint("TOPLEFT", instantComboPoints, "BOTTOMLEFT", 0, pixelsBetweenBoxes)
    CreateTooltipTwo(moveResource, L["Move_Resource"], L["Tooltip_Move_Resource_Desc"] .. playerClass, L["Tooltip_Move_Resource_SubText"])
    moveResource:HookScript("OnClick", function(self)
        if self:GetChecked() then
            BBF.EnableResourceMovement()
        end
    end)
    if BetterBlizzFramesDB.moveResourceStackPos and not BetterBlizzFramesDB.moveResourceStackPos[playerClass] then
        moveResource:SetChecked(false)
    elseif not BetterBlizzFramesDB.moveResourceStackPos then
        moveResource:SetChecked(false)
    end

    local moveResourceToTarget = CreateCheckbox("moveResourceToTarget", L["Move_Resource_To_TargetFrame"], guiMisc)
    moveResourceToTarget:SetPoint("TOPLEFT", moveResource, "BOTTOMLEFT", 0, pixelsBetweenBoxes)
    CreateTooltip(moveResourceToTarget, L["Tooltip_Move_Resource_To_Target"])

    local moveResourceToTargetCustom = CreateCheckbox("moveResourceToTargetCustom", L["Free_Move"], moveResourceToTarget)
    moveResourceToTargetCustom:SetPoint("LEFT", moveResourceToTarget.text, "RIGHT", 0, 0)
    moveResourceToTargetCustom:HookScript("OnClick", function(self)
        if self:GetChecked() then
            if BBF.ToggleEditMode then
                BBF.ToggleEditMode(true)
            end
            BBF.UpdateClassComboPoints()
        else
            if BBF.ToggleEditMode then
                BBF.ToggleEditMode(false)
            end
            BBF.UpdateClassComboPoints()
        end
    end)
    CreateTooltipTwo(moveResourceToTargetCustom, L["Free_Move_Resource_Tooltip"], L["Tooltip_Free_Move_Resource_Desc"] .. playerClass, L["Tooltip_Free_Move_Resource_SubText"])

    local moveResourceToTargetRogue = CreateCheckbox("moveResourceToTargetRogue", L["Rogue_Combo_Points"], moveResourceToTarget)
    moveResourceToTargetRogue:SetPoint("TOPLEFT", moveResourceToTarget, "BOTTOMLEFT", 12, pixelsBetweenBoxes)
    CreateTooltip(moveResourceToTargetRogue, L["Tooltip_Move_Resource_Rogue"])
    moveResourceToTargetRogue:HookScript("OnClick", function()
        StaticPopup_Show("BBF_CONFIRM_RELOAD")
    end)

    local moveResourceToTargetDruid = CreateCheckbox("moveResourceToTargetDruid", L["Druid_Combo_Points"], moveResourceToTarget)
    moveResourceToTargetDruid:SetPoint("TOPLEFT", moveResourceToTargetRogue, "BOTTOMLEFT", 0, pixelsBetweenBoxes)
    CreateTooltip(moveResourceToTargetDruid, L["Tooltip_Move_Resource_Druid"])
    moveResourceToTargetDruid:HookScript("OnClick", function()
        StaticPopup_Show("BBF_CONFIRM_RELOAD")
    end)

    local moveResourceToTargetMonk = CreateCheckbox("moveResourceToTargetMonk", L["Monk_Chi_Points"], moveResourceToTarget)
    moveResourceToTargetMonk:SetPoint("TOPLEFT", moveResourceToTargetDruid, "BOTTOMLEFT", 0, pixelsBetweenBoxes)
    CreateTooltip(moveResourceToTargetMonk, L["Tooltip_Move_Resource_Monk"])
    moveResourceToTargetMonk:HookScript("OnClick", function()
        StaticPopup_Show("BBF_CONFIRM_RELOAD")
    end)

    local moveResourceToTargetWarlock = CreateCheckbox("moveResourceToTargetWarlock", L["Warlock_Shards"], moveResourceToTarget)
    moveResourceToTargetWarlock:SetPoint("TOPLEFT", moveResourceToTargetMonk, "BOTTOMLEFT", 0, pixelsBetweenBoxes)
    CreateTooltip(moveResourceToTargetWarlock, L["Tooltip_Move_Resource_Warlock"])
    moveResourceToTargetWarlock:HookScript("OnClick", function()
        StaticPopup_Show("BBF_CONFIRM_RELOAD")
    end)

    local moveResourceToTargetEvoker = CreateCheckbox("moveResourceToTargetEvoker", L["Evoker_Essence"], moveResourceToTarget)
    moveResourceToTargetEvoker:SetPoint("TOPLEFT", moveResourceToTargetWarlock, "BOTTOMLEFT", 0, pixelsBetweenBoxes)
    CreateTooltip(moveResourceToTargetEvoker, L["Tooltip_Move_Resource_Evoker"])
    moveResourceToTargetEvoker:HookScript("OnClick", function()
        StaticPopup_Show("BBF_CONFIRM_RELOAD")
    end)

    local moveResourceToTargetMage = CreateCheckbox("moveResourceToTargetMage", L["Mage_Arcane_Charges"], moveResourceToTarget)
    moveResourceToTargetMage:SetPoint("TOPLEFT", moveResourceToTargetEvoker, "BOTTOMLEFT", 0, pixelsBetweenBoxes)
    CreateTooltip(moveResourceToTargetMage, L["Tooltip_Move_Resource_Mage"])
    moveResourceToTargetMage:HookScript("OnClick", function()
        StaticPopup_Show("BBF_CONFIRM_RELOAD")
    end)

    local moveResourceToTargetDK = CreateCheckbox("moveResourceToTargetDK", L["Death_Knight_Runes"], moveResourceToTarget)
    moveResourceToTargetDK:SetPoint("TOPLEFT", moveResourceToTargetMage, "BOTTOMLEFT", 0, pixelsBetweenBoxes)
    CreateTooltip(moveResourceToTargetDK, L["Tooltip_Move_Resource_DK"])
    moveResourceToTargetDK:HookScript("OnClick", function()
        StaticPopup_Show("BBF_CONFIRM_RELOAD")
    end)

    local moveResourceToTargetPaladin = CreateCheckbox("moveResourceToTargetPaladin", L["Paladin_Holy_Charges"], moveResourceToTarget)
    moveResourceToTargetPaladin:SetPoint("TOPLEFT", moveResourceToTargetDK, "BOTTOMLEFT", 0, pixelsBetweenBoxes)
    CreateTooltip(moveResourceToTargetPaladin, L["Tooltip_Move_Resource_Paladin"])
    moveResourceToTargetPaladin:HookScript("OnClick", function()
        StaticPopup_Show("BBF_CONFIRM_RELOAD")
    end)

    local moveResourceToTargetPaladinBG = CreateCheckbox("moveResourceToTargetPaladinBG", L["BG"], moveResourceToTargetPaladin)
    moveResourceToTargetPaladinBG:SetPoint("LEFT", moveResourceToTargetPaladin.text, "RIGHT", 0, 0)
    CreateTooltipTwo(moveResourceToTargetPaladinBG, L["Background"], L["Tooltip_Paladin_Background_Desc"])

    moveResourceToTargetPaladinBG:HookScript("OnClick", function(self)
        StaticPopup_Show("BBF_CONFIRM_RELOAD")
    end)

    moveResourceToTargetPaladin:HookScript("OnClick", function(self)
        CheckAndToggleCheckboxes(self)
    end)

    local key = "classResource" .. playerClass .. "Scale"
    local classResourceScale = CreateSlider(guiMisc, L["Class_Resource_Scale"], 0.4, 2, 0.01, key)
    classResourceScale:SetPoint("TOPLEFT", moveResourceToTargetPaladin, "BOTTOMLEFT", 5, -15)
    CreateTooltipTwo(classResourceScale, L["Class_Resource_Scale"], L["Tooltip_Class_Resource_Scale_Desc"], L["Tooltip_Class_Resource_Scale_Extra"])

    moveResource:HookScript("OnMouseDown", function(self, button)
        if button == "RightButton" then
            if BetterBlizzFramesDB.moveResourceStackPos then
                BetterBlizzFramesDB.moveResourceStackPos[playerClass] = nil
            end
            classResourceScale:SetValue(1)
            BBF.Print(string.format(L["Print_Combo_Points_Reset"], playerClass))
            BBF.ResetResourcePosition()
        end
    end)

    moveResourceToTargetCustom:HookScript("OnMouseDown", function(self, button)
        if button == "RightButton" then
            if BetterBlizzFramesDB.customComboPositions then
                BetterBlizzFramesDB.customComboPositions[playerClass] = nil
            end
            classResourceScale:SetValue(1)
            BBF.Print(string.format(L["Print_Combo_Points_Reset"], playerClass))
            BBF.UpdateClassComboPoints()
        end
    end)

    moveResourceToTarget:HookScript("OnClick", function(self)
        if self:GetChecked() then
            classResourceScale:SetValue(1)
        end
        StaticPopup_Show("BBF_CONFIRM_RELOAD")
        CheckAndToggleCheckboxes(moveResourceToTarget)
    end)



    local rpNames = CreateCheckbox("rpNames", L["Roleplay_Names_TRP3"], guiMisc)
    rpNames:SetPoint("BOTTOMRIGHT", guiMisc, "BOTTOMRIGHT", -220, 50)
    CreateTooltipTwo(rpNames, L["Roleplay_Names_Tooltip"], L["Tooltip_Roleplay_Names_Desc"])

    local rpNamesFirst = CreateCheckbox("rpNamesFirst", L["First"], rpNames)
    rpNamesFirst:SetPoint("LEFT", rpNames.text, "RIGHT", 0, 0)
    CreateTooltipTwo(rpNamesFirst, L["First_Name_TRP3"], L["Tooltip_RP_First_Name_Desc"])

    local rpNamesLast = CreateCheckbox("rpNamesLast", L["Last"], rpNames)
    rpNamesLast:SetPoint("LEFT", rpNamesFirst.text, "RIGHT", 0, 0)
    CreateTooltipTwo(rpNamesLast, L["Last_Name_TRP3"], L["Tooltip_RP_Last_Name_Desc"])

    local rpNamesColor = CreateCheckbox("rpNamesColor", L["RP_Name_Text_Color"], guiMisc)
    rpNamesColor:SetPoint("TOPLEFT", rpNames, "BOTTOMLEFT", 0, pixelsBetweenBoxes)
    CreateTooltipTwo(rpNamesColor, L["Roleplay_Name_Text_Color"], L["Tooltip_Roleplay_Name_Text_Color_Desc"])

    rpNames:HookScript("OnClick", function(self)
        CheckAndToggleCheckboxes(self)
        BBF.AllNameChanges()
    end)

    rpNamesFirst:HookScript("OnClick", function(self)
        BBF.AllNameChanges()
    end)

    rpNamesLast:HookScript("OnClick", function(self)
        BBF.AllNameChanges()
    end)

    rpNamesColor:HookScript("OnClick", function(self)
        BBF.AllNameChanges()
    end)

    local rpNamesHealthbarColor = CreateCheckbox("rpNamesHealthbarColor", L["RP_Healthbar_Color"], guiMisc)
    rpNamesHealthbarColor:SetPoint("TOPLEFT", rpNamesColor, "BOTTOMLEFT", 0, pixelsBetweenBoxes)
    CreateTooltipTwo(rpNamesHealthbarColor, L["Roleplay_Healthbar_Color"], L["Tooltip_Roleplay_Healthbar_Color_Desc"])

    rpNamesHealthbarColor:HookScript("OnClick", function(self)
        BBF.HookHealthbarColors()
        StaticPopup_Show("BBF_CONFIRM_RELOAD")
    end)

    local rpNamesFrameTextureColor = CreateCheckbox("rpNamesFrameTextureColor", L["RP_FrameTexture_Color"], guiMisc)
    rpNamesFrameTextureColor:SetPoint("TOPLEFT", rpNamesHealthbarColor, "BOTTOMLEFT", 0, pixelsBetweenBoxes)
    CreateTooltipTwo(rpNamesFrameTextureColor, L["Roleplay_FrameTexture_Color"], L["Tooltip_RP_FrameTexture_Color_Desc"])

    rpNamesFrameTextureColor:HookScript("OnClick", function(self)
        BBF.HookFrameTextureColor()
        if not self:GetChecked() then
            StaticPopup_Show("BBF_CONFIRM_RELOAD")
        end
    end)

end

local function guiImportAndExport()
    local guiImportAndExport = CreateFrame("Frame")
    guiImportAndExport.name = L["Module_Name_Import_Export"]
    guiImportAndExport.parent = BetterBlizzFrames.name
    --InterfaceOptions_AddCategory(guiImportAndExport)
    local guiImportSubcategory = Settings.RegisterCanvasLayoutSubcategory(BBF.category, guiImportAndExport, guiImportAndExport.name, guiImportAndExport.name)
    guiImportSubcategory.ID = guiImportAndExport.name;
    CreateTitle(guiImportAndExport)

    local bgImg = guiImportAndExport:CreateTexture(nil, "BACKGROUND")
    bgImg:SetAtlas("professions-recipe-background")
    bgImg:SetPoint("CENTER", guiImportAndExport, "CENTER", -8, 4)
    bgImg:SetSize(680, 610)
    bgImg:SetAlpha(0.4)
    bgImg:SetVertexColor(0,0,0)

    local fullProfile = CreateImportExportUI(guiImportAndExport, "Full Profile", BetterBlizzFramesDB, 20, -20, "fullProfile")

    local auraWhitelist = CreateImportExportUI(fullProfile, "Aura Whitelist", BetterBlizzFramesDB.auraWhitelist, 0, -100, "auraWhitelist")
    local auraBlacklist = CreateImportExportUI(auraWhitelist, "Aura Blacklist", BetterBlizzFramesDB.auraBlacklist, 210, 0, "auraBlacklist")

    local importPVPWhitelist = CreateFrame("Button", nil, guiImportAndExport, "UIPanelButtonTemplate")
    importPVPWhitelist:SetSize(150, 35)
    importPVPWhitelist:SetPoint("TOP", auraWhitelist, "BOTTOM", 0, -25)
    importPVPWhitelist:SetText(L["Import_PvP_Whitelist"])
    importPVPWhitelist:SetScript("OnClick", function()
        StaticPopup_Show("BBF_CONFIRM_PVP_WHITELIST")
    end)
    local coloredText = L["Whitelist_Colors"]

    CreateTooltipTwo(importPVPWhitelist, L["Import_PvP_Whitelist"], string.format(L["Tooltip_Import_PvP_Whitelist_Desc"], coloredText))

    local importPVPBlacklist = CreateFrame("Button", nil, guiImportAndExport, "UIPanelButtonTemplate")
    importPVPBlacklist:SetSize(150, 35)
    importPVPBlacklist:SetPoint("TOP", auraBlacklist, "BOTTOM", 0, -25)
    importPVPBlacklist:SetText(L["Import_PvP_Blacklist"])
    importPVPBlacklist:SetScript("OnClick", function()
        StaticPopup_Show("BBF_CONFIRM_PVP_BLACKLIST")
    end)
    CreateTooltipTwo(importPVPBlacklist, L["Import_PvP_Blacklist"], L["Tooltip_Import_Blacklist_Desc"])

end

local function guiCustomCode()
    local guiCustomCode = CreateFrame("Frame")
    guiCustomCode.name = L["Module_Name_Custom_Code"]
    guiCustomCode.parent = BetterBlizzFrames.name
    --InterfaceOptions_AddCategory(guiCustomCode)
    local guiCustomCodeSubCategory = Settings.RegisterCanvasLayoutSubcategory(BBF.category, guiCustomCode, guiCustomCode.name, guiCustomCode.name)
    BBF.guiCustomCode = guiCustomCode.name
    CreateTitle(guiCustomCode)

    local bgImg = guiCustomCode:CreateTexture(nil, "BACKGROUND")
    bgImg:SetAtlas("professions-recipe-background")
    bgImg:SetPoint("CENTER", guiCustomCode, "CENTER", -8, 4)
    bgImg:SetSize(680, 610)
    bgImg:SetAlpha(0.4)
    bgImg:SetVertexColor(0,0,0)

    local discordLinkEditBox = CreateFrame("EditBox", nil, guiCustomCode, "InputBoxTemplate")
    discordLinkEditBox:SetPoint("TOPLEFT", guiCustomCode, "TOPLEFT", 25, -45)
    discordLinkEditBox:SetSize(180, 20)
    discordLinkEditBox:SetAutoFocus(false)
    discordLinkEditBox:SetFontObject("ChatFontSmall")
    discordLinkEditBox:SetText("https://discord.gg/cjqVaEMm25")
    discordLinkEditBox:SetCursorPosition(0) -- Places cursor at start of the text
    discordLinkEditBox:ClearFocus() -- Removes focus from the EditBox
    discordLinkEditBox:SetScript("OnEscapePressed", function(self)
        self:ClearFocus() -- Allows user to press escape to unfocus the EditBox
    end)

    -- Make the EditBox text selectable and readonly
    discordLinkEditBox:SetScript("OnTextChanged", function(self)
        self:SetText("https://discord.gg/cjqVaEMm25")
    end)
    --discordLinkEditBox:HighlightText() -- Highlights the text for easy copying
    discordLinkEditBox:SetScript("OnCursorChanged", function() end) -- Prevents cursor changes
    discordLinkEditBox:SetScript("OnEditFocusGained", function(self) self:HighlightText() end) -- Re-highlights text when focused
    discordLinkEditBox:SetScript("OnMouseUp", function(self)
        if not self:IsMouseOver() then
            self:ClearFocus()
        end
    end)

    local discordText = guiCustomCode:CreateFontString(nil, "OVERLAY", "GameFontNormalLarge")
    discordText:SetPoint("BOTTOM", discordLinkEditBox, "TOP", 18, 8)
    discordText:SetText(L["Discord_Text"])

    local joinDiscord = guiCustomCode:CreateTexture(nil, "ARTWORK")
    joinDiscord:SetTexture("Interface\\AddOns\\BetterBlizzFrames\\media\\logos\\discord.tga")
    joinDiscord:SetSize(52, 52)
    joinDiscord:SetPoint("RIGHT", discordText, "LEFT", 0, 1)

    local boxOne = CreateFrame("EditBox", nil, guiCustomCode, "InputBoxTemplate")
    boxOne:SetPoint("LEFT", discordLinkEditBox, "RIGHT", 50, 0)
    boxOne:SetSize(180, 20)
    boxOne:SetAutoFocus(false)
    boxOne:SetFontObject("ChatFontSmall")
    boxOne:SetText("https://patreon.com/bodifydev")
    boxOne:SetCursorPosition(0) -- Places cursor at start of the text
    boxOne:ClearFocus() -- Removes focus from the EditBox
    boxOne:SetScript("OnEscapePressed", function(self)
        self:ClearFocus() -- Allows user to press escape to unfocus the EditBox
    end)

    -- Make the EditBox text selectable and readonly
    boxOne:SetScript("OnTextChanged", function(self)
        self:SetText("https://patreon.com/bodifydev")
    end)
    --boxOne:HighlightText() -- Highlights the text for easy copying
    boxOne:SetScript("OnCursorChanged", function() end) -- Prevents cursor changes
    boxOne:SetScript("OnEditFocusGained", function(self) self:HighlightText() end) -- Re-highlights text when focused
    boxOne:SetScript("OnMouseUp", function(self)
        if not self:IsMouseOver() then
            self:ClearFocus()
        end
    end)

    local boxOneTex = guiCustomCode:CreateTexture(nil, "ARTWORK")
    boxOneTex:SetTexture("Interface\\AddOns\\BetterBlizzFrames\\media\\logos\\patreon.tga")
    boxOneTex:SetSize(58, 58)
    boxOneTex:SetPoint("BOTTOMLEFT", boxOne, "TOPLEFT", 3, -2)

    local patText = guiCustomCode:CreateFontString(nil, "OVERLAY", "GameFontNormalHuge")
    patText:SetPoint("LEFT", boxOneTex, "RIGHT", 14, -1)
    patText:SetText("Patreon")

    local boxTwo = CreateFrame("EditBox", nil, guiCustomCode, "InputBoxTemplate")
    boxTwo:SetPoint("LEFT", boxOne, "RIGHT", 35, 0)
    boxTwo:SetSize(180, 20)
    boxTwo:SetAutoFocus(false)
    boxTwo:SetFontObject("ChatFontSmall")
    boxTwo:SetText("https://paypal.me/bodifydev")
    boxTwo:SetCursorPosition(0) -- Places cursor at start of the text
    boxTwo:ClearFocus() -- Removes focus from the EditBox
    boxTwo:SetScript("OnEscapePressed", function(self)
        self:ClearFocus() -- Allows user to press escape to unfocus the EditBox
    end)

    -- Make the EditBox text selectable and readonly
    boxTwo:SetScript("OnTextChanged", function(self)
        self:SetText("https://paypal.me/bodifydev")
    end)
    --boxTwo:HighlightText() -- Highlights the text for easy copying
    boxTwo:SetScript("OnCursorChanged", function() end) -- Prevents cursor changes
    boxTwo:SetScript("OnEditFocusGained", function(self) self:HighlightText() end) -- Re-highlights text when focused
    boxTwo:SetScript("OnMouseUp", function(self)
        if not self:IsMouseOver() then
            self:ClearFocus()
        end
    end)

    local boxTwoTex = guiCustomCode:CreateTexture(nil, "ARTWORK")
    boxTwoTex:SetTexture("Interface\\AddOns\\BetterBlizzFrames\\media\\logos\\paypal.tga")
    boxTwoTex:SetSize(58, 58)
    boxTwoTex:SetPoint("BOTTOMLEFT", boxTwo, "TOPLEFT", 3, -2)

    local palText = guiCustomCode:CreateFontString(nil, "OVERLAY", "GameFontNormalHuge")
    palText:SetPoint("LEFT", boxTwoTex, "RIGHT", 14, -1)
    palText:SetText("Paypal")







    -- Implementing the code editor inside the guiCustomCode frame
    local FAIAP = BBF.indent

    -- Define your color table for syntax highlighting
    local colorTable = {
        [FAIAP.tokens.TOKEN_SPECIAL] = "|c00F1D710",
        [FAIAP.tokens.TOKEN_KEYWORD] = "|c00BD6CCC",
        [FAIAP.tokens.TOKEN_COMMENT_SHORT] = "|c00999999",
        [FAIAP.tokens.TOKEN_COMMENT_LONG] = "|c00999999",
        [FAIAP.tokens.TOKEN_STRING] = "|c00E2A085",
        [FAIAP.tokens.TOKEN_NUMBER] = "|c00B1FF87",
        [FAIAP.tokens.TOKEN_ASSIGNMENT] = "|c0055ff88",
        [FAIAP.tokens.TOKEN_WOW_API] = "|c00ff8000",
        [FAIAP.tokens.TOKEN_WOW_EVENTS] = "|c004ec9b0",
        [0] = "|r",  -- Reset color
    }

    -- Add a scroll frame for the code editor
    local scrollFrame = CreateFrame("ScrollFrame", nil, guiCustomCode, "UIPanelScrollFrameTemplate")
    scrollFrame:SetPoint("TOP", guiCustomCode, "TOP", -10, -110)
    scrollFrame:SetSize(620, 440)  -- Fixed size for the entire editor box

    -- Label for the custom code box
    local customCodeText = guiCustomCode:CreateFontString(nil, "OVERLAY", "GameFontNormalHuge")
    customCodeText:SetPoint("BOTTOM", scrollFrame, "TOP", 0, 5)
    customCodeText:SetText(L["Custom_Code_Text"])

    -- Create the code editor
    local codeEditBox = CreateFrame("EditBox", nil, scrollFrame)
    codeEditBox:SetMultiLine(true)
    codeEditBox:SetFontObject("ChatFontSmall")
    codeEditBox:SetSize(600, 370)  -- Smaller than the scroll frame to allow scrolling
    codeEditBox:SetAutoFocus(false)
    codeEditBox:SetCursorPosition(0)
    codeEditBox:SetText(BetterBlizzFramesDB.customCode or "")
    codeEditBox:ClearFocus()

    -- Attach the EditBox to the scroll frame
    scrollFrame:SetScrollChild(codeEditBox)

    -- Add a static custom background to the scroll frame
    local bg = scrollFrame:CreateTexture(nil, "BACKGROUND")
    bg:SetColorTexture(0, 0, 0, 0.6)  -- Semi-transparent black background
    bg:SetAllPoints(scrollFrame)  -- Apply the background to the entire scroll frame

    -- Add a static custom border around the scroll frame
    local border = CreateFrame("Frame", nil, scrollFrame, BackdropTemplateMixin and "BackdropTemplate")
    border:SetPoint("TOPLEFT", scrollFrame, -2, 2)
    border:SetPoint("BOTTOMRIGHT", scrollFrame, 2, -2)
    border:SetBackdrop({
        edgeFile = "Interface\\Tooltips\\UI-Tooltip-Border",
        edgeSize = 14,
    })
    border:SetBackdropBorderColor(0.8, 0.8, 0.8, 1)  -- Light gray border

    -- Optional: Set padding or insets if needed
    codeEditBox:SetTextInsets(6, 10, 4, 10)

    -- Track changes to detect unsaved edits
    local unsavedChanges = false
    codeEditBox:SetScript("OnTextChanged", function(self, userInput)
        if userInput then
            -- Compare current text with saved code
            local currentText = self:GetText()
            if currentText ~= BetterBlizzFramesDB.customCode then
                unsavedChanges = true
            else
                unsavedChanges = false
            end
        end
    end)

    -- Enable syntax highlighting and indentation with FAIAP
    FAIAP.enable(codeEditBox, colorTable, 4)  -- Assuming a tab width of 4

    local customCodeSaved = L["Print_Custom_Code_Saved"]

    -- Create Save Button
    local saveButton = CreateFrame("Button", nil, guiCustomCode, "UIPanelButtonTemplate")
    saveButton:SetSize(120, 30)
    saveButton:SetPoint("TOP", scrollFrame, "BOTTOM", 0, -10)
    saveButton:SetText(L["Save"])
    saveButton:SetScript("OnClick", function()
        BetterBlizzFramesDB.customCode = codeEditBox:GetText()
        unsavedChanges = false
        BBF.Print(customCodeSaved)
    end)

    -- Flag to prevent double triggering of the prompt
    local promptShown = false

    -- Function to show the save prompt if needed
    local function showSavePrompt()
        if unsavedChanges and not promptShown then
            promptShown = true
            StaticPopup_Show("UNSAVED_CHANGES_PROMPT")
        end
    end

    -- Prevent the EditBox from clearing focus with ESC if there are unsaved changes
    codeEditBox:SetScript("OnEscapePressed", function(self)
        if unsavedChanges then
            showSavePrompt()
        else
            self:ClearFocus()
        end
    end)

    StaticPopupDialogs["UNSAVED_CHANGES_PROMPT"] = {
        text = "|A:gmchat-icon-blizz:16:16|a Better|cff00c0ffBlizz|rFrames \n\n"..L["Popup_Unsaved_Changes_Midnight"],
        button1 = L["Yes"],
        button2 = L["No"],
        OnAccept = function()
            BetterBlizzFramesDB.customCode = codeEditBox:GetText()
            unsavedChanges = false
            codeEditBox:ClearFocus()
            BBF.Print(customCodeSaved)
            if BetterBlizzFramesDB.reopenOptions then
                ReloadUI()
            end
        end,
        OnCancel = function()
            unsavedChanges = false
            codeEditBox:ClearFocus()
            if BetterBlizzFramesDB.reopenOptions then
                ReloadUI()
            end
        end,
        timeout = 0,
        whileDead = true,
    }

    local reloadUiButton = CreateFrame("Button", nil, guiCustomCode, "UIPanelButtonTemplate")
    reloadUiButton:SetText(L["Reload_UI"])
    reloadUiButton:SetWidth(85)
    reloadUiButton:SetPoint("TOP", guiCustomCode, "BOTTOMRIGHT", -140, -9)
    reloadUiButton:SetScript("OnClick", function()
        if unsavedChanges then
            showSavePrompt()
            BetterBlizzFramesDB.reopenOptions = true
            return
        end
        BetterBlizzFramesDB.reopenOptions = true
        ReloadUI()
    end)
end

local function guiSupport()
    local guiSupport = CreateFrame("Frame")
    guiSupport.name = "|A:GarrisonTroops-Health:10:10|a Support"
    guiSupport.parent = BetterBlizzFrames.name
    --InterfaceOptions_AddCategory(guiSupport)
    local guiSupportCategory = Settings.RegisterCanvasLayoutSubcategory(BBF.category, guiSupport, guiSupport.name, guiSupport.name)
    guiSupportCategory.ID = guiSupport.name;
    BBF.guiSupport = guiSupport.name
    BBF.category.guiSupportCategory = guiSupportCategory.ID
    CreateTitle(guiSupport)

    local bgImg = guiSupport:CreateTexture(nil, "BACKGROUND")
    bgImg:SetAtlas("professions-recipe-background")
    bgImg:SetPoint("CENTER", guiSupport, "CENTER", -8, 4)
    bgImg:SetSize(680, 610)
    bgImg:SetAlpha(0.4)
    bgImg:SetVertexColor(0,0,0)

    local discordLinkEditBox = CreateFrame("EditBox", nil, guiSupport, "InputBoxTemplate")
    discordLinkEditBox:SetPoint("TOP", guiSupport, "TOP", 0, -170)
    discordLinkEditBox:SetSize(180, 20)
    discordLinkEditBox:SetAutoFocus(false)
    discordLinkEditBox:SetFontObject("ChatFontNormal")
    discordLinkEditBox:SetText("https://discord.gg/cjqVaEMm25")
    discordLinkEditBox:SetCursorPosition(0) -- Places cursor at start of the text
    discordLinkEditBox:ClearFocus() -- Removes focus from the EditBox
    discordLinkEditBox:SetScript("OnEscapePressed", function(self)
        self:ClearFocus() -- Allows user to press escape to unfocus the EditBox
    end)

    -- Make the EditBox text selectable and readonly
    discordLinkEditBox:SetScript("OnTextChanged", function(self)
        self:SetText("https://discord.gg/cjqVaEMm25")
    end)
    --discordLinkEditBox:HighlightText() -- Highlights the text for easy copying
    discordLinkEditBox:SetScript("OnCursorChanged", function() end) -- Prevents cursor changes
    discordLinkEditBox:SetScript("OnEditFocusGained", function(self) self:HighlightText() end) -- Re-highlights text when focused
    discordLinkEditBox:SetScript("OnMouseUp", function(self)
        if not self:IsMouseOver() then
            self:ClearFocus()
        end
    end)

    local discordText = guiSupport:CreateFontString(nil, "OVERLAY", "GameFontNormalLarge")
    discordText:SetPoint("BOTTOM", discordLinkEditBox, "TOP", 18, 8)
    discordText:SetText(L["Discord_Text"])

    local joinDiscord = guiSupport:CreateTexture(nil, "ARTWORK")
    joinDiscord:SetTexture("Interface\\AddOns\\BetterBlizzFrames\\media\\logos\\discord.tga")
    joinDiscord:SetSize(52, 52)
    joinDiscord:SetPoint("RIGHT", discordText, "LEFT", 0, 1)

    local supportText = guiSupport:CreateFontString(nil, "OVERLAY", "GameFontNormalLarge")
    supportText:SetPoint("TOP", guiSupport, "TOP", 0, -230)
    supportText:SetText("|A:GarrisonTroops-Health:10:10|a " .. L["Support_Text"])

    local boxOne = CreateFrame("EditBox", nil, guiSupport, "InputBoxTemplate")
    boxOne:SetPoint("TOP", guiSupport, "TOP", -110, -360)
    boxOne:SetSize(180, 20)
    boxOne:SetAutoFocus(false)
    boxOne:SetFontObject("ChatFontNormal")
    boxOne:SetText("https://patreon.com/bodifydev")
    boxOne:SetCursorPosition(0) -- Places cursor at start of the text
    boxOne:ClearFocus() -- Removes focus from the EditBox
    boxOne:SetScript("OnEscapePressed", function(self)
        self:ClearFocus() -- Allows user to press escape to unfocus the EditBox
    end)

    -- Make the EditBox text selectable and readonly
    boxOne:SetScript("OnTextChanged", function(self)
        self:SetText("https://patreon.com/bodifydev")
    end)
    --boxOne:HighlightText() -- Highlights the text for easy copying
    boxOne:SetScript("OnCursorChanged", function() end) -- Prevents cursor changes
    boxOne:SetScript("OnEditFocusGained", function(self) self:HighlightText() end) -- Re-highlights text when focused
    boxOne:SetScript("OnMouseUp", function(self)
        if not self:IsMouseOver() then
            self:ClearFocus()
        end
    end)

    local boxOneTex = guiSupport:CreateTexture(nil, "ARTWORK")
    boxOneTex:SetTexture("Interface\\AddOns\\BetterBlizzFrames\\media\\logos\\patreon.tga")
    boxOneTex:SetSize(58, 58)
    boxOneTex:SetPoint("BOTTOM", boxOne, "TOP", 0, 1)

    local boxTwo = CreateFrame("EditBox", nil, guiSupport, "InputBoxTemplate")
    boxTwo:SetPoint("TOP", guiSupport, "TOP", 110, -360)
    boxTwo:SetSize(180, 20)
    boxTwo:SetAutoFocus(false)
    boxTwo:SetFontObject("ChatFontNormal")
    boxTwo:SetText("https://paypal.me/bodifydev")
    boxTwo:SetCursorPosition(0) -- Places cursor at start of the text
    boxTwo:ClearFocus() -- Removes focus from the EditBox
    boxTwo:SetScript("OnEscapePressed", function(self)
        self:ClearFocus() -- Allows user to press escape to unfocus the EditBox
    end)

    -- Make the EditBox text selectable and readonly
    boxTwo:SetScript("OnTextChanged", function(self)
        self:SetText("https://paypal.me/bodifydev")
    end)
    --boxTwo:HighlightText() -- Highlights the text for easy copying
    boxTwo:SetScript("OnCursorChanged", function() end) -- Prevents cursor changes
    boxTwo:SetScript("OnEditFocusGained", function(self) self:HighlightText() end) -- Re-highlights text when focused
    boxTwo:SetScript("OnMouseUp", function(self)
        if not self:IsMouseOver() then
            self:ClearFocus()
        end
    end)

    local boxTwoTex = guiSupport:CreateTexture(nil, "ARTWORK")
    boxTwoTex:SetTexture("Interface\\AddOns\\BetterBlizzFrames\\media\\logos\\paypal.tga")
    boxTwoTex:SetSize(58, 58)
    boxTwoTex:SetPoint("BOTTOM", boxTwo, "TOP", 0, 1)
end

local function guiMidnight()
    local guiMidnight = CreateFrame("Frame")
    guiMidnight.name = "|T136221:12:12|t |cffcc66ffWoW: Midnight|r"
    guiMidnight.parent = BetterBlizzFrames.name
    --InterfaceOptions_AddCategory(guiMidnight)
    local guiMidnightCategory = Settings.RegisterCanvasLayoutSubcategory(BBF.category, guiMidnight, guiMidnight.name, guiMidnight.name)
    guiMidnightCategory.ID = guiMidnight.name;
    BBF.guiMidnight = guiMidnight.name
    BBF.category.guiMidnightCategory = guiMidnightCategory.ID
    CreateTitle(guiMidnight)

    local titleText = guiMidnight:CreateFontString(nil, "OVERLAY", "GameFontNormalHuge")
    titleText:SetPoint("TOPLEFT", guiMidnight, "TOPLEFT", 20, -10)
    titleText:SetText(L["Midnight_Title"])
    local titleIcon = guiMidnight:CreateTexture(nil, "ARTWORK")
    titleIcon:SetTexture(136221)
    titleIcon:SetSize(23, 23)
    titleIcon:SetPoint("RIGHT", titleText, "LEFT", -3, 0.5)

    local midnightInfo = guiMidnight:CreateFontString(nil, "OVERLAY", "GameFontNormal")
    midnightInfo:SetPoint("TOPLEFT", titleIcon, "BOTTOMLEFT", 2, -5)
    midnightInfo:SetText(L["Midnight_Info"])
    midnightInfo:SetTextColor(1,1,1,1)
    midnightInfo:SetJustifyH("LEFT")

    local bgImg = guiMidnight:CreateTexture(nil, "BACKGROUND")
    bgImg:SetAtlas("professions-recipe-background")
    bgImg:SetPoint("CENTER", guiMidnight, "CENTER", -8, 4)
    bgImg:SetSize(680, 610)
    bgImg:SetAlpha(0.4)
    bgImg:SetVertexColor(0,0,0)

    local f = CreateFrame("PlayerModel", nil, guiMidnight)
    f:SetIgnoreParentScale(true)
    f:SetScale(1)
    f:SetAllPoints(bgImg)
    f:SetPortraitZoom(0)
    f:SetDisplayInfo(121956)
    f.anim = 69
    f:SetAnimation(69)
    f:HookScript("OnAnimFinished", function(self)
        if self.anim == 3 or self.anim == 15 then return end
        self:SetAnimation(self.anim)
    end)

    local DEFAULT_CAM     = 1.35
    local DEFAULT_VTX     = -35
    local DEFAULT_VTY     = -30

    local validAnimations = {}
    for i = 1, 84 do
        if i ~= 7 and i ~= 11 and i ~= 12 and i ~= 40 and i ~= 56 then
            table.insert(validAnimations, i)
        end
    end
    local extras = { 102, 103, 105, 106, 107, 108, 109, 110, 111, 112, 113, 144, 164, 185, 186, 195, 196, 225 }
    for _, v in ipairs(extras) do
        table.insert(validAnimations, v)
    end

    local pool = {}
    local function RefillPool()
        wipe(pool)
        for i = 1, #validAnimations do
            pool[i] = validAnimations[i]
        end
        for i = #pool, 2, -1 do
            local j = math.random(i)
            pool[i], pool[j] = pool[j], pool[i]
        end
    end
    RefillPool()

    local function PlayRandomAnimation()
        if #pool == 0 then
            RefillPool()
        end
        local anim = table.remove(pool)
        f.anim = anim
        f:SetAnimation(anim)
    end

    local poke = CreateFrame("Button", nil, guiMidnight, "UIPanelButtonTemplate")
    poke:SetText(L["Poke"])
    poke:SetWidth(50)
    poke:SetPoint("LEFT", f, "LEFT", 65, -55)
    poke:SetScale(1.5)
    poke:SetFrameStrata("HIGH")
    poke:SetScript("OnClick", PlayRandomAnimation)
    poke.Text:SetVertexColor(1, 1, 1)


    local r, g, b = 0.945, 0.769, 1.0
    for _, region in ipairs({ poke:GetRegions() }) do
        if region:IsObjectType("Texture") then
            region:SetDesaturated(true)
            region:SetVertexColor(r, g, b)
        end
    end

    local ROT_SENS   = 0.010 * 0.8
    local PITCH_SENS = 0.010 * 0.8
    local DOLLY_SENS = 0.015 * 0.35
    local WHEEL_PAN  = 0.34

    f:EnableMouse(true)
    f:EnableMouseWheel(true)
    f:UseModelCenterToTransform(true)

    local camScale = DEFAULT_CAM
    f:SetCamDistanceScale(camScale)

    local startX, startY, startYaw, startPitch, startPX, startPY, startPZ
    local dragMode

    local function Cur()
        local x, y = GetCursorPosition()
        local s = UIParent:GetEffectiveScale()
        return x / s, y / s
    end

    f:SetScript("OnMouseDown", function(self, button)
        startX, startY            = Cur()
        startYaw                  = self:GetFacing() or 0
        startPitch                = self:GetPitch() or 0
        startPX, startPY, startPZ = self:GetPosition()
        if button == "LeftButton" then
            dragMode = "lmb"
        elseif button == "RightButton" then
            dragMode = "rmb"
        elseif button == "MiddleButton" then
            camScale = DEFAULT_CAM
            self:SetCamDistanceScale(camScale)
            self:SetFacing(0)
            self:SetPitch(0)
            self:SetPosition(0, 0, 0)
            self:SetViewTranslation(DEFAULT_VTX, DEFAULT_VTY)
            return
        end
        self:EnableMouseMotion(true)
    end)

    f:SetScript("OnMouseUp", function(self)
        self:EnableMouseMotion(false)
        dragMode = nil
    end)

    f:SetScript("OnHide", function(self)
        self:EnableMouseMotion(false)
        dragMode = nil
    end)

    f:SetScript("OnMouseWheel", function(self, delta)
        local px, py, pz = self:GetPosition()
        self:SetPosition(px + delta * WHEEL_PAN, py, pz)
    end)

    f:SetScript("OnUpdate", function(self)
        if not dragMode then return end
        local x, y = Cur()
        local dx, dy = x - startX, y - startY
        if dragMode == "lmb" then
            self:SetFacing(startYaw + dx * ROT_SENS)
            self:SetPitch(startPitch - dy * PITCH_SENS)
        elseif dragMode == "rmb" then
            self:SetPosition(startPX, startPY + dx * DOLLY_SENS, startPZ + dy * DOLLY_SENS)
        end
    end)

    local function ResetView()
        camScale = DEFAULT_CAM
        f:RefreshCamera()
        f:ZeroCachedCenterXY()
        f:UseModelCenterToTransform(true)
        f:SetPortraitZoom(0)
        f:SetFacing(0)
        f:SetPitch(0)
        f:SetRoll(0)
        f:SetPosition(0, 0, 0)
        f:SetCamDistanceScale(camScale)
        f:SetViewTranslation(DEFAULT_VTX, DEFAULT_VTY)
    end
    ResetView()

    guiMidnight:HookScript("OnShow", function()
        ResetView()
    end)
end

------------------------------------------------------------
-- GUI Setup
------------------------------------------------------------
local function CombatOnGUICreation()
    if InCombatLockdown() then
        BBF.Print(L["Print_Waiting_For_Combat"])
        if not BBF.waitingCombat then
            local f = CreateFrame("Frame")
            f:RegisterEvent("PLAYER_REGEN_ENABLED")
            f:SetScript("OnEvent", function(self)
                self:UnregisterEvent("PLAYER_REGEN_ENABLED")
                BBF.LoadGUI()
            end)
            BBF.waitingCombat = true
        end
        return true
    end
end

function BBF.InitializeOptions()
    if not BetterBlizzFrames then
        BetterBlizzFrames = CreateFrame("Frame")
        BetterBlizzFrames.name = "Better|cff00c0ffBlizz|rFrames |A:gmchat-icon-blizz:16:16|a"
        --InterfaceOptions_AddCategory(BetterBlizzFrames)
        BBF.category = Settings.RegisterCanvasLayoutCategory(BetterBlizzFrames, BetterBlizzFrames.name, BetterBlizzFrames.name)
        Settings.RegisterAddOnCategory(BBF.category)

        local titleText = BetterBlizzFrames:CreateFontString(nil, "OVERLAY", "GameFont_Gigantic")
        titleText:SetPoint("CENTER", BetterBlizzFrames, "CENTER", -15, 33)
        titleText:SetText("|A:gmchat-icon-blizz:16:16|a Better|cff00c0ffBlizz|rFrames")
        BetterBlizzFrames.titleText = titleText

        local loadGUI = CreateFrame("Button", nil, BetterBlizzFrames, "UIPanelButtonTemplate")
        loadGUI:SetText(L["Load_Settings"])
        loadGUI:SetWidth(100)
        loadGUI:SetPoint("CENTER", BetterBlizzFrames, "CENTER", -18, 6)
        BetterBlizzFrames.loadGUI = loadGUI
        loadGUI:SetScript("OnClick", function(self)
            if CombatOnGUICreation() then return end
            titleText:Hide()
            self:Hide()
            BBF.LoadGUI()
        end)
    end
end

function BBF.LoadGUI()
    -- First time opening settings
    if BetterBlizzFramesDB.hasNotOpenedSettings then
        BBF.CreateIntroMessageWindow()
        BetterBlizzFramesDB.hasNotOpenedSettings = nil
        return
    end

    if CombatOnGUICreation() then return end

    if BetterBlizzFrames.guiLoaded then
        Settings.OpenToCategory(BBF.category:GetID())
        return
    end

    guiGeneralTab()
    guiPositionAndScale()
    guiFrameAuras()
    guiFrameLook()
    guiCastbars()
    guiImportAndExport()
    guiMisc()
    --guiChatFrame()
    guiCustomCode()
    guiSupport()
    guiMidnight()
    BetterBlizzFrames.guiLoaded = true

    if SettingsPanel:IsShown() then
        HideUIPanel(SettingsPanel)
    end
    Settings.OpenToCategory(BBF.category:GetID())
    Settings.OpenToCategory(BBF.category:GetID(), BBF.guiCustomCode)
    Settings.OpenToCategory(BBF.category:GetID())
end


function BBF.CreateIntroMessageWindow()
    if BBF.IntroMessageWindow then
        BBF.IntroMessageWindow:ClearAllPoints()
        if BBP and BBP.IntroMessageWindow and BBP.IntroMessageWindow:IsShown() then
            BBP.IntroMessageWindow:ClearAllPoints()
            BBP.IntroMessageWindow:SetPoint("CENTER", UIParent, "CENTER", 240, 45)
            BBF.IntroMessageWindow:SetPoint("CENTER", UIParent, "CENTER", -240, 45)
        else
            BBF.IntroMessageWindow:SetPoint("CENTER", UIParent, "CENTER", 0, 45)
        end
        BBF.IntroMessageWindow:Show()
        return
    end

    BBF.IntroMessageWindow = CreateFrame("Frame", "BBFIntro", UIParent, "PortraitFrameTemplate")
    BBF.IntroMessageWindow:SetSize(470, 550)
    BBF.IntroMessageWindow.Bg:SetDesaturated(true)
    BBF.IntroMessageWindow.Bg:SetVertexColor(0.5,0.5,0.5, 0.98)
    if BBP and BBP.IntroMessageWindow and BBP.IntroMessageWindow:IsShown() then
        BBP.IntroMessageWindow:SetPoint("CENTER", UIParent, "CENTER", 240, 45)
        BBF.IntroMessageWindow:SetPoint("CENTER", UIParent, "CENTER", -240, 45)
    else
        BBF.IntroMessageWindow:SetPoint("CENTER", UIParent, "CENTER", 0, 45)
    end
    BBF.IntroMessageWindow:SetMovable(true)
    BBF.IntroMessageWindow:EnableMouse(true)
    BBF.IntroMessageWindow:RegisterForDrag("LeftButton")
    BBF.IntroMessageWindow:SetScript("OnDragStart", BBF.IntroMessageWindow.StartMoving)
    BBF.IntroMessageWindow:SetScript("OnDragStop", BBF.IntroMessageWindow.StopMovingOrSizing)
    BBF.IntroMessageWindow:SetTitle("Better|cff00c0ffBlizz|rFrames v"..BBF.VersionNumber)
    BBF.IntroMessageWindow:SetFrameStrata("HIGH")

    -- Add background texture
    BBF.IntroMessageWindow.textureTest = BBF.IntroMessageWindow:CreateTexture(nil, "BACKGROUND")
    BBF.IntroMessageWindow.textureTest:SetAtlas("communities-widebackground")
    BBF.IntroMessageWindow.textureTest:SetSize(465, 150)
    BBF.IntroMessageWindow.textureTest:SetPoint("TOP", BBF.IntroMessageWindow, "TOP", 0, -15)

    -- Create a mask texture
    local maskTexture = BBF.IntroMessageWindow:CreateMaskTexture()
    maskTexture:SetAtlas("Azerite-CenterBG-ChannelGlowBar-FillingMask")
    maskTexture:SetSize(665, 300)
    maskTexture:SetPoint("CENTER", BBF.IntroMessageWindow.textureTest, "CENTER", 0, 50)
    BBF.IntroMessageWindow.textureTest:AddMaskTexture(maskTexture)

    BBF.IntroMessageWindow:SetPortraitToAsset(135724)

    local welcomeText = BBF.IntroMessageWindow:CreateFontString(nil, "OVERLAY", "GameFontNormalHuge2")
    welcomeText:SetPoint("TOP", BBF.IntroMessageWindow, "TOP", 0, -45)
    welcomeText:SetText(L["Welcome_Text"])
    welcomeText:SetJustifyH("CENTER")

    local description1 = BBF.IntroMessageWindow:CreateFontString(nil, "OVERLAY", "GameFontNormal")
    description1:SetPoint("TOP", welcomeText, "BOTTOM", 0, -10)
    local starterProfileText = "|A:newplayerchat-chaticon-newcomer:16:16|a |cff32cd32" .. L["Label_Starter_Profile"] .. "|r"
    description1:SetText(string.format(L["Welcome_Description"], starterProfileText))
    description1:SetJustifyH("CENTER")
    description1:SetWidth(410)

    local btnWidth, btnHeight, btnGap = 150, 30, -3

    local function ShowProfileConfirmation(profileName, class, profileFunction, additionalNote)
        local noteText = additionalNote or ""
        local color = CLASS_COLORS[class] or "|cffffffff"
        local icon = CLASS_ICONS[class] or "groupfinder-icon-role-leader"
        local profileText = string.format("|A:%s:16:16|a %s%s|r", icon, color, profileName..L["Profile_Label"])
        local confirmationText = titleText .. string.format(L["Profile_Confirmation_Text_Intro"], profileText, noteText)
        StaticPopupDialogs["BBF_CONFIRM_PROFILE"].text = confirmationText
        StaticPopup_Show("BBF_CONFIRM_PROFILE", nil, nil, { func = profileFunction })
    end

    local starterButton = CreateClassButton(BBF.IntroMessageWindow, "STARTER", "Starter", nil, function()
        ShowProfileConfirmation("Starter", "STARTER", BBF.StarterProfile)
    end)
    starterButton:SetPoint("TOP", description1, "BOTTOM", -75, -20)

    local bodifyButton = CreateClassButton(BBF.IntroMessageWindow, "MAGE", "Bodify", "bodify", function()
        ShowProfileConfirmation("Bodify", "MAGE", BBF.BodifyProfile)
    end)
    bodifyButton:SetPoint("TOP", description1, "BOTTOM", 75, -20)

    local orText = BBF.IntroMessageWindow:CreateFontString(nil, "OVERLAY", "GameFontNormalMed2")
    orText:SetPoint("CENTER", bodifyButton, "BOTTOM", -75, -20)
    orText:SetText(L["OR"])
    orText:SetJustifyH("CENTER")

    local aeghisButton = CreateClassButton(BBF.IntroMessageWindow, "MAGE", "Aeghis", "aeghis", function()
        ShowProfileConfirmation("Aeghis", "MAGE", BBF.AeghisProfile)
    end)
    aeghisButton:SetPoint("TOP", bodifyButton, "BOTTOM", -150, -40)

    local kalvishButton = CreateClassButton(BBF.IntroMessageWindow, "ROGUE", "Kalvish", "kalvish", function()
        ShowProfileConfirmation("Kalvish", "ROGUE", BBF.KalvishProfile)
    end)
    kalvishButton:SetPoint("TOP", aeghisButton, "BOTTOM", 0, btnGap)

    local magnuszButton = CreateClassButton(BBF.IntroMessageWindow, "WARRIOR", "Magnusz", "magnusz", function()
        ShowProfileConfirmation("Magnusz", "WARRIOR", BBF.MagnuszProfile)
    end)
    magnuszButton:SetPoint("TOP", kalvishButton, "BOTTOM", 0, btnGap)

    local mesButton = CreateClassButton(BBF.IntroMessageWindow, "DEATHKNIGHT", "Mes", "notmes", function()
        ShowProfileConfirmation("Mes", "DEATHKNIGHT", BBF.MesProfile)
    end)
    mesButton:SetPoint("TOP", magnuszButton, "BOTTOM", 0, btnGap)

    local mmarkersButton = CreateClassButton(BBF.IntroMessageWindow, "DRUID", "Mmarkers", "mmarkers", function()
        ShowProfileConfirmation("Mmarkers", "DRUID", BBF.MmarkersProfile)
    end)
    mmarkersButton:SetPoint("TOP", mesButton, "BOTTOM", 0, btnGap)

    local mysticallButton = CreateClassButton(BBF.IntroMessageWindow, "MONK", "Mysticall", "mysticallx", function()
        ShowProfileConfirmation("Mysticall", "MONK", BBF.MysticallProfile)
    end)
    mysticallButton:SetPoint("TOP", mmarkersButton, "BOTTOM", 0, btnGap)

    local nahjButton = CreateClassButton(BBF.IntroMessageWindow, "ROGUE", "Nahj", "nahj", function()
        ShowProfileConfirmation("Nahj", "ROGUE", BBF.NahjProfile)
    end)
    nahjButton:SetPoint("TOP", bodifyButton, "BOTTOM", 0, -40)

    local pmakeButton = CreateClassButton(BBF.IntroMessageWindow, "MAGE", "Pmake", "pmakewow", function()
        ShowProfileConfirmation("Pmake", "MAGE", BBF.PmakeProfile)
    end)
    pmakeButton:SetPoint("TOP", nahjButton, "BOTTOM", 0, btnGap)

    local snupyButton = CreateClassButton(BBF.IntroMessageWindow, "DRUID", "Snupy", "snupy", function()
        ShowProfileConfirmation("Snupy", "DRUID", BBF.SnupyProfile)
    end)
    snupyButton:SetPoint("TOP", pmakeButton, "BOTTOM", 0, btnGap)

    local trimazButton = CreateClassButton(BBF.IntroMessageWindow, "ROGUE", "Trimaz", "trimaz_wow", function()
        ShowProfileConfirmation("Trimaz", "ROGUE", BBF.TrimazProfile)
    end)
    trimazButton:SetPoint("TOP", snupyButton, "BOTTOM", 0, btnGap)

    local venrukiButton = CreateClassButton(BBF.IntroMessageWindow, "MAGE", "Venruki", "venruki", function()
        ShowProfileConfirmation("Venruki", "MAGE", BBF.VenrukiProfile)
    end)
    venrukiButton:SetPoint("TOP", trimazButton, "BOTTOM", 0, btnGap)

    local wolfButton = CreateClassButton(BBF.IntroMessageWindow, "DRUID", "Wolf", "wlfzx", function()
        ShowProfileConfirmation("Wolf", "DRUID", BBF.WolfProfile)
    end)
    wolfButton:SetPoint("TOP", venrukiButton, "BOTTOM", 0, btnGap)

    local orText2 = BBF.IntroMessageWindow:CreateFontString(nil, "OVERLAY", "GameFontNormalMed2")
    orText2:SetPoint("CENTER", mysticallButton, "BOTTOM", 75, -20)
    orText2:SetText(L["OR"])
    orText2:SetJustifyH("CENTER")

    local buttonLast = CreateFrame("Button", nil, BBF.IntroMessageWindow, "GameMenuButtonTemplate")
    buttonLast:SetSize(btnWidth, btnHeight)
    buttonLast:SetText(L["Exit_No_Profile"])
    buttonLast:SetPoint("TOP", mysticallButton, "BOTTOM", 75, -40)
    buttonLast:SetNormalFontObject("GameFontNormal")
    buttonLast:SetHighlightFontObject("GameFontHighlight")
    buttonLast:SetScript("OnClick", function()
        BBF.IntroMessageWindow:Hide()
        if not BetterBlizzFrames.guiLoaded then
            BBF.LoadGUI()
        else
            Settings.OpenToCategory(BBF.category:GetID())
        end
    end)
    CreateTooltipTwo(buttonLast, L["Exit_No_Profile"], L["Tooltip_Exit_No_Profile"], nil, "ANCHOR_TOP")
    local f,s,o = buttonLast.Text:GetFont()
    buttonLast.Text:SetFont(f,s,"OUTLINE")

    BBF.IntroMessageWindow.CloseButton:HookScript("OnClick", function()
        if not BetterBlizzFrames.guiLoaded then
            BBF.LoadGUI()
        else
            Settings.OpenToCategory(BBF.category:GetID())
        end
    end)

    local function AdjustWindowHeight()
        local baseHeight = 334
        local perRowHeight = 29
        local buttonCount = 0
        for _, child in ipairs({BBF.IntroMessageWindow:GetChildren()}) do
            if child and child:IsObjectType("Button") then
                buttonCount = buttonCount + 1
            end
        end

        local rowCount = math.ceil(buttonCount / 2)
        local newHeight = baseHeight + (rowCount * perRowHeight)

        BBF.IntroMessageWindow:SetSize(470, newHeight)
    end
    AdjustWindowHeight()
end