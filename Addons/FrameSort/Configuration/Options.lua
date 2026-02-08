---@type string, Addon
local _, addon = ...
local fsConfig = addon.Configuration
local fsLog = addon.Logging.Log
local fsInspector = addon.Modules.Inspector
local wow = addon.WoW.Api
local capabilities = addon.WoW.Capabilities
local callbacks = {}
local dropDownId = 1
local LibStub = LibStub

fsConfig.VerticalSpacing = 12
fsConfig.HorizontalSpacing = 50
fsConfig.TextMaxWidth = 600
fsConfig.DiscordUrl = "https://discord.gg/bF3XkyuU3E"

local function AddCategory(panel)
    if wow.Settings then
        local category = wow.Settings.RegisterCanvasLayoutCategory(panel, panel.name)
        wow.Settings.RegisterAddOnCategory(category)

        return category
    elseif wow.InterfaceOptions_AddCategory then
        wow.InterfaceOptions_AddCategory(panel)

        return panel
    else
        fsLog:Critical("Unable to add options category.")
    end

    return nil
end

local function AddSubCategory(parentCategory, panel)
    if wow.Settings then
        assert(parentCategory)
        wow.Settings.RegisterCanvasLayoutSubcategory(parentCategory, panel, panel.name)
    elseif wow.InterfaceOptions_AddCategory then
        wow.InterfaceOptions_AddCategory(panel)
    else
        fsLog:Critical("Unable to add options sub category.")
    end
end

