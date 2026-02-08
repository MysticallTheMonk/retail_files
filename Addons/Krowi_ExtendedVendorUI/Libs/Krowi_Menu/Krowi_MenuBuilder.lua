--[[
    Copyright (c) 2025 Krowi
    Licensed under the terms of the LICENSE file in this repository.
]]

---@diagnostic disable: undefined-global
---@diagnostic disable: duplicate-set-field

-- Krowi_MenuBuilder: Cross-version menu builder for WoW Classic and Modern

local sub, parent = KROWI_LIBMAN:NewSubmodule('MenuBuilder', 0)
if not sub or not parent then return end

local menuBuilder = {}
menuBuilder.__index = menuBuilder

-- Utility: Binds object methods to callback functions (see Description.md for usage)
function sub.BindCallbacks(obj, methodNames)
    local callbacks = {}
    for callbackName, methodName in pairs(methodNames) do
        callbacks[callbackName] = function(...)
            return obj[methodName](obj, ...)
        end
    end
    return callbacks
end

local function SetupDefaultCallbacks(instance)
    if not parent.Util or not parent.Util.ReadNestedKeys then
        return
    end

    if not instance.callbacks.KeyIsTrue then
        instance.callbacks.KeyIsTrue = function(filters, keys)
            return parent.Util.ReadNestedKeys(filters, keys)
        end
    end

    if not instance.callbacks.KeyEqualsText then
        instance.callbacks.KeyEqualsText = function(filters, keys, value)
            return parent.Util.ReadNestedKeys(filters, keys) == value
        end
    end
end

local function SetupDefaultTranslations(instance)
    instance.translations['Select All'] = instance.translations['Select All'] or 'Select All'
    instance.translations['Deselect All'] = instance.translations['Deselect All'] or 'Deselect All'
    instance.translations['Version'] = instance.translations['Version'] or 'Version'
end

function sub:New(config)
    local instance = setmetatable({}, menuBuilder)
    instance.config = config or {}
    instance.callbacks = config.callbacks or {}
    instance.translations = config.translations or {}

    -- Generate unique tag for this instance
    instance.uniqueTag = config.uniqueTag or tostring(instance):match('0x(%x+)') or tostring(math.random(100000, 999999))

    SetupDefaultTranslations(instance)
    SetupDefaultCallbacks(instance)

    instance:Init()

    return instance
end

function menuBuilder:GetCheckBoxStateText(text, filters, keys)
    if self.callbacks.GetCheckBoxStateText then
        return self.callbacks.GetCheckBoxStateText(text, filters, keys)
    end
    return text
end

function menuBuilder:KeyIsTrue(filters, keys)
    if self.callbacks.KeyIsTrue then
        return self.callbacks.KeyIsTrue(filters, keys)
    end
    return false
end

function menuBuilder:OnCheckboxSelect(filters, keys, ...)
    if self.callbacks.OnCheckboxSelect then
        self.callbacks.OnCheckboxSelect(filters, keys, ...)
    end
end

function menuBuilder:KeyEqualsText(filters, keys, value)
    if self.callbacks.KeyEqualsText then
        return self.callbacks.KeyEqualsText(filters, keys, value)
    end
    return false
end

function menuBuilder:OnRadioSelect(filters, keys, value, ...)
    if self.callbacks.OnRadioSelect then
        self.callbacks.OnRadioSelect(filters, keys, value, ...)
    end
end

function menuBuilder:IsMinorVersionChecked(filters, minor)
    if self.callbacks.IsMinorVersionChecked then
        return self.callbacks.IsMinorVersionChecked(filters, minor)
    end
    return false
end

function menuBuilder:OnMinorVersionSelect(filters, minor)
    if self.callbacks.OnMinorVersionSelect then
        self.callbacks.OnMinorVersionSelect(filters, minor)
    end
end

function menuBuilder:IsMajorVersionChecked(filters, major)
    if self.callbacks.IsMajorVersionChecked then
        return self.callbacks.IsMajorVersionChecked(filters, major)
    end
    return false
end

function menuBuilder:OnMajorVersionSelect(filters, major)
    if self.callbacks.OnMajorVersionSelect then
        self.callbacks.OnMajorVersionSelect(filters, major)
    end
end

function menuBuilder:OnAllVersionsSelect(filters, value)
    if self.callbacks.OnAllVersionsSelect then
        self.callbacks.OnAllVersionsSelect(filters, value)
    end
end

function menuBuilder:OnAllSelect(filters, keys, value)
    if self.callbacks.OnAllSelect then
        self.callbacks.OnAllSelect(filters, keys, value)
    end
end

-- Modern Implementation (WOW_PROJECT_MAINLINE)

function menuBuilder:Init()
    self.menuGenerator = nil
    self.currentMenu = nil
