---@type string, Addon
local _, addon = ...
local fsConfig = addon.Configuration
local fsLog = addon.Logging.Log
local wow = addon.WoW.Api
local callbacks = {}
local dropDownId = 1

fsConfig.VerticalSpacing = 12
fsConfig.HorizontalSpacing = 50
fsConfig.TextMaxWidth = 600

local function AddCategory(panel)
    if wow.Settings then
        local category = wow.Settings.RegisterCanvasLayoutCategory(panel, panel.name, panel.name)
        category.ID = panel.name
        wow.Settings.RegisterAddOnCategory(category)
    elseif wow.InterfaceOptions_AddCategory then
        wow.InterfaceOptions_AddCategory(panel)
    else
        fsLog:Error("Unable to add options category.")
    end
end

local function AddSubCategory(panel)
    if wow.Settings then
        local category = wow.Settings.GetCategory(panel.parent)
        local subcategory = wow.Settings.RegisterCanvasLayoutSubcategory(category, panel, panel.name, panel.name)
        subcategory.ID = panel.name
    elseif wow.InterfaceOptions_AddCategory then
        wow.InterfaceOptions_AddCategory(panel)
    else
        fsLog:Error("Unable to add options sub category.")
    end
end

function fsConfig:RegisterConfigurationChangedCallback(callback)
    callbacks[#callbacks + 1] = callback
end

function fsConfig:NotifyChanged()
    for _, callback in ipairs(callbacks) do
        pcall(callback)
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

function fsConfig:Dropdown(parent, items, getValue, setSelected)
    if wow.IsRetail() then
        local dd = wow.CreateFrame("DropdownButton", nil, parent, "WowStyle1DropdownTemplate")
        dd:SetupMenu(function(_, rootDescription)
            for i, value in ipairs(items) do
                rootDescription:CreateRadio(tostring(value), function(x)
                    return x == getValue()
                end, setSelected, i)
            end
        end)

        function dd:FrameSortRefresh()
            self:Update()
        end

        return dd
    else
        local libDD = LibStub:GetLibrary("LibUIDropDownMenu-4.0")
        -- needs a name to not bug out
        local dd = libDD:Create_UIDropDownMenu("FrameSortDropDown" .. dropDownId, parent)
        dropDownId = dropDownId + 1

        libDD:UIDropDownMenu_Initialize(dd, function()
            for _, value in ipairs(items) do
                local info = libDD:UIDropDownMenu_CreateInfo()
                info.text = tostring(value)
                info.value = value

                info.checked = function()
                    return getValue() == value
                end

                -- onclick handler
                info.func = function()
                    libDD:UIDropDownMenu_SetSelectedID(dd, dd:GetID(info))
                    libDD:UIDropDownMenu_SetText(dd, tostring(value))
                    setSelected(value)
                end

                libDD:UIDropDownMenu_AddButton(info, 1)

                -- if the config value matches this value, then set it as the selected item
                if getValue() == value then
                    libDD:UIDropDownMenu_SetSelectedID(dd, dd:GetID(info))
                end
            end
        end)

        function dd:FrameSortRefresh()
            libDD:UIDropDownMenu_SetText(dd, getValue())
        end

        return dd
    end
end

function fsConfig:Init()
    local panel = wow.CreateFrame("ScrollFrame", nil, nil, "UIPanelScrollFrameTemplate")
    panel.name = "FrameSort"

    local main = wow.CreateFrame("Frame")

    if wow.SettingsPanel then
        main:SetWidth(wow.SettingsPanel.Container:GetWidth())
        main:SetHeight(wow.SettingsPanel.Container:GetHeight())
    elseif wow.InterfaceOptionsFramePanelContainer then
        main:SetWidth(wow.InterfaceOptionsFramePanelContainer:GetWidth())
        main:SetHeight(wow.InterfaceOptionsFramePanelContainer:GetHeight())
    else
        fsLog:Error("Unable to set configuration panel width.")
    end

    panel:SetScrollChild(main)

    AddCategory(panel)

    local panels = fsConfig.Panels
    panels.Sorting:Build(main)

    local ordering = panels.Ordering:Build(panel)
    local sortingMethod = panels.SortingMethod:Build(panel)
    local autoLeader = wow.IsRetail() and panels.AutoLeader:Build(panel)
    local keybinding = panels.Keybinding:Build(panel)
    local macro = panels.Macro:Build(panel)
    local spacing = panels.Spacing:Build(panel)
    local addons = panels.Addons:Build(panel)
    local api = panels.Api:Build(panel)
    local health = panels.Health:Build(panel)
    local help = panels.Help:Build(panel)

    AddSubCategory(ordering)
    AddSubCategory(sortingMethod)

    if wow.IsRetail() then
        AddSubCategory(autoLeader)
    end

    AddSubCategory(keybinding)
    AddSubCategory(macro)
    AddSubCategory(spacing)
    AddSubCategory(addons)
    AddSubCategory(api)
    AddSubCategory(health)
    AddSubCategory(help)

    SLASH_FRAMESORT1 = "/fs"
    SLASH_FRAMESORT2 = "/framesort"

    wow.SlashCmdList.FRAMESORT = function()
        if wow.Settings then
            wow.Settings.OpenToCategory(panel.name)
        elseif wow.InterfaceOptionsFrame_OpenToCategory then
            -- workaround the classic bug where the first call opens the Game interface
            -- and a second call is required
            wow.InterfaceOptionsFrame_OpenToCategory(panel)
            wow.InterfaceOptionsFrame_OpenToCategory(panel)
        end
    end
end
