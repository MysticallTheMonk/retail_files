local _, LRP = ...

-- Tooltip
CreateFrame("GameTooltip", "LRTooltip", UIParent, "GameTooltipTemplate")

LRP.Tooltip = _G["LRTooltip"]
LRP.Tooltip:SetOwner(WorldFrame, "ANCHOR_NONE")

LRP.Tooltip:AddFontStrings(
	LRP.Tooltip:CreateFontString("$parentTextLeft1", nil, "GameTooltipText"),
	LRP.Tooltip:CreateFontString("$parentTextRight1", nil, "GameTooltipText")
)

if LRP.isRetail then
    LRP.Tooltip.TextLeft1:SetFontObject(LRFont13)
    LRP.Tooltip.TextRight1:SetFontObject(LRFont13)
end

-- Main window
local windowDefaultWidth = 1200
local windowMinWidth = 800

function LRP:InitializeInterface()
    LRP.window = LRP:CreateWindow("Main", true, true, true)
    LRP.window:SetFrameStrata("HIGH")
    LRP.window:SetResizeBounds(windowMinWidth, 0) -- Height is set based on timeine data
    LRP.window:SetPoint("CENTER")
    LRP.window:Hide()

    LRP.window:SetScript("OnHide", function() LRP:StopSimulation() end)

    -- If there's no saved position/size settings for the main window yet, apply some default values
    local windowSettings = LiquidRemindersSaved.settings.frames["Main"]
    local windowWidth = windowSettings and windowSettings.width

    -- If this is the first time the addon loads, and the user has never resized the window yet, apply some default width
    if not windowWidth then
        windowWidth = windowDefaultWidth

        LRP.window:SetWidth(windowWidth)
    end

    -- Discord button
    local discordButton = CreateFrame("Button", nil, LRP.window)

    discordButton:SetSize(24, 24)
    discordButton:SetPoint("BOTTOMLEFT", LRP.window, "BOTTOMLEFT", 10, 6)
    discordButton:SetHighlightTexture("Interface\\AddOns\\TimelineReminders\\Media\\Textures\\DiscordHighlight.tga", "ADD")

    discordButton.tex = discordButton:CreateTexture(nil, "BACKGROUND")
    discordButton.tex:SetTexture("Interface\\AddOns\\TimelineReminders\\Media\\Textures\\Discord.tga")
    discordButton.tex:SetAllPoints()

    local discordEditBox = LRP:CreateEditBox(
        discordButton,
        "",
        function() end
    )

    discordEditBox:SetSize(150, 20)
    discordEditBox:SetPoint("LEFT", discordButton, "RIGHT", 8, 0)
    discordEditBox:SetText("discord.gg/wFt6h3qpP6")
    discordEditBox:Hide()
    discordEditBox:RegisterEvent("GLOBAL_MOUSE_DOWN")

    discordEditBox:SetScript(
        "OnCursorChanged",
        function()
            discordEditBox:HighlightText()
        end
    )

    discordEditBox:SetScript(
        "OnTextChanged",
        function()
            discordEditBox:SetText("discord.gg/wFt6h3qpP6")
            discordEditBox:HighlightText()
        end
    )

    discordEditBox:SetScript(
        "OnEvent",
        function()
            if not (discordEditBox:IsMouseOver() or discordButton:IsMouseOver()) then
                discordEditBox:Hide()
            end
        end
    )

    discordButton:SetScript(
        "OnClick",
        function()
            if discordEditBox:IsShown() then
                discordEditBox:Hide()
            else
                discordEditBox:Show()
                discordEditBox:HighlightText()
                discordEditBox:SetFocus()
            end
        end
    )

    LRP:AddTooltip(discordButton, "Join the Discord to receive updates about new features")
    
    -- Settings button
    LRP.window:AddButton(
        "Interface\\Addons\\TimelineReminders\\Media\\Textures\\Cogwheel.tga",
        "Settings",
        function()
            LRP.settingsWindow:SetShown(not LRP.settingsWindow:IsShown())
        end
    )

    -- Anchors button
    LRP.window:AddButton(
        "Interface\\Addons\\TimelineReminders\\Media\\Textures\\Anchor.tga",
        "Toggle anchors",
        function()
            LRP.anchors.TEXT:SetShown(not LRP.anchors.TEXT:IsShown())
            LRP.anchors.SPELL:SetShown(not LRP.anchors.SPELL:IsShown())
        end
    )

    -- Timeline
    LRP:InitializeTimeline()
    
    local timeline = LRP.timeline

    timeline:SetParent(LRP.window)
    timeline:SetPoint("TOPLEFT", LRP.window, "TOPLEFT", 16, -140)
    timeline:SetPoint("TOPRIGHT", LRP.window, "TOPRIGHT", -16, -140)

    -- Reminder config
    LRP:InitializeConfig()
    LRP:InitializeSingleExport()
    LRP:InitializeImportExport()
    LRP:InitializeSettings()

    -- Take care of window frame levels
    -- i.e. when a window is clicked, it should be "raised" above the other windows
    local windows = {}
    local windowRaiseFrame = CreateFrame("Frame", nil, LRP.window)
    
    table.insert(windows, LRP.importExportWindow)
    table.insert(windows, LRP.reminderConfig)
    table.insert(windows, LRP.confirmWindow)
    table.insert(windows, LRP.profileWindow)

    local function RaiseWindow(window)
        local index = tIndexOf(windows, window)

        table.remove(windows, index)
        table.insert(windows, window)

        for order, w in ipairs(windows) do
            w:SetFrameLevel(order * 100)
        end
    end

    -- When a window is opened, it should appear above other windows that were already opened
    for _, window in ipairs(windows) do
        window:SetScript("OnShow", RaiseWindow)
    end

    -- When a window is clicked, raise it above the other windows
    windowRaiseFrame:RegisterEvent("GLOBAL_MOUSE_DOWN")
    windowRaiseFrame:SetScript(
        "OnEvent",
        function()
            local frame = GetMouseFoci()[1]
            
            for _ = 1, 5 do
                if not frame then return end
                if frame:IsForbidden() then return end

                if tContains(windows, frame) then
                    RaiseWindow(frame)

                    return
                else
                    frame = frame.GetParent and frame:GetParent()
                end
            end
        end
    )

    windowRaiseFrame:RegisterEvent("PLAYER_REGEN_DISABLED")
    LRP.window:SetScript(
        "OnEvent",
        function()
            LRP.window:SetPropagateKeyboardInput(true)
        end
    )

    -- When escape is pressed, close the most top level window
    LRP.window:SetScript(
        "OnKeyDown",
        function(_, key)
            if InCombatLockdown() then return end

            if key == "ESCAPE" then
                LRP.window:SetPropagateKeyboardInput(false)

                for _, window in ipairs_reverse(windows) do
                    if window:IsShown() then
                        window:Hide()

                        return
                    end
                end

                LRP.window:Hide()
            else
                LRP.window:SetPropagateKeyboardInput(true)
            end
        end
    )
end