end

function menuBuilder:SetupMenuForModern(button)
    if not button.SetupMenu then
        error('Button must have SetupMenu method (WowStyle1FilterDropdownMixin)')
    end

    button:SetupMenu(function(owner, menu)
        menu:SetTag(self.uniqueTag)
        self.currentMenu = menu
        if self.CreateMenu then
            self:CreateMenu()
        end
    end)
end

function menuBuilder:Show(anchor, offsetX, offsetY)
end

function menuBuilder:ShowPopup(createMenuFunc, anchor, offsetX, offsetY)
    local menuFunc = createMenuFunc or self.CreateMenu
    if not menuFunc then
        error('ShowPopup requires a createMenuFunc parameter or self.CreateMenu function')
    end

    local menu = MenuUtil.CreateContextMenu(anchor or UIParent, function(owner, menuObj)
        menuObj:SetTag(self.uniqueTag)
        self.currentMenu = menuObj
        menuFunc(self)
    end)
    if anchor then
        menu:SetPoint('TOPLEFT', anchor or UIParent, 'BOTTOMLEFT', offsetX or 0, offsetY or 0)
    end
end

function menuBuilder:Close()
end

function menuBuilder:GetMenu()
    return self.currentMenu
end

function menuBuilder:CreateDivider(menu)
    menu = menu or self:GetMenu()
    menu:CreateDivider()
end

function menuBuilder:CreateCheckbox(menu, text, filters, keys, ...)
    menu = menu or self:GetMenu()
    local userData = {...}

    return menu:CreateCheckbox(
        self:GetCheckBoxStateText(text, filters, keys),
        function()
            return self:KeyIsTrue(filters, keys)
        end,
        function()
            self:OnCheckboxSelect(filters, keys, unpack(userData))
        end
    )
end

function menuBuilder:CreateCustomCheckbox(menu, text, isCheckedFunc, onClickFunc)
    menu = menu or self:GetMenu()

    return menu:CreateCheckbox(
        text,
        isCheckedFunc,
        onClickFunc
    )
end

function menuBuilder:CreateRadio(menu, text, filters, keys, value, ...)
    menu = menu or self:GetMenu()
    value = value or text
    local userData = {...}

    local button = menu:CreateRadio(
        text,
        function()
            return self:KeyEqualsText(filters, keys, value)
        end,
        function()
            self:OnRadioSelect(filters, keys, value, unpack(userData))
        end
    )
    button:SetResponse(MenuResponse.Refresh)
    return button
end

function menuBuilder:CreateCustomRadio(menu, text, isSelectedFunc, onClickFunc)
    menu = menu or self:GetMenu()

    local button = menu:CreateRadio(
        text,
        isSelectedFunc,
        onClickFunc
    )
    button:SetResponse(MenuResponse.Refresh)
    return button
end

function menuBuilder:CreateMinorVersionGroup(majorGroup, filters, major, minor)
    return majorGroup:CreateCheckbox(
        major.Major .. '.' .. minor.Minor .. '.x',
        function()
            return self:IsMinorVersionChecked(filters, minor)
        end,
        function()
            self:OnMinorVersionSelect(filters, minor)
        end
    )
end

function menuBuilder:CreateMajorVersionGroup(version, filters, major)
    return version:CreateCheckbox(
        major.Major .. '.x.x',
        function()
            return self:IsMajorVersionChecked(filters, major)
        end,
        function()
            self:OnMajorVersionSelect(filters, major)
        end
    )
end

function menuBuilder:CreateSelectDeselectAllVersions(version, filters)
    self:CreateDivider(version)

    local selectAll = version:CreateButton(
        self.translations['Select All'],
        function()
            self:OnAllVersionsSelect(filters, true)
        end
    )
    selectAll:SetResponse(MenuResponse.Refresh)

    local deselectAll = version:CreateButton(
        self.translations['Deselect All'],
        function()
            self:OnAllVersionsSelect(filters, false)
        end
    )
    deselectAll:SetResponse(MenuResponse.Refresh)
end

function menuBuilder:CreateBuildVersionFilter(filters, menu)
    menu = menu or self:GetMenu()

    local version = menu:CreateButton(self.translations['Version'])
    if self.callbacks.CreateBuildVersionFilterGroups then
        self.callbacks.CreateBuildVersionFilterGroups(version, filters, self)
    end
    self:CreateSelectDeselectAllVersions(version, filters)
end

function menuBuilder:CreateSelectDeselectAll(menu, text, filters, keys, value, callback)
    menu = menu or self:GetMenu()
    callback = callback or self.OnAllSelect

    local button = menu:CreateButton(
        text,
        function()
            callback(self, filters, keys, value)
        end
    )
    button:SetResponse(MenuResponse.Refresh)
    return button