function fsConfig:RegisterConfigurationChangedCallback(callback)
    callbacks[#callbacks + 1] = callback
end

function fsConfig:NotifyChanged()
    fsLog:Debug("Configuration has changed.")

    for _, callback in ipairs(callbacks) do
        local ok, err = pcall(callback)
        if not ok then
            fsLog:Error("Configuration changed callback failed: %s.", tostring(err) or "unknown")
        end
    end
end

function fsConfig:TextLine(line, parent, anchor, font, verticalSpacing)
    local fstring = parent:CreateFontString(nil, "ARTWORK", font or "GameFontWhite")
    fstring:SetSpacing(0)

    if anchor then
        fstring:SetPoint("TOPLEFT", anchor, "BOTTOMLEFT", 0, verticalSpacing)
    end

    fstring:SetWidth(fsConfig.TextMaxWidth)
    fstring:SetJustifyH("LEFT")

    if line then
        fstring:SetText(line)
    end

    return fstring
end

function fsConfig:TextBlock(lines, parent, anchor)
    local textAnchor = anchor

    for i, line in ipairs(lines) do
        textAnchor = fsConfig:TextLine(line, parent, textAnchor, nil, i == 1 and -fsConfig.VerticalSpacing or -fsConfig.VerticalSpacing / 2)
    end

    return textAnchor
end

function fsConfig:MultilineTextBlock(text, parent, anchor)
    local lines = {}

    for str in string.gmatch(text, "([^\n]+)") do
        str = string.gsub(str, "\\n", "")
        lines[#lines + 1] = str
    end

    return fsConfig:TextBlock(lines, parent, anchor)
end

function fsConfig:Dropdown(parent, items, getValue, setSelected, getText)
    if capabilities.HasModernDropdown() then
        local dd = wow.CreateFrame("DropdownButton", nil, parent, "WowStyle1DropdownTemplate")
        dd:SetupMenu(function(_, rootDescription)
            for _, value in ipairs(items) do
                rootDescription:CreateRadio(getText and getText(value) or tostring(value), function(x)
                    return x == getValue()
                end, function()
                    setSelected(value)
                end, value)
            end
        end)

        function dd.FrameSortRefresh(ddSelf)
            ddSelf:Update()
        end

        return dd
    elseif LibStub then
        local libDD = LibStub:GetLibrary("LibUIDropDownMenu-4.0")
        -- needs a name to not bug out
        local dd = libDD:Create_UIDropDownMenu("FrameSortDropDown" .. dropDownId, parent)
        dropDownId = dropDownId + 1

        libDD:UIDropDownMenu_Initialize(dd, function()
            for _, value in ipairs(items) do
                local info = libDD:UIDropDownMenu_CreateInfo()
                info.text = getText and getText(value) or tostring(value)
                info.value = value

                info.checked = function()
                    return getValue() == value
                end

                -- onclick handler
                info.func = function()
                    libDD:UIDropDownMenu_SetSelectedID(dd, dd:GetID(info))
                    libDD:UIDropDownMenu_SetText(dd, getText and getText(value) or tostring(value))
                    setSelected(value)
                end

                libDD:UIDropDownMenu_AddButton(info, 1)

                -- if the config value matches this value, then set it as the selected item
                if getValue() == value then
                    libDD:UIDropDownMenu_SetSelectedID(dd, dd:GetID(info))
                end
            end
        end)

        function dd.FrameSortRefresh()
            libDD:UIDropDownMenu_SetText(dd, getText and getText(getValue()) or tostring(getValue()))
        end

        return dd
    else
        error("Failed to create dropdown menu.")
    end
end

function fsConfig:SettingsSize()
    local settingsContainer = wow.SettingsPanel and wow.SettingsPanel.Container

    if settingsContainer then
        return settingsContainer:GetWidth(), settingsContainer:GetHeight()
    end

    if wow.InterfaceOptionsFramePanelContainer then
        return wow.InterfaceOptionsFramePanelContainer:GetWidth(), wow.InterfaceOptionsFramePanelContainer:GetHeight()
    end

    fsLog:Error("Unable to determine configuration panel width.")

    return 600, 600
end

function fsConfig:Init()
    local panel = wow.CreateFrame("ScrollFrame", nil, nil, "UIPanelScrollFrameTemplate")
    panel.name = "FrameSort"

    local main = wow.CreateFrame("Frame")
    local width, height = fsConfig:SettingsSize()

    main:SetWidth(width)
    main:SetHeight(height)

    panel:SetScrollChild(main)

    local category = AddCategory(panel)

    if not category then
        return
    end

    local panels = fsConfig.Panels
    panels.Sorting:Build(main)

    local specOrdering = panels.SpecOrdering:Build(panel)
    local specPriority = fsInspector:CanRun() and panels.SpecPriority:Build(panel)
    local sortingMethod = panels.SortingMethod:Build(panel)
    local autoLeader = capabilities.HasSoloShuffle() and panels.AutoLeader:Build(panel)
    local keybinding = panels.Keybinding:Build(panel)
    local macro = panels.Macro:Build(panel)
    local variables = panels.MacroVariables:Build(panel)
    local spacing = panels.Spacing:Build(panel)
    local nameplates = panels.Nameplates:Build(panel)
    local misc = panels.Miscellaneous:Build(panel)
    local addons = panels.Addons:Build(panel)
    local api = panels.Api:Build(panel)
    local health = panels.Health:Build(panel)
    local locale = panels.Locale:Build(panel)
    local discord = panels.Discord:Build(panel)
    local log = panels.Log:Build(panel)

    AddSubCategory(category, specOrdering)

    if specPriority then
        AddSubCategory(category, specPriority)
    end

    AddSubCategory(category, sortingMethod)

    if autoLeader then
        AddSubCategory(category, autoLeader)
    end

    AddSubCategory(category, keybinding)
    AddSubCategory(category, macro)
    AddSubCategory(category, variables)
    AddSubCategory(category, spacing)
    AddSubCategory(category, nameplates)
    AddSubCategory(category, misc)
    AddSubCategory(category, addons)
    AddSubCategory(category, health)
    AddSubCategory(category, api)
    AddSubCategory(category, discord)
    AddSubCategory(category, locale)
    AddSubCategory(category, log)

    SLASH_FRAMESORT1 = "/fs"
    SLASH_FRAMESORT2 = "/framesort"

    wow.SlashCmdList.FRAMESORT = function()
        if wow.Settings then
            assert(category)

            if not wow.InCombatLockdown() or capabilities.CanOpenOptionsDuringCombat() then
                wow.Settings.OpenToCategory(category:GetID())
            else
                fsLog:NotifyCombatLockdown()
            end
        elseif wow.InterfaceOptionsFrame_OpenToCategory then
            -- workaround the classic bug where the first call opens the Game interface
            -- and a second call is required
            wow.InterfaceOptionsFrame_OpenToCategory(panel)
            wow.InterfaceOptionsFrame_OpenToCategory(panel)
        end
    end
end