end

function menuBuilder:CreateSelectDeselectAllButtons(menu, filters, keys, callback)
    self:CreateSelectDeselectAll(menu, self.translations['Select All'], filters, keys, true, callback)
    self:CreateSelectDeselectAll(menu, self.translations['Deselect All'], filters, keys, false, callback)
end

function menuBuilder:CreateButton(menu, text, func)
    menu = menu or self:GetMenu()
    return menu:CreateButton(text, func)
end

function menuBuilder:CreateTitle(menu, text)
    menu = menu or self:GetMenu()
    menu:CreateTitle(text)
end

function menuBuilder:SetElementEnabled(element, isEnabled)
    if element and element.SetEnabled then
        element:SetEnabled(isEnabled ~= false)
    end
end

function menuBuilder:CreateSubmenuButton(menu, text, func, isEnabled)
    menu = menu or self:GetMenu()
    local button = menu:CreateButton(text, func)
    if isEnabled == false then
        button:SetEnabled(false)
    end
    return button
end

function menuBuilder:CreateSubmenuRadio(menu, text, isSelectedFunc, onClickFunc, isEnabled)
    menu = menu or self:GetMenu()
    local button = self:CreateCustomRadio(menu, text, isSelectedFunc, onClickFunc)
    if button and isEnabled == false then
        button:SetEnabled(false)
    end
    return button
end

function menuBuilder:AddChildMenu(menu, child)
end

function menuBuilder:CreateButtonAndAdd(menu, text, func, isEnabled)
    return self:CreateSubmenuButton(menu, text, func, isEnabled)
end

if WOW_PROJECT_ID == WOW_PROJECT_MAINLINE then
    sub.MenuBuilder = menuBuilder
    return
end

-- Classic Implementation (non-Mainline)

function menuBuilder:Init()
    self.rootMenu = parent
end

function menuBuilder:Show(anchor, offsetX, offsetY)
    self.rootMenu:Clear()
    if self.CreateMenu then
        self:CreateMenu()
    end
    self.rootMenu:Toggle(anchor, offsetX or 0, offsetY or 0)
end

function menuBuilder:ShowPopup(createMenuFunc, anchor, offsetX, offsetY)
    local menuFunc = createMenuFunc or self.CreateMenu
    if not menuFunc then
        error('ShowPopup requires a createMenuFunc parameter or self.CreateMenu function')
    end

    self.rootMenu:Clear()
    menuFunc(self)
    self.rootMenu:Toggle(anchor or 'cursor', offsetX or 0, offsetY or 0)
end

function menuBuilder:Close()
    if self.rootMenu then
        self.rootMenu:Close()
    end
end

function menuBuilder:GetMenu()
    return self.rootMenu
end

function menuBuilder:CreateDivider(menu)
    menu = menu or self:GetMenu()
    menu:AddSeparator()
end

function menuBuilder:CreateCheckbox(menu, text, filters, keys, ...)
    menu = menu or self:GetMenu()
    local userData = {...}

    return menu:AddFull({
        Text = self:GetCheckBoxStateText(text, filters, keys),
        Checked = function()
            return self:KeyIsTrue(filters, keys)
        end,
        Func = function()
            self:OnCheckboxSelect(filters, keys, unpack(userData))
            UIDropDownMenu_RefreshAll(UIDROPDOWNMENU_OPEN_MENU)
        end,
        IsNotRadio = true,
        NotCheckable = false,
        KeepShownOnClick = true
    })
end

function menuBuilder:CreateCustomCheckbox(menu, text, isCheckedFunc, onClickFunc)
    menu = menu or self:GetMenu()

    return menu:AddFull({
        Text = text,
        Checked = isCheckedFunc,
        Func = function()
            onClickFunc()
            UIDropDownMenu_RefreshAll(UIDROPDOWNMENU_OPEN_MENU)
        end,
        IsNotRadio = true,
        NotCheckable = false,
        KeepShownOnClick = true
    })
end

function menuBuilder:CreateRadio(menu, text, filters, keys, value, ...)
    menu = menu or self:GetMenu()
    value = value or text
    local userData = {...}

    return menu:AddFull({
        Text = text,
        Checked = function()
            return self:KeyEqualsText(filters, keys, value)
        end,
        Func = function()
            self:OnRadioSelect(filters, keys, value, unpack(userData))
            self.rootMenu:SetSelectedName(text)
        end,
        NotCheckable = false,
        KeepShownOnClick = true
    })
end

function menuBuilder:CreateCustomRadio(menu, text, isSelectedFunc, onClickFunc)
    menu = menu or self:GetMenu()

    return menu:AddFull({
        Text = text,
        Checked = isSelectedFunc,
        Func = function()
            onClickFunc()
            self.rootMenu:SetSelectedName(text)
        end,
        NotCheckable = false,
        KeepShownOnClick = true
    })
end

function menuBuilder:CreateMinorVersionGroup(majorGroup, filters, major, minor)
    return majorGroup:AddFull({
        Text = major.Major .. '.' .. minor.Minor .. '.x',
        Checked = function()
            return self:IsMinorVersionChecked(filters, minor)
        end,
        Func = function()
            self:OnMinorVersionSelect(filters, minor)
            UIDropDownMenu_RefreshAll(UIDROPDOWNMENU_OPEN_MENU)
        end,
        IsNotRadio = true,
        NotCheckable = false,
        KeepShownOnClick = true
    })
end

function menuBuilder:CreateMajorVersionGroup(version, filters, major)
    return version:AddFull({
        Text = major.Major .. '.x.x',
        Checked = function()
            return self:IsMajorVersionChecked(filters, major)
        end,
        Func = function()
            self:OnMajorVersionSelect(filters, major)
            UIDropDownMenu_RefreshAll(UIDROPDOWNMENU_OPEN_MENU)
        end,
        IsNotRadio = true,
        NotCheckable = false,
        KeepShownOnClick = true
    })
end

function menuBuilder:CreateSelectDeselectAllVersions(version, filters)
    self:CreateDivider(version)

    version:AddFull({
        Text = self.translations['Select All'],
        Func = function()
            self:OnAllVersionsSelect(filters, true)
            UIDropDownMenu_RefreshAll(UIDROPDOWNMENU_OPEN_MENU)
        end,
        KeepShownOnClick = true
    })
    version:AddFull({
        Text = self.translations['Deselect All'],
        Func = function()
            self:OnAllVersionsSelect(filters, false)
            UIDropDownMenu_RefreshAll(UIDROPDOWNMENU_OPEN_MENU)
        end,
        KeepShownOnClick = true
    })
end

function menuBuilder:CreateBuildVersionFilter(filters, menu)
    menu = menu or self:GetMenu()

    local version = self:CreateSubmenuButton(menu, self.translations['Version'])
    if self.callbacks.CreateBuildVersionFilterGroups then
        self.callbacks.CreateBuildVersionFilterGroups(version, filters, self)
    end
    self:CreateSelectDeselectAllVersions(version, filters)
    self:AddChildMenu(menu, version)
end

function menuBuilder:CreateSelectDeselectAll(menu, text, filters, keys, value, callback)
    menu = menu or self:GetMenu()
    callback = callback or self.OnAllSelect

    return menu:AddFull({
        Text = text,
        Func = function()
            callback(self, filters, keys, value)
            UIDropDownMenu_RefreshAll(UIDROPDOWNMENU_OPEN_MENU)
        end,
        KeepShownOnClick = true
    })
end

function menuBuilder:CreateSelectDeselectAllButtons(menu, filters, keys, callback)
    self:CreateSelectDeselectAll(menu, self.translations['Select All'], filters, keys, true, callback)
    self:CreateSelectDeselectAll(menu, self.translations['Deselect All'], filters, keys, false, callback)
end

function menuBuilder:CreateButton(menu, text, func)
    menu = menu or self:GetMenu()
    return menu:AddFull({
        Text = text,
        Func = func,
        NotCheckable = true
    })
end

function menuBuilder:CreateTitle(menu, text)
    menu = menu or self:GetMenu()
    menu:AddTitle(text)
end

function menuBuilder:SetElementEnabled(element, isEnabled)
    if element then
        element.Disabled = isEnabled == false
    end
end

function menuBuilder:CreateSubmenuButton(menu, text, func, isEnabled)
    menu = menu or self:GetMenu()
    return parent.MenuItem:New({
        Text = text,
        Func = func,
        Disabled = isEnabled == false
    })
end

function menuBuilder:CreateSubmenuRadio(menu, text, isSelectedFunc, onClickFunc, isEnabled)
    menu = menu or self:GetMenu()
    return parent.MenuItem:New({
        Text = text,
        Checked = isSelectedFunc,
        Func = function()
            onClickFunc()
            self.rootMenu:SetSelectedName(text)
        end,
        NotCheckable = false,
        KeepShownOnClick = true,
        Disabled = isEnabled == false
    })
end

function menuBuilder:AddChildMenu(menu, child)
    menu = menu or self:GetMenu()
    if not menu or not child then
        return
    end
    menu:Add(child)
end

function menuBuilder:CreateButtonAndAdd(menu, text, func, isEnabled)
    menu = menu or self:GetMenu()
    local button = self:CreateSubmenuButton(nil, text, func, isEnabled)
    self:AddChildMenu(menu, button)
    return button
end

sub.MenuBuilder = menuBuilder